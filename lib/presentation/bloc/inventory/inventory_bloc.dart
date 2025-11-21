import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/inventory/get_inventory_usecase.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final GetInventoryUseCase getInventoryUseCase;

  InventoryBloc({
    required this.getInventoryUseCase,
  }) : super(InventoryInitial()) {
    on<InventoryLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    InventoryLoadRequested event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    try {
      final items = await getInventoryUseCase(
        InventoryParams(locationId: event.locationId),
      );
      emit(InventoryLoaded(items));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }
}
