abstract class SyncRepository {
  Future<void> syncPendingOperations();
  Future<int> getPendingCount();
  Stream<int> get pendingCountStream;
}
