import 'package:equatable/equatable.dart';
import '../../../domain/entities/purchase.dart';

abstract class PurchaseState extends Equatable {
  const PurchaseState();

  @override
  List<Object?> get props => [];
}

class PurchaseInitial extends PurchaseState {}

class PurchaseLoading extends PurchaseState {}

class PurchaseLoaded extends PurchaseState {
  final List<Purchase> purchases;

  const PurchaseLoaded(this.purchases);

  @override
  List<Object?> get props => [purchases];
}

class PurchaseCreating extends PurchaseState {}

class PurchaseCreated extends PurchaseState {
  final Purchase purchase;

  const PurchaseCreated(this.purchase);

  @override
  List<Object?> get props => [purchase];
}

class PurchaseError extends PurchaseState {
  final String message;

  const PurchaseError(this.message);

  @override
  List<Object?> get props => [message];
}
