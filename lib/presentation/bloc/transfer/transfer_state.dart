import 'package:equatable/equatable.dart';
import '../../../domain/entities/transfer.dart';

abstract class TransferState extends Equatable {
  const TransferState();

  @override
  List<Object?> get props => [];
}

class TransferInitial extends TransferState {}

class TransferLoading extends TransferState {}

class TransferCreated extends TransferState {
  final Transfer transfer;

  const TransferCreated(this.transfer);

  @override
  List<Object?> get props => [transfer];
}

class TransferCompleted extends TransferState {
  final Transfer transfer;

  const TransferCompleted(this.transfer);

  @override
  List<Object?> get props => [transfer];
}

// NUEVO: Estado con lista de transferencias
class TransferLoaded extends TransferState {
  final List<Transfer> transfers;

  const TransferLoaded(this.transfers);

  @override
  List<Object?> get props => [transfers];
}

class TransferError extends TransferState {
  final String message;

  const TransferError(this.message);

  @override
  List<Object?> get props => [message];
}
