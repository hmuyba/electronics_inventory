import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/purchase/create_purchase_usecase.dart';
import 'purchase_event.dart';
import 'purchase_state.dart';

class PurchaseBloc extends Bloc<PurchaseEvent, PurchaseState> {
  final CreatePurchaseUseCase createPurchaseUseCase;

  PurchaseBloc({
    required this.createPurchaseUseCase,
  }) : super(PurchaseInitial()) {
    on<PurchaseCreateRequested>(_onCreateRequested);
  }

  Future<void> _onCreateRequested(
    PurchaseCreateRequested event,
    Emitter<PurchaseState> emit,
  ) async {
    emit(PurchaseCreating());
    try {
      final purchase = await createPurchaseUseCase(
        CreatePurchaseParams(
          purchase: event.purchase,
          details: event.details,
        ),
      );
      emit(PurchaseCreated(purchase));
    } catch (e) {
      emit(PurchaseError(e.toString()));
    }
  }
}
