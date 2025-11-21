import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/transfer/create_transfer_usecase.dart';
import '../../../domain/repositories/transfer_repository.dart';
import 'transfer_event.dart';
import 'transfer_state.dart';

class TransferBloc extends Bloc<TransferEvent, TransferState> {
  final CreateTransferUseCase createTransferUseCase;
  final TransferRepository transferRepository;

  TransferBloc({
    required this.createTransferUseCase,
    required this.transferRepository,
  }) : super(TransferInitial()) {
    on<TransferCreateRequested>(_onCreateRequested);
    on<TransferCompleteRequested>(_onCompleteRequested);
    on<TransferLoadRequested>(_onLoadRequested);
    on<TransferLoadPendingRequested>(_onLoadPendingRequested);
  }

  Future<void> _onCreateRequested(
    TransferCreateRequested event,
    Emitter<TransferState> emit,
  ) async {
    emit(TransferLoading());
    try {
      final transfer = await createTransferUseCase(
        CreateTransferParams(
          transfer: event.transfer,
          details: event.details,
        ),
      );
      emit(TransferCreated(transfer));
    } catch (e) {
      emit(TransferError(e.toString()));
    }
  }

  Future<void> _onCompleteRequested(
    TransferCompleteRequested event,
    Emitter<TransferState> emit,
  ) async {
    emit(TransferLoading());
    try {
      final transfer = await transferRepository.updateStatus(
        event.transferId,
        'completed',
      );
      emit(TransferCompleted(transfer));
    } catch (e) {
      emit(TransferError(e.toString()));
    }
  }

  Future<void> _onLoadRequested(
    TransferLoadRequested event,
    Emitter<TransferState> emit,
  ) async {
    emit(TransferLoading());
    try {
      final transfers = await transferRepository.getAll();
      emit(TransferLoaded(transfers));
    } catch (e) {
      emit(TransferError(e.toString()));
    }
  }

  Future<void> _onLoadPendingRequested(
    TransferLoadPendingRequested event,
    Emitter<TransferState> emit,
  ) async {
    emit(TransferLoading());
    try {
      final allTransfers = await transferRepository.getAll();
      final pendingTransfers =
          allTransfers.where((t) => t.status == 'pending').toList();
      emit(TransferLoaded(pendingTransfers));
    } catch (e) {
      emit(TransferError(e.toString()));
    }
  }
}
