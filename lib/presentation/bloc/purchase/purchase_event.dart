import 'package:equatable/equatable.dart';
import '../../../domain/entities/purchase.dart';

abstract class PurchaseEvent extends Equatable {
  const PurchaseEvent();

  @override
  List<Object?> get props => [];
}

class PurchaseLoadRequested extends PurchaseEvent {}

class PurchaseCreateRequested extends PurchaseEvent {
  final Purchase purchase;
  final List<PurchaseDetail> details;

  const PurchaseCreateRequested({
    required this.purchase,
    required this.details,
  });

  @override
  List<Object?> get props => [purchase, details];
}
