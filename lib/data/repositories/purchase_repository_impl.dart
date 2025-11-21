import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/purchase.dart' as entity;
import '../../domain/repositories/purchase_repository.dart';
import '../datasources/remote/supabase_datasource.dart';
import '../datasources/local/database.dart';
import '../models/purchase_model.dart';

class PurchaseRepositoryImpl implements PurchaseRepository {
  final SupabaseDataSource remoteDataSource;
  final AppDatabase localDatabase;

  PurchaseRepositoryImpl({
    required this.remoteDataSource,
    required this.localDatabase,
  });

  @override
  Future<List<entity.Purchase>> getAll() async {
    try {
      final purchases = await remoteDataSource.getPurchases();
      return purchases;
    } catch (e) {
      // Obtener de local
      final query = localDatabase.select(localDatabase.purchases).join([
        innerJoin(
          localDatabase.locations,
          localDatabase.locations.id
              .equalsExp(localDatabase.purchases.locationId),
        ),
        innerJoin(
          localDatabase.employees,
          localDatabase.employees.id
              .equalsExp(localDatabase.purchases.employeeId),
        ),
      ]);

      final results = await query.get();

      return results.map((row) {
        final purchase = row.readTable(localDatabase.purchases);
        final location = row.readTable(localDatabase.locations);
        final employee = row.readTable(localDatabase.employees);

        return PurchaseModel(
          id: purchase.id,
          locationId: purchase.locationId,
          locationName: location.name,
          employeeId: purchase.employeeId,
          employeeName: employee.name,
          supplier: purchase.supplier,
          total: purchase.total,
          notes: purchase.notes,
          createdAt: purchase.createdAt,
          updatedAt: DateTime.now(),
          syncedAt: purchase.syncedAt,
        );
      }).toList();
    }
  }

  @override
  Future<List<entity.Purchase>> getByLocation(String locationId) async {
    try {
      final purchases =
          await remoteDataSource.getPurchases(locationId: locationId);
      return purchases;
    } catch (e) {
      final all = await getAll();
      return all.where((p) => p.locationId == locationId).toList();
    }
  }

  @override
  Future<List<entity.Purchase>> getByDateRange(
      DateTime start, DateTime end) async {
    try {
      final purchases = await remoteDataSource.getPurchases(
        startDate: start,
        endDate: end,
      );
      return purchases;
    } catch (e) {
      final all = await getAll();
      return all.where((p) {
        return p.createdAt.isAfter(start) && p.createdAt.isBefore(end);
      }).toList();
    }
  }

  @override
  Future<entity.Purchase> getById(String id) async {
    final purchase = await (localDatabase.select(localDatabase.purchases)
          ..where((p) => p.id.equals(id)))
        .getSingle();

    final location = await (localDatabase.select(localDatabase.locations)
          ..where((l) => l.id.equals(purchase.locationId)))
        .getSingle();

    final employee = await (localDatabase.select(localDatabase.employees)
          ..where((e) => e.id.equals(purchase.employeeId)))
        .getSingle();

    return PurchaseModel(
      id: purchase.id,
      locationId: purchase.locationId,
      locationName: location.name,
      employeeId: purchase.employeeId,
      employeeName: employee.name,
      supplier: purchase.supplier,
      total: purchase.total,
      notes: purchase.notes,
      createdAt: purchase.createdAt,
      updatedAt: DateTime.now(),
      syncedAt: purchase.syncedAt,
    );
  }

  @override
  Future<entity.Purchase> create(
    entity.Purchase purchase,
    List<entity.PurchaseDetail> details,
  ) async {
    final purchaseModel = PurchaseModel(
      id: purchase.id,
      locationId: purchase.locationId,
      locationName: purchase.locationName,
      employeeId: purchase.employeeId,
      employeeName: purchase.employeeName,
      supplier: purchase.supplier,
      total: purchase.total,
      notes: purchase.notes,
      createdAt: purchase.createdAt,
      updatedAt: purchase.updatedAt,
      syncedAt: purchase.syncedAt,
    );

    final detailModels = details
        .map((d) => PurchaseDetailModel(
              id: d.id,
              productId: d.productId,
              productName: d.productName,
              quantity: d.quantity,
              unitPrice: d.unitPrice,
              subtotal: d.subtotal,
            ))
        .toList();

    try {
      // Intentar crear en Supabase
      final created = await remoteDataSource.createPurchase(
        purchaseModel,
        detailModels,
      );

      // Guardar en local
      await _saveToLocal(created, detailModels);

      return created;
    } catch (e) {
      print('❌ ERROR al crear en Supabase: $e');
      print('Guardando solo en local...');

      await _saveToLocal(purchaseModel, detailModels);

      // AGREGAR A COLA DE SINCRONIZACIÓN
      await _addToSyncQueue(purchaseModel, detailModels);

      print('✅ Guardado en local (offline)');

      return purchase;
    }
  }

  Future<void> _addToSyncQueue(
    PurchaseModel purchase,
    List<PurchaseDetailModel> details,
  ) async {
    final data = json.encode({
      'purchase': purchase.toJson(),
      'details': details.map((d) => d.toJson()).toList(),
    });

    await localDatabase.into(localDatabase.syncQueue).insert(
          SyncQueueCompanion.insert(
            id: const Uuid().v4(),
            operationType: 'purchase',
            operationId: purchase.id,
            data: data,
            status: 'pending',
            retryCount: const Value(0),
          ),
        );

    print('📝 Operación de compra agregada a cola de sincronización');
  }

  Future<void> _saveToLocal(
    PurchaseModel purchase,
    List<PurchaseDetailModel> details,
  ) async {
    print('=== GUARDANDO EN LOCAL ===');

    try {
      // Guardar compra
      await localDatabase.into(localDatabase.purchases).insert(
            PurchasesCompanion.insert(
              id: purchase.id,
              locationId: purchase.locationId,
              employeeId: purchase.employeeId,
              supplier: purchase.supplier,
              total: purchase.total,
              notes: Value(purchase.notes),
              createdAt: Value(purchase.createdAt),
              syncedAt: Value(purchase.syncedAt),
            ),
            mode: InsertMode.insertOrReplace,
          );
      print('✅ Compra guardada en Drift');

      // Guardar detalles
      for (var detail in details) {
        await localDatabase.into(localDatabase.purchaseDetails).insert(
              PurchaseDetailsCompanion.insert(
                id: detail.id,
                purchaseId: purchase.id,
                productId: detail.productId,
                quantity: detail.quantity,
                unitPrice: detail.unitPrice,
                subtotal: detail.subtotal,
              ),
              mode: InsertMode.insertOrReplace,
            );
        print('✅ Detalle guardado: ${detail.productName}');
      }

      // Actualizar inventario local
      for (var detail in details) {
        print('Actualizando inventario para: ${detail.productId}');

        final existingInventory =
            await (localDatabase.select(localDatabase.inventory)
                  ..where((inv) =>
                      inv.productId.equals(detail.productId) &
                      inv.locationId.equals(purchase.locationId)))
                .getSingleOrNull();

        if (existingInventory != null) {
          final newQuantity = existingInventory.quantity + detail.quantity;
          print(
              'Inventario existente: ${existingInventory.quantity} + ${detail.quantity} = $newQuantity');

          // USAR .write() EN VEZ DE .replace()
          await (localDatabase.update(localDatabase.inventory)
                ..where((inv) => inv.id.equals(existingInventory.id)))
              .write(
            InventoryCompanion(
              quantity: Value(newQuantity),
              updatedAt: Value(DateTime.now()),
              syncedAt: const Value(null),
            ),
          );
        } else {
          print('Creando nuevo inventario: ${detail.quantity}');
          // QUITAR Value() del id
          await localDatabase.into(localDatabase.inventory).insert(
                InventoryCompanion.insert(
                  id: '${detail.productId}_${purchase.locationId}',
                  productId: detail.productId,
                  locationId: purchase.locationId,
                  quantity: Value(detail.quantity),
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
