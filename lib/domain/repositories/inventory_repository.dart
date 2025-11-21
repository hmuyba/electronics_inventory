import '../entities/inventory.dart';

abstract class InventoryRepository {
  Future<List<InventoryItem>> getAll();
  Future<List<InventoryItem>> getByLocation(String locationId);
  Future<List<InventoryItem>> getByProduct(String productId);
  Future<InventoryItem?> getByProductAndLocation(
      String productId, String locationId);
  Future<int> getStockByProductAndLocation(String productId, String locationId);
}
