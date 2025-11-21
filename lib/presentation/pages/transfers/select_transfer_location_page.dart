import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/location_repository.dart';
import '../../bloc/inventory/inventory_bloc.dart';
import '../../bloc/inventory/inventory_event.dart';
import 'create_transfer_page.dart';

class SelectTransferLocationPage extends StatelessWidget {
  const SelectTransferLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación de Origen'),
      ),
      body: FutureBuilder(
        future: RepositoryProvider.of<LocationRepository>(context).getAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final locations = snapshot.data!;

          if (locations.isEmpty) {
            return const Center(
              child: Text('No hay ubicaciones disponibles'),
            );
          }

          return ListView.builder(
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return ListTile(
                leading: Icon(
                  location.isStore ? Icons.store : Icons.warehouse,
                  color: Colors.blue,
                ),
                title: Text(location.name),
                subtitle: Text(location.isStore ? 'Tienda' : 'Almacén'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Cargar inventario de esta ubicación
                  context.read<InventoryBloc>().add(
                        InventoryLoadRequested(locationId: location.id),
                      );

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateTransferPage(
                        fromLocation: location,
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
