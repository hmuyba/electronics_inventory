import 'package:drift/drift.dart';
import '../../domain/entities/location.dart' as entity;
import '../../domain/repositories/location_repository.dart';
import '../datasources/remote/supabase_datasource.dart';
import '../datasources/local/database.dart';
import '../models/location_model.dart';

class LocationRepositoryImpl implements LocationRepository {
  final SupabaseDataSource remoteDataSource;
  final AppDatabase localDatabase;

  LocationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDatabase,
  });

  @override
  Future<List<entity.Location>> getAll() async {
    try {
      final remoteLocations = await remoteDataSource.getAllLocations();

      // Guardar en local
      for (var location in remoteLocations) {
        await localDatabase.into(localDatabase.locations).insert(
              LocationsCompanion.insert(
                id: location.id,
                name: location.name,
                type: location.type,
                address: location.address,
                phone: Value(location.phone),
                isActive: Value(location.isActive),
                createdAt: Value(location.createdAt),
                updatedAt: Value(location.updatedAt),
                syncedAt: Value(location.syncedAt),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }

      return remoteLocations;
    } catch (e) {
      final localLocations =
          await localDatabase.select(localDatabase.locations).get();
      return localLocations
          .map((l) => LocationModel(
                id: l.id,
                name: l.name,
                type: l.type,
                address: l.address,
                phone: l.phone,
                isActive: l.isActive,
                createdAt: l.createdAt,
                updatedAt: l.updatedAt,
                syncedAt: l.syncedAt,
              ))
          .toList();
    }
  }

  @override
  Future<List<entity.Location>> getStores() async {
    final all = await getAll();
    return all.where((l) => l.type == 'store').toList();
  }

  @override
  Future<List<entity.Location>> getWarehouses() async {
    final all = await getAll();
    return all.where((l) => l.type == 'warehouse').toList();
  }

  @override
  Future<entity.Location> getById(String id) async {
    final location = await (localDatabase.select(localDatabase.locations)
          ..where((l) => l.id.equals(id)))
        .getSingle();

    return LocationModel(
      id: location.id,
      name: location.name,
      type: location.type,
      address: location.address,
      phone: location.phone,
      isActive: location.isActive,
      createdAt: location.createdAt,
      updatedAt: location.updatedAt,
      syncedAt: location.syncedAt,
    );
  }

  @override
  Future<entity.Location> create(entity.Location location) async {
    throw UnimplementedError();
  }

  @override
  Future<entity.Location> update(entity.Location location) async {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String id) async {
    throw UnimplementedError();
  }
}
