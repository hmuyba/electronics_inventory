import 'entity_base.dart';

class Location extends Entity {
  final String name;
  final String type;
  final String address;
  final String? phone;
  final bool isActive;

  const Location({
    required super.id,
    required this.name,
    required this.type,
    required this.address,
    this.phone,
    required this.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.syncedAt,
  });

  bool get isStore => type == 'store';
  bool get isWarehouse => type == 'warehouse';

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        address,
        phone,
        isActive,
      ];
}
