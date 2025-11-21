import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/product/get_products_usecase.dart';
import '../../../domain/usecases/product/create_product_usecase.dart';
import '../../../domain/usecases/usecase.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUseCase getProductsUseCase;
  final CreateProductUseCase createProductUseCase;

  ProductBloc({
    required this.getProductsUseCase,
    required this.createProductUseCase,
  }) : super(ProductInitial()) {
    on<ProductLoadRequested>(_onLoadRequested);
    on<ProductCreateRequested>(_onCreateRequested);
    on<ProductFilterByCategory>(_onFilterByCategory);
  }

  Future<void> _onLoadRequested(
    ProductLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      final products = await getProductsUseCase(NoParams());
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onCreateRequested(
    ProductCreateRequested event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await createProductUseCase(event.product);
      add(ProductLoadRequested());
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  void _onFilterByCategory(
    ProductFilterByCategory event,
    Emitter<ProductState> emit,
  ) {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      emit(ProductLoaded(
        currentState.products,
        selectedCategory: event.category,
      ));
    }
  }
}
