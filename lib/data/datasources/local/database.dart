import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Employees,
  Locations,
  EmployeeLocations,
  Products,
  Inventory,
  Purchases,
  PurchaseDetails,
  Sales,
  SaleDetails,
  Transfers,
  TransferDetails,
  SyncQueue,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'electronics_inventory.db'));
      return NativeDatabase(file);
    });
  }
}
