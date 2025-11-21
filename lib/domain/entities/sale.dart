import 'entity_base.dart';

class SaleDetail {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const SaleDetail({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });
}

class Sale extends Entity {
  final String locationId;
  final String locationName;
  final String employeeId;
  final String employeeName;
  final double total;
  final List<SaleDetail> details;

  const Sale({
    required super.id,
    required this.locationId,
    required this.locationName,
    required this.employeeId,
    required this.employeeName,
    required this.total,
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
        total,
      ];
}
