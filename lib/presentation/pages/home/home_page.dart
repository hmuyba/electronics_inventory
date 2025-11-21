import 'package:electronics_inventory/domain/repositories/sync_repository.dart';
import 'package:electronics_inventory/presentation/bloc/connectivity/connectivity_bloc.dart';
import 'package:electronics_inventory/presentation/bloc/connectivity/connectivity_state.dart';
import 'package:electronics_inventory/presentation/bloc/inventory/inventory_bloc.dart';
import 'package:electronics_inventory/presentation/bloc/inventory/inventory_event.dart';
import 'package:electronics_inventory/presentation/pages/purchases/purchases_page.dart';
import 'package:electronics_inventory/presentation/pages/reports/reports_page.dart';
import 'package:electronics_inventory/presentation/pages/sales/sales_page.dart';
import 'package:electronics_inventory/presentation/pages/transfers/transfers_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../auth/login_page.dart';
import '../products/products_page.dart';
import '../inventory/inventory_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inicio'),
          actions: [
            // Botón de sincronización
            BlocBuilder<ConnectivityBloc, ConnectivityState>(
              builder: (context, state) {
                if (state is ConnectivityOnline) {
                  return IconButton(
                    icon: const Icon(Icons.sync),
                    tooltip: 'Sincronizar',
                    onPressed: () async {
                      final syncRepo =
                          RepositoryProvider.of<SyncRepository>(context);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🔄 Sincronizando...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }

                      try {
                        await syncRepo.syncPendingOperations();

                        if (context.mounted) {
                          context
                              .read<InventoryBloc>()
                              .add(const InventoryLoadRequested());

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  '✅ Sincronización completada. Inventario actualizado.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        state.employee.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildMenuCard(
                context,
                icon: Icons.inventory_2,
                title: 'Productos',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductsPage(),
                    ),
                  );
                },
              ),
              _buildMenuCard(
                context,
                icon: Icons.warehouse,
                title: 'Inventario',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InventoryPage(),
                    ),
                  );
                },
              ),
              _buildMenuCard(
                context,
                icon: Icons.shopping_cart,
                title: 'Ventas',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SalesPage(),
                    ),
                  );
                },
              ),
              _buildMenuCard(
                context,
                icon: Icons.add_shopping_cart,
                title: 'Compras',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PurchasesPage(),
                    ),
                  );
                },
              ),
              _buildMenuCard(
                context,
                icon: Icons.swap_horiz,
                title: 'Transferencias',
                color: Colors.indigo,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TransfersPage(),
                    ),
                  );
                },
              ),
              _buildMenuCard(
                context,
                icon: Icons.analytics,
                title: 'Reportes',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReportsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
