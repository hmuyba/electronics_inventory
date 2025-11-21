import '../../domain/entities/inventory.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/remote/supabase_datasource.dart';
import '../datasources/local/database.dart';
import 'package:drift/drift.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final SupabaseDataSource remoteDataSource;
  final AppDatabase localDatabase;

  InventoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDatabase,
  });

  @override
  Future<List<InventoryItem>> getAll() async {
    try {
      final items = await remoteDataSource.getInventory();
      return items;
    } catch (e) {
      // Si falla, obtener de local con joins
      final query = localDatabase.select(localDatabase.inventory).join([
        innerJoin(
          localDatabase.products,
          localDatabase.products.id
              .equalsExp(localDatabase.inventory.productId),
        ),
        innerJoin(
          localDatabase.locations,
          localDatabase.locations.id
              .equalsExp(localDatabase.inventory.locationId),
        ),
      ]);

      final results = await query.get();

      return results.map((row) {
        final inv = row.readTable(localDatabase.inventory);
        final prod = row.readTable(localDatabase.products);
        final loc = row.readTable(localDatabase.locations);

        return InventoryItem(
          id: inv.id,
          productId: inv.productId,
          productName: prod.name,
          productCategory: prod.category,
          locationId: inv.locationId,
          locationName: loc.name,
          locationType: loc.type,
          quantity: inv.quantity,
          salePrice: prod.salePrice,
          updatedAt: inv.updatedAt,
        );
      }).toList();
    }
  }

  @override
  Future<List<InventoryItem>> getByLocation(String locationId) async {
    try {
      final items = await remoteDataSource.getInventory(locationId: locationId);
      return items;
    } catch (e) {
      final query = localDatabase.select(localDatabase.inventory).join([
        innerJoin(
          localDatabase.products,
          localDatabase.products.id
              .equalsExp(localDatabase.inventory.productId),
        ),
        innerJoin(
          localDatabase.locations,
          localDatabase.locations.id
              .equalsExp(localDatabase.inventory.locationId),
        ),
      ])
        ..where(localDatabase.inventory.locationId.equals(locationId));

      final results = await query.get();

      return results.map((row) {
        final inv = row.readTable(localDatabase.inventory);
        final prod = row.readTable(localDatabase.products);
        final loc = row.readTable(localDatabase.locations);

        return InventoryItem(
          id: inv.id,
          productId: inv.productId,
          productName: prod.name,
          productCategory: prod.category,
          locationId: inv.locationId,
          locationName: loc.name,
          locationType: loc.type,
          quantity: inv.quantity,
          salePrice: prod.salePrice,
          updatedAt: inv.updatedAt,
        );
      }).toList();
    }
  }

  @override
  Future<List<InventoryItem>> getByProduct(String productId) async {
    final allItems = await getAll();
    return allItems.where((item) => item.productId == productId).toList();
  }

  @override
  Future<InventoryItem?> getByProductAndLocation(
    String productId,
    String locationId,
  ) async {
    final items = await getByLocation(locationId);
    try {
      return items.firstWhere(
        (item) => item.productId == productId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int> getStockByProductAndLocation(
    String productId,
    String locationId,
  ) async {
    final item = await getByProductAndLocation(productId, locationId);
    return item?.quantity ?? 0;
  }
}
