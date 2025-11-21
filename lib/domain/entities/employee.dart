import 'entity_base.dart';

class Employee extends Entity {
  final String userId;
  final String name;
  final String email;
  final String role;
  final bool isActive;

  const Employee({
    required super.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.syncedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        email,
        role,
        isActive,
      ];
}
