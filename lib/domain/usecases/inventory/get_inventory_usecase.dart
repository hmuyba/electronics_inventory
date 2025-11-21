import 'package:equatable/equatable.dart';
import '../../entities/inventory.dart';
import '../../repositories/inventory_repository.dart';
import '../usecase.dart';

class GetInventoryUseCase
    implements UseCase<List<InventoryItem>, InventoryParams> {
  final InventoryRepository repository;

  GetInventoryUseCase(this.repository);

  @override
  Future<List<InventoryItem>> call(InventoryParams params) async {
    if (params.locationId != null) {
      return await repository.getByLocation(params.locationId!);
    }
    return await repository.getAll();
  }
}

class InventoryParams extends Equatable {
  final String? locationId;

  const InventoryParams({this.locationId});

  @override
  List<Object?> get props => [locationId];
}
