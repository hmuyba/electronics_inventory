import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/repositories/location_repository.dart';
import 'create_purchase_page.dart';

class SelectLocationPage extends StatelessWidget {
  const SelectLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
      ),
      body: FutureBuilder<List<Location>>(
        future: context.read<LocationRepository>().getAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final locations = snapshot.data!;

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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreatePurchasePage(location: location),
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
