import '../../entities/location.dart';
import '../../repositories/location_repository.dart';
import '../usecase.dart';

class GetLocationsUseCase implements UseCase<List<Location>, NoParams> {
  final LocationRepository repository;

  GetLocationsUseCase(this.repository);

  @override
  Future<List<Location>> call(NoParams params) async {
    return await repository.getAll();
  }
}
