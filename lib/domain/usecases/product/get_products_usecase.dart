import '../../entities/product.dart';
import '../../repositories/product_repository.dart';
import '../usecase.dart';

class GetProductsUseCase implements UseCase<List<Product>, NoParams> {
  final ProductRepository repository;

  GetProductsUseCase(this.repository);

  @override
  Future<List<Product>> call(NoParams params) async {
    return await repository.getAll();
  }
}
