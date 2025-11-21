import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/entities/inventory.dart';
import '../../bloc/sale/sale_bloc.dart';
import '../../bloc/sale/sale_event.dart';
import '../../bloc/sale/sale_state.dart';
import '../../bloc/inventory/inventory_bloc.dart';
import '../../bloc/inventory/inventory_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';

class CreateSalePage extends StatefulWidget {
  final String locationId;
  final String locationName;

  const CreateSalePage({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  @override
  State<CreateSalePage> createState() => _CreateSalePageState();
}

class _CreateSalePageState extends State<CreateSalePage> {
  final numberFormat = NumberFormat.currency(symbol: 'Bs. ');
  final List<SaleItem> _items = [];

  double get _total {
    return _items.fold(0, (sum, item) => sum + item.subtotal);
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        locationId: widget.locationId,
        onAdd: (inventoryItem, quantity) {
          setState(() {
            _items.add(SaleItem(
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

  void _saveSale() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agregue al menos un producto')),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final uuid = const Uuid();
    final saleId = uuid.v4();

    final sale = Sale(
      id: saleId,
      locationId: widget.locationId,
      locationName: widget.locationName,
      employeeId: authState.employee.id,
      employeeName: authState.employee.name,
      total: _total,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final details = _items.map((item) {
      return SaleDetail(
        id: uuid.v4(),
        productId: item.inventoryItem.productId,
        productName: item.inventoryItem.productName,
        quantity: item.quantity,
        unitPrice: item.inventoryItem.salePrice,
        subtotal: item.subtotal,
      );
    }).toList();

    context.read<SaleBloc>().add(
          SaleCreateRequested(sale: sale, details: details),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta'),
      ),
      body: BlocListener<SaleBloc, SaleState>(
        listener: (context, state) {
          if (state is SaleCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Venta registrada exitosamente')),
            );
            Navigator.pop(context, true);
          } else if (state is SaleError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ubicación: ${widget.locationName}'),
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
                                'Cantidad: ${item.quantity} x ${numberFormat.format(item.inventoryItem.salePrice)}\nStock disponible: ${item.inventoryItem.quantity}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    numberFormat.format(item.subtotal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _removeItem(index),
                                  ),
                                ],
                              ),
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        numberFormat.format(_total),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveSale,
                      child: const Text('Guardar Venta'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SaleItem {
  final InventoryItem inventoryItem;
  final int quantity;

  SaleItem({
    required this.inventoryItem,
    required this.quantity,
  });

  double get subtotal => quantity * inventoryItem.salePrice;
}

class _AddItemDialog extends StatefulWidget {
  final String locationId;
  final Function(InventoryItem, int) onAdd;

  const _AddItemDialog({
    required this.locationId,
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
                  item.locationId == widget.locationId && item.quantity > 0)
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
                    child:
                        Text('${item.productName} (Stock: ${item.quantity})'),
                  );
                }).toList(),
                onChanged: (item) {
                  setState(() {
                    _selectedItem = item;
                  });
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
                      content: Text('Cantidad excede el stock disponible')),
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
