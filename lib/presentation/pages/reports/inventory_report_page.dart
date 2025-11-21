import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../domain/repositories/inventory_repository.dart';
import '../../../domain/repositories/location_repository.dart';
import '../../../domain/entities/inventory.dart';

class InventoryReportPage extends StatefulWidget {
  const InventoryReportPage({super.key});

  @override
  State<InventoryReportPage> createState() => _InventoryReportPageState();
}

class _InventoryReportPageState extends State<InventoryReportPage> {
  final numberFormat = NumberFormat.currency(symbol: 'Bs. ');

  String? _selectedLocationId;
  List<InventoryItem> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _loading = true);

    try {
      final repository = RepositoryProvider.of<InventoryRepository>(context);
      List<InventoryItem> items;

      if (_selectedLocationId != null) {
        items = await repository.getByLocation(_selectedLocationId!);
      } else {
        items = await repository.getAll();
      }

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  int get _totalItems {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get _totalValue {
    return _items.fold(
        0, (sum, item) => sum + (item.quantity * item.salePrice));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario Global'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: FutureBuilder(
              future:
                  RepositoryProvider.of<LocationRepository>(context).getAll(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final locations = snapshot.data as List;
                return DropdownButtonFormField<String>(
                  value: _selectedLocationId,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por ubicación',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todas las ubicaciones'),
                    ),
                    ...locations.map((loc) {
                      return DropdownMenuItem(
                        value: loc.id,
                        child: Text(loc.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedLocationId = value);
                    _loadInventory();
                  },
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Total Unidades'),
                        Text(
                          _totalItems.toString(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Valor Total'),
                        Text(
                          numberFormat.format(_totalValue),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_items.length} productos en inventario',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('No hay inventario'))
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
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
                              leading: CircleAvatar(
                                backgroundColor: stockColor.withOpacity(0.2),
                                child: Icon(
                                  Icons.inventory_2,
                                  color: stockColor,
                                ),
                              ),
                              title: Text(item.productName),
                              subtitle: Text(
                                '${item.locationName}\n${numberFormat.format(item.salePrice)} c/u',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: stockColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${item.quantity}',
                                      style: TextStyle(
                                        color: stockColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    numberFormat
                                        .format(item.quantity * item.salePrice),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
