import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'core/config/supabase_config.dart';
import 'data/datasources/local/database.dart';
import 'data/datasources/remote/supabase_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/product_repository_impl.dart';
import 'data/repositories/inventory_repository_impl.dart';
import 'data/repositories/location_repository_impl.dart';
import 'data/repositories/purchase_repository_impl.dart';
import 'data/repositories/sale_repository_impl.dart';
import 'data/repositories/sync_repository_impl.dart';
import 'data/repositories/transfer_repository_impl.dart';
import 'domain/repositories/location_repository.dart';
import 'domain/repositories/sale_repository.dart';
import 'domain/repositories/purchase_repository.dart';
import 'domain/repositories/inventory_repository.dart';
import 'domain/repositories/sync_repository.dart';
import 'domain/repositories/transfer_repository.dart';
import 'domain/usecases/auth/login_usecase.dart';
import 'domain/usecases/auth/logout_usecase.dart';
import 'domain/usecases/auth/get_current_employee_usecase.dart';
import 'domain/usecases/product/get_products_usecase.dart';
import 'domain/usecases/product/create_product_usecase.dart';
import 'domain/usecases/inventory/get_inventory_usecase.dart';
import 'domain/usecases/purchase/create_purchase_usecase.dart';
import 'domain/usecases/sale/create_sale_usecase.dart';
import 'domain/usecases/sale/get_sales_usecase.dart';
import 'domain/usecases/sync/sync_pending_operations_usecase.dart';
import 'domain/usecases/transfer/create_transfer_usecase.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/bloc/auth/auth_state.dart';
import 'presentation/bloc/product/product_bloc.dart';
import 'presentation/bloc/product/product_event.dart';
import 'presentation/bloc/inventory/inventory_bloc.dart';
import 'presentation/bloc/inventory/inventory_event.dart';
import 'presentation/bloc/purchase/purchase_bloc.dart';
import 'presentation/bloc/sale/sale_bloc.dart';
import 'presentation/bloc/connectivity/connectivity_bloc.dart';
import 'presentation/bloc/connectivity/connectivity_event.dart';
import 'presentation/bloc/transfer/transfer_bloc.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/home/home_page.dart';
import 'presentation/widgets/connectivity_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  final database = AppDatabase();
  final supabaseDataSource = SupabaseDataSource();

  // Repositories
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: supabaseDataSource,
    localDatabase: database,
  );

  final productRepository = ProductRepositoryImpl(
    remoteDataSource: supabaseDataSource,
    localDatabase: database,
  );

  final inventoryRepository = InventoryRepositoryImpl(
    remoteDataSource: supabaseDataSource,
    localDatabase: database,
  );

  final locationRepository = LocationRepositoryImpl(
    remoteDataSource: supabaseDataSource,
    localDatabase: database,
  );

  final purchaseRepository = PurchaseRepositoryImpl(
    remoteDataSource: supabaseDataSource,
    localDatabase: database,
  );

  final saleRepository = SaleRepositoryImpl(
    remoteDataSource: supabaseDataSource,
    localDatabase: database,
  );

  final syncRepository = SyncRepositoryImpl(
    localDatabase: database,
    remoteDataSource: supabaseDataSource,
  );

  final transferRepository = TransferRepositoryImpl(
    remoteDataSource: supabaseDataSource,
    localDatabase: database,
  );

  // Use Cases
  final loginUseCase = LoginUseCase(authRepository);
  final logoutUseCase = LogoutUseCase(authRepository);
  final getCurrentEmployeeUseCase = GetCurrentEmployeeUseCase(authRepository);
  final getProductsUseCase = GetProductsUseCase(productRepository);
  final createProductUseCase = CreateProductUseCase(productRepository);
  final getInventoryUseCase = GetInventoryUseCase(inventoryRepository);
  final createPurchaseUseCase = CreatePurchaseUseCase(purchaseRepository);
  final createSaleUseCase = CreateSaleUseCase(saleRepository);
  final getSalesUseCase = GetSalesUseCase(saleRepository);
  final syncPendingOperationsUseCase =
      SyncPendingOperationsUseCase(syncRepository);
  final createTransferUseCase = CreateTransferUseCase(transferRepository);

  runApp(MyApp(
    authBloc: AuthBloc(
      loginUseCase: loginUseCase,
      logoutUseCase: logoutUseCase,
      getCurrentEmployeeUseCase: getCurrentEmployeeUseCase,
    ),
    productBloc: ProductBloc(
      getProductsUseCase: getProductsUseCase,
      createProductUseCase: createProductUseCase,
    ),
    inventoryBloc: InventoryBloc(
      getInventoryUseCase: getInventoryUseCase,
    ),
    purchaseBloc: PurchaseBloc(
      createPurchaseUseCase: createPurchaseUseCase,
    ),
    saleBloc: SaleBloc(
      createSaleUseCase: createSaleUseCase,
      getSalesUseCase: getSalesUseCase,
    ),
    connectivityBloc: ConnectivityBloc(),
    transferBloc: TransferBloc(
      createTransferUseCase: createTransferUseCase,
      transferRepository: transferRepository,
    ),
    locationRepository: locationRepository,
    saleRepository: saleRepository,
    purchaseRepository: purchaseRepository,
    inventoryRepository: inventoryRepository,
    syncRepository: syncRepository,
    transferRepository: transferRepository,
  ));
}

class MyApp extends StatelessWidget {
  final AuthBloc authBloc;
  final ProductBloc productBloc;
  final InventoryBloc inventoryBloc;
  final PurchaseBloc purchaseBloc;
  final SaleBloc saleBloc;
  final ConnectivityBloc connectivityBloc;
  final TransferBloc transferBloc;
  final LocationRepository locationRepository;
  final SaleRepository saleRepository;
  final PurchaseRepository purchaseRepository;
  final InventoryRepository inventoryRepository;
  final SyncRepository syncRepository;
  final TransferRepository transferRepository;

  const MyApp({
    super.key,
    required this.authBloc,
    required this.productBloc,
    required this.inventoryBloc,
    required this.purchaseBloc,
    required this.saleBloc,
    required this.connectivityBloc,
    required this.transferBloc,
    required this.locationRepository,
    required this.saleRepository,
    required this.purchaseRepository,
    required this.inventoryRepository,
    required this.syncRepository,
    required this.transferRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LocationRepository>.value(value: locationRepository),
        RepositoryProvider<SaleRepository>.value(value: saleRepository),
        RepositoryProvider<PurchaseRepository>.value(value: purchaseRepository),
        RepositoryProvider<InventoryRepository>.value(
            value: inventoryRepository),
        RepositoryProvider<SyncRepository>.value(value: syncRepository),
        RepositoryProvider<TransferRepository>.value(value: transferRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc..add(AuthCheckRequested())),
          BlocProvider.value(value: productBloc..add(ProductLoadRequested())),
          BlocProvider.value(
              value: inventoryBloc..add(const InventoryLoadRequested())),
          BlocProvider.value(value: purchaseBloc),
          BlocProvider.value(value: saleBloc),
          BlocProvider.value(
              value: connectivityBloc..add(ConnectivityCheckRequested())),
          BlocProvider.value(value: transferBloc),
        ],
        child: MaterialApp(
          title: 'Electronics Inventory',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading || state is AuthInitial) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is AuthAuthenticated) {
                return ConnectivityBanner(
                  child: const HomePage(),
                );
              }
              return const LoginPage();
            },
          ),
        ),
      ),
    );
  }
}
