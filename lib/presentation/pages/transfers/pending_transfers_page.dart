import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/transfer/transfer_bloc.dart';
import '../../bloc/transfer/transfer_event.dart';
import '../../bloc/transfer/transfer_state.dart';
import '../../bloc/inventory/inventory_bloc.dart';
import '../../bloc/inventory/inventory_event.dart';

class PendingTransfersPage extends StatefulWidget {
  const PendingTransfersPage({super.key});

  @override
  State<PendingTransfersPage> createState() => _PendingTransfersPageState();
}

class _PendingTransfersPageState extends State<PendingTransfersPage> {
  @override
  void initState() {
    super.initState();
    context.read<TransferBloc>().add(const TransferLoadPendingRequested());
  }

  void _completeTransfer(String transferId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Transferencia'),
        content: const Text(
          '¿Estás seguro de completar esta transferencia?\n\n'
          'Esto moverá el inventario de la ubicación origen a la destino.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<TransferBloc>()
                  .add(TransferCompleteRequested(transferId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Completar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transferencias Pendientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context
                  .read<TransferBloc>()
                  .add(const TransferLoadPendingRequested());
            },
          ),
        ],
      ),
      body: BlocConsumer<TransferBloc, TransferState>(
        listener: (context, state) {
          if (state is TransferCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Transferencia completada exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            // Recargar inventario
            context.read<InventoryBloc>().add(const InventoryLoadRequested());
            // Recargar lista de pendientes
            context
                .read<TransferBloc>()
                .add(const TransferLoadPendingRequested());
          } else if (state is TransferError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error: ${state.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TransferLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TransferLoaded) {
            if (state.transfers.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No hay transferencias pendientes',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<TransferBloc>()
                    .add(const TransferLoadPendingRequested());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.transfers.length,
                itemBuilder: (context, index) {
                  final transfer = state.transfers[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.pending, color: Colors.white),
                      ),
                      title: Text(
                        '${transfer.fromLocationName} → ${transfer.toLocationName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Empleado: ${transfer.employeeName}'),
                          Text(
                            'Creado: ${_formatDate(transfer.createdAt)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (transfer.notes != null)
                            Text(
                              'Nota: ${transfer.notes}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                      children: [
                        if (transfer.details.isNotEmpty) ...[
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Productos:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...transfer.details.map((detail) {
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.inventory_2, size: 20),
                              title: Text(detail.productName),
                              trailing: Text(
                                '${detail.quantity} unidades',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }),
                        ],
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  // TODO: Implementar cancelar transferencia
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Función cancelar en desarrollo'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.cancel),
                                label: const Text('Cancelar'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _completeTransfer(transfer.id),
                                icon: const Icon(Icons.check),
                                label: const Text('Completar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }

          return const Center(child: Text('Cargando...'));
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
