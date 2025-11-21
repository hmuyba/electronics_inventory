import '../entities/transfer.dart';

abstract class TransferRepository {
  Future<List<Transfer>> getAll();
  Future<List<Transfer>> getByFromLocation(String locationId);
  Future<List<Transfer>> getByToLocation(String locationId);
  Future<List<Transfer>> getByDateRange(DateTime start, DateTime end);
  Future<Transfer> getById(String id);
  Future<Transfer> create(Transfer transfer, List<TransferDetail> details);
  Future<Transfer> updateStatus(String id, String status);
}
