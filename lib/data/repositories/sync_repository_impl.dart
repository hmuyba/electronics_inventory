import 'dart:convert';
import 'package:drift/drift.dart';
import '../models/transfer_model.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../core/utils/connectivity_helper.dart';
import '../datasources/local/database.dart';
import '../datasources/remote/supabase_datasource.dart';
import '../models/purchase_model.dart';
import '../models/sale_model.dart';

class SyncRepositoryImpl implements SyncRepository {
  final AppDatabase localDatabase;
  final SupabaseDataSource remoteDataSource;

  SyncRepositoryImpl({
    required this.localDatabase,
    required this.remoteDataSource,
  });

  @override
  Future<void> syncPendingOperations() async {
    print('=== INICIANDO SINCRONIZACIÓN ===');

    final hasConnection = await ConnectivityHelper.hasConnection();
    if (!hasConnection) {
      print('❌ Sin conexión, no se puede sincronizar');
      return;
    }

    final pendingOps = await (localDatabase.select(localDatabase.syncQueue)
          ..where((sq) => sq.status.equals('pending'))
          ..orderBy([(sq) => OrderingTerm.asc(sq.createdAt)]))
        .get();

    print('Operaciones pendientes: ${pendingOps.length}');

    // Procesar operaciones pendientes (si hay)
    for (var op in pendingOps) {
      try {
        print('Sincronizando: ${op.operationType} - ${op.operationId}');

        await (localDatabase.update(localDatabase.syncQueue)
              ..where((sq) => sq.id.equals(op.id)))
            .write(
          SyncQueueCompanion(
            status: const Value('syncing'),
            updatedAt: Value(DateTime.now()),
          ),
        );

        switch (op.operationType) {
          case 'purchase':
            await _syncPurchase(op);
            break;
          case 'sale':
            await _syncSale(op);
            break;
          case 'transfer':
          case 'transfer_status_update':
            await _syncTransfer(op);
            break;
        }

        await (localDatabase.update(localDatabase.syncQueue)
              ..where((sq) => sq.id.equals(op.id)))
            .write(
          SyncQueueCompanion(
            status: const Value('synced'),
            updatedAt: Value(DateTime.now()),
          ),
        );

        print('✅ Sincronizado: ${op.operationType}');
      } catch (e) {
        print('❌ Error sincronizando ${op.operationType}: $e');

        await (localDatabase.update(localDatabase.syncQueue)
              ..where((sq) => sq.id.equals(op.id)))
            .write(
          SyncQueueCompanion(
            status: const Value('failed'),
            errorMessage: Value(e.toString()),
            retryCount: Value(op.retryCount + 1),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    }

    // ✅ SIEMPRE sincronizar inventario (aunque no haya operaciones pendientes)
    await _syncInventoryFromRemote();

    print('=== SINCRONIZACIÓN COMPLETADA ===');
  }

  // ✅ NUEVO: Descargar inventario de Supabase y actualizar local
  Future<void> _syncInventoryFromRemote() async {
    print('📥 Sincronizando inventario desde Supabase...');

    try {
      final remoteInventory = await remoteDataSource.getInventory();

      for (var item in remoteInventory) {
        // Verificar si existe el registro
        final existing = await (localDatabase.select(localDatabase.inventory)
              ..where((inv) =>
                  inv.productId.equals(item.productId) &
                  inv.locationId.equals(item.locationId)))
            .getSingleOrNull();

        if (existing != null) {
          // Actualizar existente
          await (localDatabase.update(localDatabase.inventory)
                ..where((inv) => inv.id.equals(existing.id)))
              .write(
            InventoryCompanion(
              quantity: Value(item.quantity),
              updatedAt: Value(DateTime.now()),
              syncedAt: Value(DateTime.now()),
            ),
          );
        } else {
          // Crear nuevo
          await localDatabase.into(localDatabase.inventory).insert(
                InventoryCompanion.insert(
                  id: item.id,
                  productId: item.productId,
                  locationId: item.locationId,
                  quantity: Value(item.quantity),
                  updatedAt: Value(DateTime.now()),
                  syncedAt: Value(DateTime.now()),
                ),
                mode: InsertMode.insertOrReplace,
              );
        }
      }

      print('✅ Inventario sincronizado: ${remoteInventory.length} items');
    } catch (e) {
      print('❌ Error sincronizando inventario: $e');
    }
  }

  Future<void> _syncPurchase(SyncQueueData op) async {
    final data = json.decode(op.data) as Map<String, dynamic>;
    final purchaseData = data['purchase'] as Map<String, dynamic>;
    final detailsData = data['details'] as List;

    final purchase = PurchaseModel.fromJson(purchaseData);
    final details = detailsData
        .map((d) => PurchaseDetailModel.fromJson(d as Map<String, dynamic>))
        .toList();

    await remoteDataSource.createPurchase(purchase, details);
  }

  Future<void> _syncSale(SyncQueueData op) async {
    final data = json.decode(op.data) as Map<String, dynamic>;
    final saleData = data['sale'] as Map<String, dynamic>;
    final detailsData = data['details'] as List;

    final sale = SaleModel.fromJson(saleData);
    final details = detailsData
        .map((d) => SaleDetailModel.fromJson(d as Map<String, dynamic>))
        .toList();

    await remoteDataSource.createSale(sale, details);
  }

  Future<void> _syncTransfer(SyncQueueData op) async {
    final data = json.decode(op.data) as Map<String, dynamic>;

    print('🔄 _syncTransfer - operationType: ${op.operationType}');
    print('🔄 _syncTransfer - data: $data');

    if (op.operationType == 'transfer_status_update') {
      final transferId = op.operationId;
      final status = data['status'] as String;

      print('📤 Actualizando status en Supabase: $transferId -> $status');

      await Future.delayed(const Duration(milliseconds: 500));

      try {
        final result =
            await remoteDataSource.updateTransferStatus(transferId, status);
        print(
            '✅ Status actualizado en Supabase. Nuevo status: ${result.status}');

        if (result.status != status) {
          print(
              '⚠️ WARNING: El status retornado (${result.status}) no coincide con el esperado ($status)');
        }
      } catch (e) {
        print('❌ Error actualizando status: $e');
        rethrow;
      }

      await (localDatabase.update(localDatabase.transfers)
            ..where((t) => t.id.equals(transferId)))
          .write(
        TransfersCompanion(
          syncedAt: Value(DateTime.now()),
        ),
      );

      return;
    }

    final transferData = data['transfer'] as Map<String, dynamic>;
    final detailsData = data['details'] as List;

    transferData['status'] = 'pending';

    final transfer = TransferModel.fromJson(transferData);
    final details = detailsData
        .map((d) => TransferDetailModel.fromJson(d as Map<String, dynamic>))
        .toList();

    print(
        '📤 Creando transferencia en Supabase: ${transfer.id} con status: pending');
    await remoteDataSource.createTransfer(transfer, details);
    print('✅ Transferencia creada en Supabase');

    await (localDatabase.update(localDatabase.transfers)
          ..where((t) => t.id.equals(transfer.id)))
        .write(
      TransfersCompanion(
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<int> getPendingCount() async {
    final count = await (localDatabase.selectOnly(localDatabase.syncQueue)
          ..addColumns([localDatabase.syncQueue.id.count()])
          ..where(localDatabase.syncQueue.status.equals('pending')))
        .getSingle();

    return count.read(localDatabase.syncQueue.id.count()) ?? 0;
  }

  @override
  Stream<int> get pendingCountStream {
    return (localDatabase.select(localDatabase.syncQueue)
          ..where((sq) => sq.status.equals('pending')))
        .watch()
        .map((list) => list.length);
  }
}
