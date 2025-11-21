import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/transfer/transfer_bloc.dart';
import '../../bloc/transfer/transfer_state.dart';
import '../../bloc/inventory/inventory_bloc.dart';
import '../../bloc/inventory/inventory_event.dart';
import 'select_transfer_location_page.dart';
import 'pending_transfers_page.dart';

class TransfersPage extends StatelessWidget {
  const TransfersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transferencias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pending_actions),
            tooltip: 'Ver pendientes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PendingTransfersPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocListener<TransferBloc, TransferState>(
        listener: (context, state) {
          if (state is TransferCreated) {
            context.read<InventoryBloc>().add(const InventoryLoadRequested());
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.swap_horiz, size: 100, color: Colors.indigo),
              const SizedBox(height: 24),
              const Text(
                'Transferencias entre Ubicaciones',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Crea transferencias para mover productos entre tiendas y almacenes',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PendingTransfersPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.list),
                label: const Text('Ver Pendientes'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SelectTransferLocationPage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Transferencia'),
      ),
    );
  }
}
