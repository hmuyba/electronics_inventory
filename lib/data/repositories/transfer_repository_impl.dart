import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/transfer.dart' as entity;
import '../../domain/repositories/transfer_repository.dart';
import '../datasources/remote/supabase_datasource.dart';
import '../datasources/local/database.dart';
import '../models/transfer_model.dart';

class TransferRepositoryImpl implements TransferRepository {
  final SupabaseDataSource remoteDataSource;
  final AppDatabase localDatabase;

  TransferRepositoryImpl({
    required this.remoteDataSource,
    required this.localDatabase,
  });

  @override
  Future<List<entity.Transfer>> getAll() async {
    try {
      final transfers = await remoteDataSource.getTransfers();
      return transfers;
    } catch (e) {
      print('❌ Error obteniendo de Supabase, leyendo de local: $e');

      // ✅ LEER DE LOCAL CON JOIN (igual que ventas/compras)
      final query = localDatabase.select(localDatabase.transfers).join([
        innerJoin(
          localDatabase.locations,
          localDatabase.locations.id
              .equalsExp(localDatabase.transfers.fromLocationId),
        ),
        innerJoin(
          localDatabase.employees,
          localDatabase.employees.id
              .equalsExp(localDatabase.transfers.employeeId),
        ),
      ]);

      final results = await query.get();

      final transfersList = <entity.Transfer>[];

      for (var row in results) {
        final transfer = row.readTable(localDatabase.transfers);
        final fromLocation = row.readTable(localDatabase.locations);
        final employee = row.readTable(localDatabase.employees);

        // Obtener ubicación destino
        final toLocation = await (localDatabase.select(localDatabase.locations)
              ..where((l) => l.id.equals(transfer.toLocationId)))
            .getSingleOrNull();

        // Obtener detalles de la transferencia
        final detailsQuery =
            await (localDatabase.select(localDatabase.transferDetails)
                  ..where((td) => td.transferId.equals(transfer.id)))
                .get();

        final details = <entity.TransferDetail>[];
        for (var detail in detailsQuery) {
          final product = await (localDatabase.select(localDatabase.products)
                ..where((p) => p.id.equals(detail.productId)))
              .getSingleOrNull();

          if (product != null) {
            details.add(entity.TransferDetail(
              id: detail.id,
              productId: detail.productId,
              productName: product.name,
              quantity: detail.quantity,
            ));
          }
        }

        if (toLocation != null) {
          transfersList.add(TransferModel(
            id: transfer.id,
            fromLocationId: transfer.fromLocationId,
            fromLocationName: fromLocation.name,
            toLocationId: transfer.toLocationId,
            toLocationName: toLocation.name,
            employeeId: transfer.employeeId,
            employeeName: employee.name,
            status: transfer.status,
            notes: transfer.notes,
            details: details,
            createdAt: transfer.createdAt,
            updatedAt: transfer.createdAt,
            syncedAt: transfer.syncedAt,
          ));
        }
      }

      return transfersList;
    }
  }

  @override
  Future<List<entity.Transfer>> getByFromLocation(String locationId) async {
    try {
      final transfers = await remoteDataSource.getTransfers(
        fromLocationId: locationId,
      );
      return transfers;
    } catch (e) {
      final all = await getAll();
      return all.where((t) => t.fromLocationId == locationId).toList();
    }
  }

  @override
  Future<List<entity.Transfer>> getByToLocation(String locationId) async {
    try {
      final transfers = await remoteDataSource.getTransfers(
        toLocationId: locationId,
      );
      return transfers;
    } catch (e) {
      final all = await getAll();
      return all.where((t) => t.toLocationId == locationId).toList();
    }
  }

  @override
  Future<List<entity.Transfer>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final transfers = await remoteDataSource.getTransfers(
        startDate: start,
        endDate: end,
      );
      return transfers;
    } catch (e) {
      final all = await getAll();
      return all.where((t) {
        return t.createdAt.isAfter(start) && t.createdAt.isBefore(end);
      }).toList();
    }
  }

  @override
  Future<entity.Transfer> getById(String id) async {
    final transfer = await (localDatabase.select(localDatabase.transfers)
          ..where((t) => t.id.equals(id)))
        .getSingle();

    final fromLocation = await (localDatabase.select(localDatabase.locations)
          ..where((l) => l.id.equals(transfer.fromLocationId)))
        .getSingle();

    final toLocation = await (localDatabase.select(localDatabase.locations)
          ..where((l) => l.id.equals(transfer.toLocationId)))
        .getSingle();

    final employee = await (localDatabase.select(localDatabase.employees)
          ..where((e) => e.id.equals(transfer.employeeId)))
        .getSingle();

    // Obtener detalles
    final detailsQuery =
        await (localDatabase.select(localDatabase.transferDetails)
              ..where((td) => td.transferId.equals(transfer.id)))
            .get();

    final details = <entity.TransferDetail>[];
    for (var detail in detailsQuery) {
      final product = await (localDatabase.select(localDatabase.products)
            ..where((p) => p.id.equals(detail.productId)))
          .getSingleOrNull();

      if (product != null) {
        details.add(entity.TransferDetail(
          id: detail.id,
          productId: detail.productId,
          productName: product.name,
          quantity: detail.quantity,
        ));
      }
    }

    return TransferModel(
      id: transfer.id,
      fromLocationId: transfer.fromLocationId,
      fromLocationName: fromLocation.name,
      toLocationId: transfer.toLocationId,
      toLocationName: toLocation.name,
      employeeId: transfer.employeeId,
      employeeName: employee.name,
      status: transfer.status,
      notes: transfer.notes,
      details: details,
      createdAt: transfer.createdAt,
      updatedAt: DateTime.now(),
      syncedAt: transfer.syncedAt,
    );
  }

  @override
  Future<entity.Transfer> create(
    entity.Transfer transfer,
    List<entity.TransferDetail> details,
  ) async {
    print('=== INICIANDO CREACIÓN DE TRANSFERENCIA ===');
    print('Transfer ID: ${transfer.id}');
    print('Desde: ${transfer.fromLocationName}');
    print('Hacia: ${transfer.toLocationName}');

    final transferModel = TransferModel(
      id: transfer.id,
      fromLocationId: transfer.fromLocationId,
      fromLocationName: transfer.fromLocationName,
      toLocationId: transfer.toLocationId,
      toLocationName: transfer.toLocationName,
      employeeId: transfer.employeeId,
      employeeName: transfer.employeeName,
      status: 'pending',
      notes: transfer.notes,
      createdAt: transfer.createdAt,
      updatedAt: transfer.updatedAt,
      syncedAt: transfer.syncedAt,
    );

    final detailModels = details
        .map((d) => TransferDetailModel(
              id: d.id,
              productId: d.productId,
              productName: d.productName,
              quantity: d.quantity,
            ))
        .toList();

    try {
      print('Intentando crear transferencia en Supabase...');

      final created = await remoteDataSource.createTransfer(
        transferModel,
        detailModels,
      );

      print('✅ Transferencia creada en Supabase');
      await _saveToLocal(created, detailModels);

      return created;
    } catch (e) {
      print('❌ ERROR al crear en Supabase: $e');
      print('Guardando solo en local...');

      await _saveToLocal(transferModel, detailModels);
      await _addToSyncQueue(transferModel, detailModels);

      print('✅ Guardado en local (offline)');
      return transfer;
    }
  }

  @override
  Future<entity.Transfer> updateStatus(String id, String status) async {
    print('=== ACTUALIZANDO STATUS DE TRANSFERENCIA ===');
    print('Transfer ID: $id, Nuevo status: $status');

    try {
      final updated = await remoteDataSource.updateTransferStatus(id, status);

      // Actualizar en local
      await (localDatabase.update(localDatabase.transfers)
            ..where((t) => t.id.equals(id)))
          .write(
        TransfersCompanion(
          status: Value(status),
          syncedAt: Value(DateTime.now()),
        ),
      );

      print('✅ Status actualizado en Supabase y local');
      return updated;
    } catch (e) {
      print('❌ ERROR actualizando en Supabase: $e');
      print('Actualizando solo en local y agregando a cola...');

      // Actualizar solo en local
      await (localDatabase.update(localDatabase.transfers)
            ..where((t) => t.id.equals(id)))
          .write(
        TransfersCompanion(
          status: Value(status),
          syncedAt: const Value(null),
        ),
      );

      // Agregar a cola de sincronización
      await localDatabase.into(localDatabase.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: const Uuid().v4(),
              operationType: 'transfer_status_update',
              operationId: id,
              data: json.encode({'status': status}),
              status: 'pending',
              retryCount: const Value(0),
            ),
          );

      // Obtener el transfer de local para retornarlo
      final transfer = await getById(id);

      print('✅ Status actualizado en local (offline)');
      return transfer;
    }
  }

  Future<void> _saveToLocal(
    TransferModel transfer,
    List<TransferDetailModel> details,
  ) async {
    print('=== GUARDANDO TRANSFERENCIA EN LOCAL ===');

    // Guardar transferencia
    await localDatabase.into(localDatabase.transfers).insert(
          TransfersCompanion.insert(
            id: transfer.id,
            fromLocationId: transfer.fromLocationId,
            toLocationId: transfer.toLocationId,
            employeeId: transfer.employeeId,
            status: transfer.status,
            notes: Value(transfer.notes),
            createdAt: Value(transfer.createdAt),
            syncedAt: Value(transfer.syncedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );

    // Guardar detalles
    for (var detail in details) {
      await localDatabase.into(localDatabase.transferDetails).insert(
            TransferDetailsCompanion.insert(
              id: detail.id,
              transferId: transfer.id,
              productId: detail.productId,
              quantity: detail.quantity,
            ),
            mode: InsertMode.insertOrReplace,
          );
    }

    print('✅ Transferencia guardada en local');
  }

  Future<void> _addToSyncQueue(
    TransferModel transfer,
    List<TransferDetailModel> details,
  ) async {
    final data = json.encode({
      'transfer': transfer.toJson(),
      'details': details.map((d) => d.toJson()).toList(),
    });

    await localDatabase.into(localDatabase.syncQueue).insert(
          SyncQueueCompanion.insert(
            id: const Uuid().v4(),
            operationType: 'transfer',
            operationId: transfer.id,
            data: data,
            status: 'pending',
            retryCount: const Value(0),
          ),
        );

    print('📝 Operación de transferencia agregada a cola');
  }
}
