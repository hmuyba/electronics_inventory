import '../entities/location.dart';

abstract class LocationRepository {
  Future<List<Location>> getAll();
  Future<List<Location>> getStores();
  Future<List<Location>> getWarehouses();
  Future<Location> getById(String id);
  Future<Location> create(Location location);
  Future<Location> update(Location location);
  Future<void> delete(String id);
}
