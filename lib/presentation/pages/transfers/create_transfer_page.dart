import 'package:electronics_inventory/domain/repositories/location_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/transfer.dart';
import '../../../domain/entities/inventory.dart';
import '../../../domain/entities/location.dart';
import '../../bloc/transfer/transfer_bloc.dart';
import '../../bloc/transfer/transfer_event.dart';
import '../../bloc/transfer/transfer_state.dart';
import '../../bloc/inventory/inventory_bloc.dart';
import '../../bloc/inventory/inventory_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';

class CreateTransferPage extends StatefulWidget {
  final Location fromLocation;

  const CreateTransferPage({super.key, required this.fromLocation});

  @override
  State<CreateTransferPage> createState() => _CreateTransferPageState();
}

class _CreateTransferPageState extends State<CreateTransferPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  Location? _toLocation;
  final List<TransferItem> _items = [];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        fromLocationId: widget.fromLocation.id,
        onAdd: (inventoryItem, quantity) {
          setState(() {
            _items.add(TransferItem(
              inventoryItem: inventoryItem,
              quantity: quantity,
            ));
          });
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _saveTransfer() {
    if (!_formKey.currentState!.validate()) return;
    if (_toLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione ubicación destino')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agregue al menos un producto')),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final uuid = const Uuid();
    final transferId = uuid.v4();

    final transfer = Transfer(
      id: transferId,
      fromLocationId: widget.fromLocation.id,
      fromLocationName: widget.fromLocation.name,
      toLocationId: _toLocation!.id,
      toLocationName: _toLocation!.name,
      employeeId: authState.employee.id,
      employeeName: authState.employee.name,
      status: 'pending',
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final details = _items.map((item) {
      return TransferDetail(
        id: uuid.v4(),
        productId: item.inventoryItem.productId,
        productName: item.inventoryItem.productName,
        quantity: item.quantity,
      );
    }).toList();

    context.read<TransferBloc>().add(
          TransferCreateRequested(transfer: transfer, details: details),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Transferencia'),
      ),
      body: BlocListener<TransferBloc, TransferState>(
        listener: (context, state) {
          if (state is TransferCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Transferencia creada exitosamente')),
            );
            Navigator.pop(context, true);
          } else if (state is TransferError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Desde: ${widget.fromLocation.name}'),
                      const SizedBox(height: 16),
                      FutureBuilder(
                        future:
                            RepositoryProvider.of<LocationRepository>(context)
                                .getAll(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }

                          final locations = snapshot.data!
                              .where((l) => l.id != widget.fromLocation.id)
                              .toList();

                          return DropdownButtonFormField<Location>(
                            value: _toLocation,
                            decoration: const InputDecoration(
                              labelText: 'Hacia (Destino)',
                              border: OutlineInputBorder(),
                            ),
                            items: locations.map((loc) {
                              return DropdownMenuItem(
                                value: loc,
                                child: Text(loc.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _toLocation = value);
                            },
                            validator: (value) =>
                                value == null ? 'Seleccione destino' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notas (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Productos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_items.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No hay productos agregados'),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Card(
                              child: ListTile(
                                title: Text(item.inventoryItem.productName),
                                subtitle: Text(
                                  'Cantidad: ${item.quantity}\nStock disponible: ${item.inventoryItem.quantity}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _removeItem(index),
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveTransfer,
                    child: const Text('Crear Transferencia'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TransferItem {
  final InventoryItem inventoryItem;
  final int quantity;

  TransferItem({
    required this.inventoryItem,
    required this.quantity,
  });
}

class _AddItemDialog extends StatefulWidget {
  final String fromLocationId;
  final Function(InventoryItem, int) onAdd;

  const _AddItemDialog({
    required this.fromLocationId,
    required this.onAdd,
  });

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  InventoryItem? _selectedItem;
  final _quantityController = TextEditingController(text: '1');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Producto'),
      content: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) {
          if (state is! InventoryLoaded) {
            return const CircularProgressIndicator();
          }

          final availableItems = state.items
              .where((item) =>
                  item.locationId == widget.fromLocationId && item.quantity > 0)
              .toList();

          if (availableItems.isEmpty) {
            return const Text('No hay productos con stock en esta ubicación');
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<InventoryItem>(
                isExpanded: true,
                value: _selectedItem,
                decoration: const InputDecoration(
                  labelText: 'Producto',
                  border: OutlineInputBorder(),
                ),
                items: availableItems.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text('${item.productName} (${item.quantity})'),
                  );
                }).toList(),
                onChanged: (item) {
                  setState(() => _selectedItem = item);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  border: const OutlineInputBorder(),
                  helperText: _selectedItem != null
                      ? 'Stock disponible: ${_selectedItem!.quantity}'
                      : null,
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedItem != null && _quantityController.text.isNotEmpty) {
              final quantity = int.parse(_quantityController.text);
              if (quantity > _selectedItem!.quantity) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cantidad excede el stock disponible'),
                  ),
                );
                return;
              }
              widget.onAdd(_selectedItem!, quantity);
              Navigator.pop(context);
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
