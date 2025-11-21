import '../../domain/entities/purchase.dart';

class PurchaseDetailModel extends PurchaseDetail {
  const PurchaseDetailModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.quantity,
    required super.unitPrice,
    required super.subtotal,
  });

  factory PurchaseDetailModel.fromJson(Map<String, dynamic> json) {
    return PurchaseDetailModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }
}

class PurchaseModel extends Purchase {
  const PurchaseModel({
    required super.id,
    required super.locationId,
    required super.locationName,
    required super.employeeId,
    required super.employeeName,
    required super.supplier,
    required super.total,
    super.notes,
    super.details = const [],
    required super.createdAt,
    required super.updatedAt,
    super.syncedAt,
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id'] as String,
      locationId: json['location_id'] as String,
      locationName: json['location_name'] as String? ?? '',
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String? ?? '',
      supplier: json['supplier'] as String,
      total: (json['total'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location_id': locationId,
      'employee_id': employeeId,
      'supplier': supplier,
      'total': total,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
    };
  }
}
