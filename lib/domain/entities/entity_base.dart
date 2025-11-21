import 'package:equatable/equatable.dart';

abstract class Entity extends Equatable {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;

  const Entity({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
  });

  bool get isSynced => syncedAt != null;

  @override
  List<Object?> get props => [id];
}
