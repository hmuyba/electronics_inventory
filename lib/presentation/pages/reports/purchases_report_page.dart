import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../domain/repositories/purchase_repository.dart';
import '../../../domain/repositories/location_repository.dart';
import '../../../domain/entities/purchase.dart';

class PurchasesReportPage extends StatefulWidget {
  const PurchasesReportPage({super.key});

  @override
  State<PurchasesReportPage> createState() => _PurchasesReportPageState();
}

class _PurchasesReportPageState extends State<PurchasesReportPage> {
  final numberFormat = NumberFormat.currency(symbol: 'Bs. ');
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedLocationId;
  List<Purchase> _purchases = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() => _loading = true);

    try {
      final repository = RepositoryProvider.of<PurchaseRepository>(context);
      List<Purchase> purchases;

      if (_startDate != null && _endDate != null) {
        purchases = await repository.getByDateRange(_startDate!, _endDate!);
      } else if (_selectedLocationId != null) {
        purchases = await repository.getByLocation(_selectedLocationId!);
      } else {
        purchases = await repository.getAll();
      }

      if (_selectedLocationId != null) {
        purchases = purchases
            .where((p) => p.locationId == _selectedLocationId)
            .toList();
      }

      setState(() {
        _purchases = purchases;
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

  double get _totalPurchases {
    return _purchases.fold(0, (sum, purchase) => sum + purchase.total);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadPurchases();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Compras'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                FutureBuilder(
                  future: RepositoryProvider.of<LocationRepository>(context)
                      .getAll(),
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
                        _loadPurchases();
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _startDate != null && _endDate != null
                              ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                              : 'Seleccionar fechas',
                        ),
                      ),
                    ),
                    if (_startDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                          _loadPurchases();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              children: [
                const Text(
                  'Total Compras',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  numberFormat.format(_totalPurchases),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  '${_purchases.length} ${_purchases.length == 1 ? 'compra' : 'compras'}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _purchases.isEmpty
                    ? const Center(child: Text('No hay compras'))
                    : ListView.builder(
                        itemCount: _purchases.length,
                        itemBuilder: (context, index) {
                          final purchase = _purchases[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: const Icon(
                                  Icons.add_shopping_cart,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(purchase.locationName),
                              subtitle: Text(
                                '${dateFormat.format(purchase.createdAt)}\nProveedor: ${purchase.supplier}',
                              ),
                              trailing: Text(
                                numberFormat.format(purchase.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
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
