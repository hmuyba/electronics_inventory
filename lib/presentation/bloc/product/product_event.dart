import 'package:equatable/equatable.dart';
import '../../../domain/entities/product.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class ProductLoadRequested extends ProductEvent {}

class ProductCreateRequested extends ProductEvent {
  final Product product;

  const ProductCreateRequested(this.product);

  @override
  List<Object?> get props => [product];
}

class ProductFilterByCategory extends ProductEvent {
  final String? category;

  const ProductFilterByCategory(this.category);

  @override
  List<Object?> get props => [category];
}