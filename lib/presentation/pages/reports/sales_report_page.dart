import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../domain/repositories/sale_repository.dart';
import '../../../domain/repositories/location_repository.dart';
import '../../../domain/entities/sale.dart';

class SalesReportPage extends StatefulWidget {
  final bool todayOnly;

  const SalesReportPage({super.key, this.todayOnly = false});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  final numberFormat = NumberFormat.currency(symbol: 'Bs. ');
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedLocationId;
  List<Sale> _sales = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.todayOnly) {
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = _startDate!.add(const Duration(days: 1));
    }
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _loading = true);

    try {
      final repository =
          RepositoryProvider.of<SaleRepository>(context); // CAMBIO AQUÍ
      List<Sale> sales;

      if (widget.todayOnly) {
        sales = await repository.getTodaySales();
      } else if (_startDate != null && _endDate != null) {
        sales = await repository.getByDateRange(_startDate!, _endDate!);
      } else if (_selectedLocationId != null) {
        sales = await repository.getByLocation(_selectedLocationId!);
      } else {
        sales = await repository.getAll();
      }

      // Filtrar por ubicación si está seleccionada
      if (_selectedLocationId != null && !widget.todayOnly) {
        sales =
            sales.where((s) => s.locationId == _selectedLocationId).toList();
      }

      setState(() {
        _sales = sales;
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

  double get _totalSales {
    return _sales.fold(0, (sum, sale) => sum + sale.total);
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
      _loadSales();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.todayOnly ? 'Ventas del Día' : 'Reporte de Ventas'),
      ),
      body: Column(
        children: [
          if (!widget.todayOnly)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                children: [
                  // Selector de ubicación
                  FutureBuilder(
                    future: RepositoryProvider.of<LocationRepository>(context)
                        .getAll(), // CAMBIO AQUÍ
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
                          _loadSales();
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Selector de fechas
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
                            _loadSales();
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          // Total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green[50],
            child: Column(
              children: [
                const Text(
                  'Total Ventas',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  numberFormat.format(_totalSales),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '${_sales.length} ${_sales.length == 1 ? 'venta' : 'ventas'}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Lista de ventas
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _sales.isEmpty
                    ? const Center(child: Text('No hay ventas'))
                    : ListView.builder(
                        itemCount: _sales.length,
                        itemBuilder: (context, index) {
                          final sale = _sales[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green,
                                child: const Icon(
                                  Icons.shopping_cart,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(sale.locationName),
                              subtitle: Text(
                                '${dateFormat.format(sale.createdAt)}\n${sale.employeeName}',
                              ),
                              trailing: Text(
                                numberFormat.format(sale.total),
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
