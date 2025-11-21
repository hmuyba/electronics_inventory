import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/location_repository.dart';
import '../../bloc/inventory/inventory_bloc.dart';
import '../../bloc/inventory/inventory_event.dart';
import 'create_sale_page.dart';

class SelectSaleLocationPage extends StatelessWidget {
  const SelectSaleLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
      ),
      body: FutureBuilder(
        future: context.read<LocationRepository>().getStores(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final stores = snapshot.data!;

          if (stores.isEmpty) {
            return const Center(
              child: Text('No hay tiendas disponibles'),
            );
          }

          return ListView.builder(
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];
              return ListTile(
                leading: const Icon(Icons.store, color: Colors.blue),
                title: Text(store.name),
                subtitle: const Text('Tienda'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Cargar inventario de esta ubicación
                  context.read<InventoryBloc>().add(
                        InventoryLoadRequested(locationId: store.id),
                      );

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateSalePage(
                        locationId: store.id,
                        locationName: store.name,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
