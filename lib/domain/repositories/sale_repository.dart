import '../entities/sale.dart';

abstract class SaleRepository {
  Future<List<Sale>> getAll();
  Future<List<Sale>> getByLocation(String locationId);
  Future<List<Sale>> getByDateRange(DateTime start, DateTime end);
  Future<List<Sale>> getTodaySales();
  Future<Sale> getById(String id);
  Future<Sale> create(Sale sale, List<SaleDetail> details);
}
