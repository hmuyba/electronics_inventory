import '../../domain/entities/transfer.dart';

class TransferDetailModel extends TransferDetail {
  const TransferDetailModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.quantity,
  });

  factory TransferDetailModel.fromJson(Map<String, dynamic> json) {
    return TransferDetailModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String? ?? '',
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'quantity': quantity,
    };
  }
}

class TransferModel extends Transfer {
  const TransferModel({
    required super.id,
    required super.fromLocationId,
    required super.fromLocationName,
    required super.toLocationId,
    required super.toLocationName,
    required super.employeeId,
    required super.employeeName,
    required super.status,
    super.notes,
    super.details = const [],
    required super.createdAt,
    required super.updatedAt,
    super.syncedAt,
  });

  factory TransferModel.fromJson(Map<String, dynamic> json) {
    return TransferModel(
      id: json['id'] as String,
      fromLocationId: json['from_location_id'] as String,
      fromLocationName: json['from_location_name'] as String? ?? '',
      toLocationId: json['to_location_id'] as String,
      toLocationName: json['to_location_name'] as String? ?? '',
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      details: (json['details'] as List<dynamic>?)
              ?.map((d) =>
                  TransferDetailModel.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_location_id': fromLocationId,
      'to_location_id': toLocationId,
      'employee_id': employeeId,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
    };
  }
}
