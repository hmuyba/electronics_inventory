import 'package:equatable/equatable.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

class InventoryLoadRequested extends InventoryEvent {
  final String? locationId;

  const InventoryLoadRequested({this.locationId});

  @override
  List<Object?> get props => [locationId];
}
