import 'package:equatable/equatable.dart';
import '../../../domain/entities/sale.dart';

abstract class SaleState extends Equatable {
  const SaleState();

  @override
  List<Object?> get props => [];
}

class SaleInitial extends SaleState {}

class SaleLoading extends SaleState {}

class SaleLoaded extends SaleState {
  final List<Sale> sales;

  const SaleLoaded(this.sales);

  @override
  List<Object?> get props => [sales];
}

class SaleCreating extends SaleState {}

class SaleCreated extends SaleState {
  final Sale sale;

  const SaleCreated(this.sale);

  @override
  List<Object?> get props => [sale];
}

class SaleError extends SaleState {
  final String message;

  const SaleError(this.message);

  @override
  List<Object?> get props => [message];
}
