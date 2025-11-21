import 'entity_base.dart';

class TransferDetail {
  final String id;
  final String productId;
  final String productName;
  final int quantity;

  const TransferDetail({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
  });
}

class Transfer extends Entity {
  final String fromLocationId;
  final String fromLocationName;
  final String toLocationId;
  final String toLocationName;
  final String employeeId;
  final String employeeName;
  final String status;
  final String? notes;
  final List<TransferDetail> details;

  const Transfer({
    required super.id,
    required this.fromLocationId,
    required this.fromLocationName,
    required this.toLocationId,
    required this.toLocationName,
    required this.employeeId,
    required this.employeeName,
    required this.status,
    this.notes,
    this.details = const [],
    required super.createdAt,
    required super.updatedAt,
    super.syncedAt,
  });

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  @override
  List<Object?> get props => [
        id,
        fromLocationId,
        toLocationId,
        employeeId,
        status,
        notes,
      ];
}
