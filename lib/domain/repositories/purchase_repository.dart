import '../entities/purchase.dart';

abstract class PurchaseRepository {
  Future<List<Purchase>> getAll();
  Future<List<Purchase>> getByLocation(String locationId);
  Future<List<Purchase>> getByDateRange(DateTime start, DateTime end);
  Future<Purchase> getById(String id);
  Future<Purchase> create(Purchase purchase, List<PurchaseDetail> details);
}
