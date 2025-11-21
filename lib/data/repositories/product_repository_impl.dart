import 'package:drift/drift.dart';
import '../../domain/entities/product.dart' as entity;
import '../../domain/repositories/product_repository.dart';
import '../datasources/remote/supabase_datasource.dart';
import '../datasources/local/database.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final SupabaseDataSource remoteDataSource;
  final AppDatabase localDatabase;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDatabase,
  });

  @override
  Future<List<entity.Product>> getAll() async {
    try {
      final remoteProducts = await remoteDataSource.getAllProducts();

      // Guardar en local
      for (var product in remoteProducts) {
        await localDatabase.into(localDatabase.products).insert(
              ProductsCompanion.insert(
                id: product.id,
                name: product.name,
                description: Value(product.description),
                category: product.category,
                purchasePrice: product.purchasePrice,
                salePrice: product.salePrice,
                isActive: Value(product.isActive),
                createdAt: Value(product.createdAt),
                updatedAt: Value(product.updatedAt),
                syncedAt: Value(product.syncedAt),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }

      return remoteProducts;
    } catch (e) {
      // Si falla, obtener de local
      final localProducts =
          await localDatabase.select(localDatabase.products).get();
      return localProducts
          .map((p) => ProductModel(
                id: p.id,
                name: p.name,
                description: p.description,
                category: p.category,
                purchasePrice: p.purchasePrice,
                salePrice: p.salePrice,
                isActive: p.isActive,
                createdAt: p.createdAt,
                updatedAt: p.updatedAt,
                syncedAt: p.syncedAt,
              ))
          .toList();
    }
  }

  @override
  Future<List<entity.Product>> getByCategory(String category) async {
    final allProducts = await getAll();
    return allProducts.where((p) => p.category == category).toList();
  }

  @override
  Future<entity.Product> getById(String id) async {
    try {
      final product = await (localDatabase.select(localDatabase.products)
            ..where((p) => p.id.equals(id)))
          .getSingle();

      return ProductModel(
        id: product.id,
        name: product.name,
        description: product.description,
        category: product.category,
        purchasePrice: product.purchasePrice,
        salePrice: product.salePrice,
        isActive: product.isActive,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
        syncedAt: product.syncedAt,
      );
    } catch (e) {
      throw Exception('Producto no encontrado');
    }
  }

  @override
  Future<entity.Product> create(entity.Product product) async {
    final productModel = ProductModel.fromEntity(product);

    try {
      final created = await remoteDataSource.createProduct(productModel);

      // Guardar en local
      await localDatabase.into(localDatabase.products).insert(
            ProductsCompanion.insert(
              id: created.id,
              name: created.name,
              description: Value(created.description),
              category: created.category,
              purchasePrice: created.purchasePrice,
              salePrice: created.salePrice,
              isActive: Value(created.isActive),
              createdAt: Value(created.createdAt),
              updatedAt: Value(created.updatedAt),
              syncedAt: Value(created.syncedAt),
            ),
          );

      return created;
    } catch (e) {
      // Si falla, guardar solo en local
      await localDatabase.into(localDatabase.products).insert(
            ProductsCompanion.insert(
              id: product.id,
              name: product.name,
              description: Value(product.description),
              category: product.category,
              purchasePrice: product.purchasePrice,
              salePrice: product.salePrice,
              isActive: Value(product.isActive),
              createdAt: Value(product.createdAt),
              updatedAt: Value(product.updatedAt),
            ),
          );

      return product;
    }
  }

  @override
  Future<entity.Product> update(entity.Product product) async {
    await localDatabase.update(localDatabase.products).replace(
          Product(
            id: product.id,
            name: product.name,
            description: product.description,
            category: product.category,
            purchasePrice: product.purchasePrice,
            salePrice: product.salePrice,
            isActive: product.isActive,
            createdAt: product.createdAt,
            updatedAt: DateTime.now(),
            syncedAt: null,
          ),
        );

    return product;
  }

  @override
  Future<void> delete(String id) async {
    await (localDatabase.delete(localDatabase.products)
          ..where((p) => p.id.equals(id)))
        .go();
  }
}
