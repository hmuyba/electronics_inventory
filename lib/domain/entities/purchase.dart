import 'entity_base.dart';

class PurchaseDetail {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const PurchaseDetail({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });
}

class Purchase extends Entity {
  final String locationId;
  final String locationName;
  final String employeeId;
  final String employeeName;
  final String supplier;
  final double total;
  final String? notes;
  final List<PurchaseDetail> details;

  const Purchase({
    required super.id,
    required this.locationId,
    required this.locationName,
    required this.employeeId,
    required this.employeeName,
    required this.supplier,
    required this.total,
    this.notes,
    this.details = const [],
    required super.createdAt,
    required super.updatedAt,
    super.syncedAt,
  });

  @override
  List<Object?> get props => [
        id,
        locationId,
        employeeId,
        supplier,
        total,
        notes,
      ];
}
