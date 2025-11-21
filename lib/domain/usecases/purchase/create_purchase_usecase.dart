import 'package:equatable/equatable.dart';
import '../../entities/purchase.dart';
import '../../repositories/purchase_repository.dart';
import '../usecase.dart';

class CreatePurchaseUseCase implements UseCase<Purchase, CreatePurchaseParams> {
  final PurchaseRepository repository;

  CreatePurchaseUseCase(this.repository);

  @override
  Future<Purchase> call(CreatePurchaseParams params) async {
    return await repository.create(params.purchase, params.details);
  }
}

class CreatePurchaseParams extends Equatable {
  final Purchase purchase;
  final List<PurchaseDetail> details;

  const CreatePurchaseParams({
    required this.purchase,
    required this.details,
  });

  @override
  List<Object?> get props => [purchase, details];
}
