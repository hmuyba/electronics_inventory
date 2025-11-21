import 'package:equatable/equatable.dart';
import '../../../domain/entities/sale.dart';

abstract class SaleEvent extends Equatable {
  const SaleEvent();

  @override
  List<Object?> get props => [];
}

class SaleLoadRequested extends SaleEvent {}

class SaleCreateRequested extends SaleEvent {
  final Sale sale;
  final List<SaleDetail> details;

  const SaleCreateRequested({
    required this.sale,
    required this.details,
  });

  @override
  List<Object?> get props => [sale, details];
}

class SaleLoadTodayRequested extends SaleEvent {}
