import 'package:equatable/equatable.dart';
import '../../entities/sale.dart';
import '../../repositories/sale_repository.dart';
import '../usecase.dart';

class CreateSaleUseCase implements UseCase<Sale, CreateSaleParams> {
  final SaleRepository repository;

  CreateSaleUseCase(this.repository);

  @override
  Future<Sale> call(CreateSaleParams params) async {
    return await repository.create(params.sale, params.details);
  }
}

class CreateSaleParams extends Equatable {
  final Sale sale;
  final List<SaleDetail> details;

  const CreateSaleParams({
    required this.sale,
    required this.details,
  });

  @override
  List<Object?> get props => [sale, details];
}
