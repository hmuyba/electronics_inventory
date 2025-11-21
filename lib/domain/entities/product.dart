import 'entity_base.dart';

class Product extends Entity {
  final String name;
  final String? description;
  final String category;
  final double purchasePrice;
  final double salePrice;
  final bool isActive;

  const Product({
    required super.id,
    required this.name,
    this.description,
    required this.category,
    required this.purchasePrice,
    required this.salePrice,
    required this.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.syncedAt,
  });

  double get profit => salePrice - purchasePrice;
  double get profitMargin => ((profit / purchasePrice) * 100);

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        purchasePrice,
        salePrice,
        isActive,
      ];
}
