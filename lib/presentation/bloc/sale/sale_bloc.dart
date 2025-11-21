import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/sale/create_sale_usecase.dart';
import '../../../domain/usecases/sale/get_sales_usecase.dart';
import 'sale_event.dart';
import 'sale_state.dart';

class SaleBloc extends Bloc<SaleEvent, SaleState> {
  final CreateSaleUseCase createSaleUseCase;
  final GetSalesUseCase getSalesUseCase;

  SaleBloc({
    required this.createSaleUseCase,
    required this.getSalesUseCase,
  }) : super(SaleInitial()) {
    on<SaleCreateRequested>(_onCreateRequested);
    on<SaleLoadTodayRequested>(_onLoadTodayRequested);
  }

  Future<void> _onCreateRequested(
    SaleCreateRequested event,
    Emitter<SaleState> emit,
  ) async {
    emit(SaleCreating());
    try {
      final sale = await createSaleUseCase(
        CreateSaleParams(
          sale: event.sale,
          details: event.details,
        ),
      );
      emit(SaleCreated(sale));
    } catch (e) {
      emit(SaleError(e.toString()));
    }
  }

  Future<void> _onLoadTodayRequested(
    SaleLoadTodayRequested event,
    Emitter<SaleState> emit,
  ) async {
    emit(SaleLoading());
    try {
      final sales = await getSalesUseCase(const SalesParams(isToday: true));
      emit(SaleLoaded(sales));
    } catch (e) {
      emit(SaleError(e.toString()));
    }
  }
}
