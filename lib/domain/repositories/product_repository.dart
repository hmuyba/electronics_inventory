import '../entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getAll();
  Future<List<Product>> getByCategory(String category);
  Future<Product> getById(String id);
  Future<Product> create(Product product);
  Future<Product> update(Product product);
  Future<void> delete(String id);
}
