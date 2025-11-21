import '../../entities/product.dart';
import '../../repositories/product_repository.dart';
import '../usecase.dart';

class CreateProductUseCase implements UseCase<Product, Product> {
  final ProductRepository repository;

  CreateProductUseCase(this.repository);

  @override
  Future<Product> call(Product params) async {
    return await repository.create(params);
  }
}
