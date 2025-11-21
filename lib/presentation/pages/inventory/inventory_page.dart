import 'package:electronics_inventory/presentation/bloc/inventory/inventory_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/inventory/inventory_bloc.dart';
import '../../bloc/inventory/inventory_state.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  @override
  void initState() {
    super.initState();
    // Recargar inventario al entrar
    context.read<InventoryBloc>().add(const InventoryLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
      ),
      body: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) {
          if (state is InventoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InventoryError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is InventoryLoaded) {
            final items = state.items;

            if (items.isEmpty) {
              return const Center(child: Text('No hay inventario'));
            }

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final stockColor = item.isOutOfStock
                    ? Colors.red
                    : item.isLowStock
                        ? Colors.orange
                        : Colors.green;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(item.productName),
                    subtitle: Text(
                      '${item.locationName} (${item.locationType == 'store' ? 'Tienda' : 'Almacén'})',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: stockColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Stock: ${item.quantity}',
                        style: TextStyle(
                          color: stockColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return const Center(child: Text('Cargando inventario...'));
        },
      ),
    );
  }
}
