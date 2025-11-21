import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_event.dart';
import '../../bloc/product/product_state.dart';
import '../../../core/constants/roles.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.currency(symbol: 'Bs. ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is ProductLoaded) {
            final products = state.filteredProducts;

            if (products.isEmpty) {
              return const Center(child: Text('No hay productos'));
            }

            return Column(
              children: [
                // Filtro por categoría
                Container(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    value: state.selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todas las categorías'),
                      ),
                      ...ProductCategories.all.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(ProductCategories.getDisplayName(cat)),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      context.read<ProductBloc>().add(
                            ProductFilterByCategory(value),
                          );
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(product.name),
                          subtitle: Text(
                            ProductCategories.getDisplayName(product.category),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                numberFormat.format(product.salePrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Compra: ${numberFormat.format(product.purchasePrice)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const Center(child: Text('Cargando productos...'));
        },
      ),
    );
  }
}
