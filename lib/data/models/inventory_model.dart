import '../../domain/entities/inventory.dart';

class InventoryItemModel extends InventoryItem {
  const InventoryItemModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.productCategory,
    required super.locationId,
    required super.locationName,
    required super.locationType,
    required super.quantity,
    required super.salePrice,
    required super.updatedAt,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      productCategory: json['product_category'] as String,
      locationId: json['location_id'] as String,
      locationName: json['location_name'] as String,
      locationType: json['location_type'] as String,
      quantity: json['quantity'] as int,
      salePrice: (json['sale_price'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_category': productCategory,
      'location_id': locationId,
      'location_name': locationName,
      'location_type': locationType,
      'quantity': quantity,
      'sale_price': salePrice,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
