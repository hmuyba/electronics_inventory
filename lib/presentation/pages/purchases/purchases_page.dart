import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/purchase/purchase_bloc.dart';
import '../../bloc/purchase/purchase_state.dart';
import '../../bloc/inventory/inventory_bloc.dart';
import '../../bloc/inventory/inventory_event.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_event.dart';
import 'select_location_page.dart';

class PurchasesPage extends StatelessWidget {
  const PurchasesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras'),
      ),
      body: BlocListener<PurchaseBloc, PurchaseState>(
        listener: (context, state) {
          if (state is PurchaseCreated) {
            // Recargar inventario y productos
            context.read<InventoryBloc>().add(const InventoryLoadRequested());
            context.read<ProductBloc>().add(ProductLoadRequested());
          }
        },
        child: BlocBuilder<PurchaseBloc, PurchaseState>(
          builder: (context, state) {
            if (state is PurchaseCreated) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 80, color: Colors.green),
                    const SizedBox(height: 16),
                    const Text('¡Compra registrada exitosamente!'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Volver'),
                    ),
                  ],
                ),
              );
            }

            return const Center(
              child: Text('Seleccione una ubicación para registrar compra'),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SelectLocationPage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Compra'),
      ),
    );
  }
}
