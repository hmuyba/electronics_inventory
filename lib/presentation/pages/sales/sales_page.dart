import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/sale/sale_bloc.dart';
import '../../bloc/sale/sale_state.dart';
import '../../bloc/inventory/inventory_bloc.dart';
import '../../bloc/inventory/inventory_event.dart';
import 'select_sale_location_page.dart';

class SalesPage extends StatelessWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
      ),
      body: BlocListener<SaleBloc, SaleState>(
        listener: (context, state) {
          if (state is SaleCreated) {
            context.read<InventoryBloc>().add(const InventoryLoadRequested());
          }
        },
        child: BlocBuilder<SaleBloc, SaleState>(
          builder: (context, state) {
            if (state is SaleCreated) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 80, color: Colors.green),
                    const SizedBox(height: 16),
                    const Text('¡Venta registrada exitosamente!'),
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
              child: Text('Seleccione una ubicación para registrar venta'),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SelectSaleLocationPage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Venta'),
      ),
    );
  }
}
