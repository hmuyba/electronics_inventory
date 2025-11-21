import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/sale.dart' as entity;
import '../../domain/repositories/sale_repository.dart';
import '../datasources/remote/supabase_datasource.dart';
import '../datasources/local/database.dart';
import '../models/sale_model.dart';

class SaleRepositoryImpl implements SaleRepository {
  final SupabaseDataSource remoteDataSource;
  final AppDatabase localDatabase;

  SaleRepositoryImpl({
    required this.remoteDataSource,
    required this.localDatabase,
  });

  @override
  Future<List<entity.Sale>> getAll() async {
    try {
      final sales = await remoteDataSource.getSales();
      return sales;
    } catch (e) {
      final query = localDatabase.select(localDatabase.sales).join([
        innerJoin(
          localDatabase.locations,
          localDatabase.locations.id.equalsExp(localDatabase.sales.locationId),
        ),
        innerJoin(
          localDatabase.employees,
          localDatabase.employees.id.equalsExp(localDatabase.sales.employeeId),
        ),
      ]);

      final results = await query.get();

      return results.map((row) {
        final sale = row.readTable(localDatabase.sales);
        final location = row.readTable(localDatabase.locations);
        final employee = row.readTable(localDatabase.employees);

        return SaleModel(
          id: sale.id,
          locationId: sale.locationId,
          locationName: location.name,
          employeeId: sale.employeeId,
          employeeName: employee.name,
          total: sale.total,
          createdAt: sale.createdAt,
          updatedAt: DateTime.now(),
          syncedAt: sale.syncedAt,
        );
      }).toList();
    }
  }

  @override
  Future<List<entity.Sale>> getByLocation(String locationId) async {
    try {
      final sales = await remoteDataSource.getSales(locationId: locationId);
      return sales;
    } catch (e) {
      final all = await getAll();
      return all.where((s) => s.locationId == locationId).toList();
    }
  }

  @override
  Future<List<entity.Sale>> getByDateRange(DateTime start, DateTime end) async {
    try {
      final sales = await remoteDataSource.getSales(
        startDate: start,
        endDate: end,
      );
      return sales;
    } catch (e) {
      final all = await getAll();
      return all.where((s) {
        return s.createdAt.isAfter(start) && s.createdAt.isBefore(end);
      }).toList();
    }
  }

  @override
  Future<List<entity.Sale>> getTodaySales() async {
    try {
      final sales = await remoteDataSource.getSales(todayOnly: true);
      return sales;
    } catch (e) {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      return getByDateRange(startOfDay, endOfDay);
    }
  }

  @override
  Future<entity.Sale> getById(String id) async {
    final sale = await (localDatabase.select(localDatabase.sales)
          ..where((s) => s.id.equals(id)))
        .getSingle();

    final location = await (localDatabase.select(localDatabase.locations)
          ..where((l) => l.id.equals(sale.locationId)))
        .getSingle();

    final employee = await (localDatabase.select(localDatabase.employees)
          ..where((e) => e.id.equals(sale.employeeId)))
        .getSingle();

    return SaleModel(
      id: sale.id,
      locationId: sale.locationId,
      locationName: location.name,
      employeeId: sale.employeeId,
      employeeName: employee.name,
      total: sale.total,
      createdAt: sale.createdAt,
      updatedAt: DateTime.now(),
      syncedAt: sale.syncedAt,
    );
  }

  @override
  Future<entity.Sale> create(
    entity.Sale sale,
    List<entity.SaleDetail> details,
  ) async {
    print('=== INICIANDO CREACIÓN DE VENTA ===');
    print('Sale ID: ${sale.id}');
    print('Location ID: ${sale.locationId}');
    print('Detalles: ${details.length} items');

    // Validar stock antes de crear la venta
    for (var detail in details) {
      final stock = await _getStock(detail.productId, sale.locationId);
      print(
          'Stock disponible para ${detail.productName}: $stock, necesita: ${detail.quantity}');

      if (stock < detail.quantity) {
        throw Exception(
            'Stock insuficiente para ${detail.productName}. Disponible: $stock, Necesita: ${detail.quantity}');
      }
    }

    final saleModel = SaleModel(
      id: sale.id,
      locationId: sale.locationId,
      locationName: sale.locationName,
      employeeId: sale.employeeId,
      employeeName: sale.employeeName,
      total: sale.total,
      createdAt: sale.createdAt,
      updatedAt: sale.updatedAt,
      syncedAt: sale.syncedAt,
    );

    final detailModels = details
        .map((d) => SaleDetailModel(
              id: d.id,
              productId: d.productId,
              productName: d.productName,
              quantity: d.quantity,
              unitPrice: d.unitPrice,
              subtotal: d.subtotal,
            ))
        .toList();

    try {
      print('Intentando crear venta en Supabase...');

      final created = await remoteDataSource.createSale(
        saleModel,
        detailModels,
      );

      print('✅ Venta creada en Supabase exitosamente!');

      await _saveToLocal(created, detailModels);

      print('✅ Guardado en local exitosamente!');

      return created;
    } catch (e) {
      print('❌ ERROR al crear en Supabase: $e');
      print('Guardando solo en local...');

      await _saveToLocal(saleModel, detailModels);

      // AGREGAR A COLA DE SINCRONIZACIÓN
      await _addToSyncQueue(saleModel, detailModels);

      print('✅ Guardado en local (offline)');

      return sale;
    }
  }

  Future<void> _addToSyncQueue(
    SaleModel sale,
    List<SaleDetailModel> details,
  ) async {
    final data = json.encode({
      'sale': sale.toJson(),
      'details': details.map((d) => d.toJson()).toList(),
    });

    await localDatabase.into(localDatabase.syncQueue).insert(
          SyncQueueCompanion.insert(
            id: const Uuid().v4(),
            operationType: 'sale',
            operationId: sale.id,
            data: data,
            status: 'pending',
            retryCount: const Value(0),
          ),
        );

    print('📝 Operación de venta agregada a cola de sincronización');
  }

  Future<int> _getStock(String productId, String locationId) async {
    final inventory = await (localDatabase.select(localDatabase.inventory)
          ..where((inv) =>
              inv.productId.equals(productId) &
              inv.locationId.equals(locationId)))
        .getSingleOrNull();

    return inventory?.quantity ?? 0;
  }

  Future<void> _saveToLocal(
    SaleModel sale,
    List<SaleDetailModel> details,
  ) async {
    print('=== GUARDANDO EN LOCAL ===');

    try {
      // Guardar venta
      await localDatabase.into(localDatabase.sales).insert(
            SalesCompanion.insert(
              id: sale.id,
              locationId: sale.locationId,
              employeeId: sale.employeeId,
              total: sale.total,
              createdAt: Value(sale.createdAt),
              syncedAt: Value(sale.syncedAt),
            ),
            mode: InsertMode.insertOrReplace,
          );
      print('✅ Venta guardada en Drift');

      // Guardar detalles
      for (var detail in details) {
        await localDatabase.into(localDatabase.saleDetails).insert(
              SaleDetailsCompanion.insert(
                id: detail.id,
                saleId: sale.id,
                productId: detail.productId,
                quantity: detail.quantity,
                unitPrice: detail.unitPrice,
                subtotal: detail.subtotal,
              ),
              mode: InsertMode.insertOrReplace,
            );
        print('✅ Detalle guardado: ${detail.productName}');
      }

      // Actualizar inventario local (restar cantidades)
      for (var detail in details) {
        print('Actualizando inventario para: ${detail.productId}');

        final existingInventory =
            await (localDatabase.select(localDatabase.inventory)
                  ..where((inv) =>
                      inv.productId.equals(detail.productId) &
                      inv.locationId.equals(sale.locationId)))
                .getSingleOrNull();

        if (existingInventory != null) {
          final newQuantity = existingInventory.quantity - detail.quantity;
          print(
              'Inventario existente: ${existingInventory.quantity} - ${detail.quantity} = $newQuantity');

          await (localDatabase.update(localDatabase.inventory)
                ..where((inv) => inv.id.equals(existingInventory.id)))
              .write(
            InventoryCompanion(
              quantity: Value(newQuantity),
              updatedAt: Value(DateTime.now()),
              syncedAt: const Value(null),
            ),
          );
        }
      }

      print('✅ Inventario actualizado en local');
    } catch (e) {
      print('❌ ERROR guardando en local: $e');
      rethrow;
    }
  }
}
