import '../../repositories/sync_repository.dart';
import '../usecase.dart';

class SyncPendingOperationsUseCase implements UseCase<void, NoParams> {
  final SyncRepository repository;

  SyncPendingOperationsUseCase(this.repository);

  @override
  Future<void> call(NoParams params) async {
    return await repository.syncPendingOperations();
  }
}