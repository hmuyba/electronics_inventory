import 'package:equatable/equatable.dart';

class InventoryItem extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String productCategory;
  final String locationId;
  final String locationName;
  final String locationType;
  final int quantity;
  final double salePrice;
  final DateTime updatedAt;

  const InventoryItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.locationId,
    required this.locationName,
    required this.locationType,
    required this.quantity,
    required this.salePrice,
    required this.updatedAt,
  });

  bool get hasStock => quantity > 0;
  bool get isLowStock => quantity > 0 && quantity <= 5;
  bool get isOutOfStock => quantity == 0;

  @override
  List<Object?> get props => [
        id,
        productId,
        locationId,
        quantity,
      ];
}
