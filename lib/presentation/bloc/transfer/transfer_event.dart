import 'package:equatable/equatable.dart';
import '../../../domain/entities/transfer.dart';

abstract class TransferEvent extends Equatable {
  const TransferEvent();

  @override
  List<Object?> get props => [];
}

class TransferCreateRequested extends TransferEvent {
  final Transfer transfer;
  final List<TransferDetail> details;

  const TransferCreateRequested({
    required this.transfer,
    required this.details,
  });

  @override
  List<Object?> get props => [transfer, details];
}

class TransferCompleteRequested extends TransferEvent {
  final String transferId;

  const TransferCompleteRequested(this.transferId);

  @override
  List<Object?> get props => [transferId];
}

// NUEVO: Cargar lista de transferencias
class TransferLoadRequested extends TransferEvent {
  const TransferLoadRequested();
}

// NUEVO: Cargar transferencias pendientes
class TransferLoadPendingRequested extends TransferEvent {
  const TransferLoadPendingRequested();
}
