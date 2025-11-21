import 'package:equatable/equatable.dart';
import '../../entities/sale.dart';
import '../../repositories/sale_repository.dart';
import '../usecase.dart';

class GetSalesUseCase implements UseCase<List<Sale>, SalesParams> {
  final SaleRepository repository;

  GetSalesUseCase(this.repository);

  @override
  Future<List<Sale>> call(SalesParams params) async {
    if (params.isToday) {
      return await repository.getTodaySales();
    }
    if (params.locationId != null) {
      return await repository.getByLocation(params.locationId!);
    }
    if (params.startDate != null && params.endDate != null) {
      return await repository.getByDateRange(
          params.startDate!, params.endDate!);
    }
    return await repository.getAll();
  }
}

class SalesParams extends Equatable {
  final String? locationId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isToday;

  const SalesParams({
    this.locationId,
    this.startDate,
    this.endDate,
    this.isToday = false,
  });

  @override
  List<Object?> get props => [locationId, startDate, endDate, isToday];
}
