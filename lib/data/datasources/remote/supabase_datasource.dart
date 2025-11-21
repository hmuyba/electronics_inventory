import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/errors/failures.dart';
import '../../models/employee_model.dart';
import '../../models/location_model.dart';
import '../../models/product_model.dart';
import '../../models/inventory_model.dart';
import '../../models/purchase_model.dart';
import '../../models/sale_model.dart';
import '../../models/transfer_model.dart';

class SupabaseDataSource {
  final SupabaseClient client;

  SupabaseDataSource({SupabaseClient? client})
      : client = client ?? Supabase.instance.client;

  // ============================================
  // AUTH
  // ============================================

  Future<EmployeeModel> login(String email, String password) async {
    try {
      final authResponse = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw const AuthenticationFailure('Usuario no encontrado');
      }

      final employeeData = await client
          .from(SupabaseConfig.employeesTable)
          .select()
          .eq('user_id', authResponse.user!.id)
          .single();

      return EmployeeModel.fromJson(employeeData);
    } on AuthException catch (e) {
      throw AuthenticationFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<EmployeeModel?> getCurrentEmployee() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return null;

      final employeeData = await client
          .from(SupabaseConfig.employeesTable)
          .select()
          .eq('user_id', user.id)
          .single();

      return EmployeeModel.fromJson(employeeData);
    } catch (e) {
      return null;
    }
  }

  Stream<EmployeeModel?> authStateChanges() {
    return client.auth.onAuthStateChange.asyncMap((state) async {
      if (state.session?.user == null) return null;
      return await getCurrentEmployee();
    });
  }

  // ============================================
  // EMPLOYEES
  // ============================================

  Future<List<EmployeeModel>> getAllEmployees() async {
    try {
      final data = await client
          .from(SupabaseConfig.employeesTable)
          .select()
          .order('name');

      return (data as List).map((e) => EmployeeModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<EmployeeModel> getEmployeeById(String id) async {
    try {
      final data = await client
          .from(SupabaseConfig.employeesTable)
          .select()
          .eq('id', id)
          .single();

      return EmployeeModel.fromJson(data);
    } catch (e) {
      throw NotFoundFailure('Empleado no encontrado');
    }
  }

  // ============================================
  // LOCATIONS
  // ============================================

  Future<List<LocationModel>> getAllLocations() async {
    try {
      final data = await client
          .from(SupabaseConfig.locationsTable)
          .select()
          .order('name');

      return (data as List).map((e) => LocationModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<LocationModel>> getLocationsByType(String type) async {
    try {
      final data = await client
          .from(SupabaseConfig.locationsTable)
          .select()
          .eq('type', type)
          .order('name');

      return (data as List).map((e) => LocationModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ============================================
  // PRODUCTS
  // ============================================

  Future<List<ProductModel>> getAllProducts() async {
    try {
      final data = await client
          .from(SupabaseConfig.productsTable)
          .select()
          .eq('is_active', true)
          .order('name');

      return (data as List).map((e) => ProductModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<ProductModel> createProduct(ProductModel product) async {
    try {
      final data = await client
          .from(SupabaseConfig.productsTable)
          .insert(product.toJson())
          .select()
          .single();

      return ProductModel.fromJson(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ============================================
  // INVENTORY
  // ============================================

  Future<List<InventoryItemModel>> getInventory({String? locationId}) async {
    try {
      var query = client.from(SupabaseConfig.inventoryTable).select('''
            id,
            product_id,
            location_id,
            quantity,
            updated_at,
            products!inner(id, name, category, sale_price),
            locations!inner(id, name, type)
          ''');

      if (locationId != null) {
        query = query.eq('location_id', locationId);
      }

      final data = await query;

      return (data as List).map((item) {
        return InventoryItemModel.fromJson({
          'id': item['id'],
          'product_id': item['product_id'],
          'product_name': item['products']['name'],
          'product_category': item['products']['category'],
          'location_id': item['location_id'],
          'location_name': item['locations']['name'],
          'location_type': item['locations']['type'],
          'quantity': item['quantity'],
          'sale_price': item['products']['sale_price'],
          'updated_at': item['updated_at'],
        });
      }).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ============================================
  // PURCHASES
  // ============================================

  Future<PurchaseModel> createPurchase(
    PurchaseModel purchase,
    List<PurchaseDetailModel> details,
  ) async {
    try {
      // Insertar compra
      final purchaseData = await client
          .from(SupabaseConfig.purchasesTable)
          .insert(purchase.toJson())
          .select()
          .single();

      // Insertar detalles
      final detailsData = details.map((d) {
        return {
          'id': d.id,
          'purchase_id': purchase.id,
          'product_id': d.productId,
          'quantity': d.quantity,
          'unit_price': d.unitPrice,
          'subtotal': d.subtotal,
        };
      }).toList();

      await client
          .from(SupabaseConfig.purchaseDetailsTable)
          .insert(detailsData);

      return PurchaseModel.fromJson(purchaseData);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<PurchaseModel>> getPurchases({
    String? locationId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = client.from(SupabaseConfig.purchasesTable).select('''
        *,
        locations!inner(name),
        employees!inner(name)
      ''');

      if (locationId != null) {
        query = query.eq('location_id', locationId);
      }

      if (startDate != null && endDate != null) {
        query = query
            .gte('created_at', startDate.toIso8601String())
            .lte('created_at', endDate.toIso8601String());
      }

      final data = await query.order('created_at', ascending: false);

      return (data as List).map((item) {
        return PurchaseModel.fromJson({
          ...item,
          'location_name': item['locations']['name'],
          'employee_name': item['employees']['name'],
        });
      }).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ============================================
  // SALES
  // ============================================

  Future<SaleModel> createSale(
    SaleModel sale,
    List<SaleDetailModel> details,
  ) async {
    try {
      // Insertar venta
      final saleData = await client
          .from(SupabaseConfig.salesTable)
          .insert(sale.toJson())
          .select()
          .single();

      // Insertar detalles
      final detailsData = details.map((d) {
        return {
          'id': d.id,
          'sale_id': sale.id,
          'product_id': d.productId,
          'quantity': d.quantity,
          'unit_price': d.unitPrice,
          'subtotal': d.subtotal,
        };
      }).toList();

      await client.from(SupabaseConfig.saleDetailsTable).insert(detailsData);

      return SaleModel.fromJson(saleData);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<SaleModel>> getSales({
    String? locationId,
    DateTime? startDate,
    DateTime? endDate,
    bool todayOnly = false,
  }) async {
    try {
      var query = client.from(SupabaseConfig.salesTable).select('''
    *,
    locations!inner(name),
    employees!inner(name)
  ''');

      if (locationId != null) {
        query = query.eq('location_id', locationId);
      }

      if (todayOnly) {
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        query = query
            .gte('created_at', startOfDay.toIso8601String())
            .lt('created_at', endOfDay.toIso8601String());
      } else if (startDate != null && endDate != null) {
        query = query
            .gte('created_at', startDate.toIso8601String())
            .lte('created_at', endDate.toIso8601String());
      }

      final data = await query.order('created_at', ascending: false);

      return (data as List).map((item) {
        return SaleModel.fromJson({
          ...item,
          'location_name': item['locations']['name'],
          'employee_name': item['employees']['name'],
        });
      }).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ============================================
  // TRANSFERS
  // ============================================

  Future<TransferModel> createTransfer(
    TransferModel transfer,
    List<TransferDetailModel> details,
  ) async {
    try {
      // Insertar transferencia
      final transferData = await client
          .from(SupabaseConfig.transfersTable)
          .insert(transfer.toJson())
          .select()
          .single();

      // Insertar detalles
      final detailsData = details.map((d) {
        return {
          'id': d.id,
          'transfer_id': transfer.id,
          'product_id': d.productId,
          'quantity': d.quantity,
        };
      }).toList();

      await client
          .from(SupabaseConfig.transferDetailsTable)
          .insert(detailsData);

      return TransferModel.fromJson(transferData);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<TransferModel> updateTransferStatus(String id, String status) async {
    try {
      final data = await client
          .from(SupabaseConfig.transfersTable)
          .update({'status': status})
          .eq('id', id)
          .select()
          .single();

      return TransferModel.fromJson(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<TransferModel>> getTransfers({
    String? fromLocationId,
    String? toLocationId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = client.from(SupabaseConfig.transfersTable).select('''
    *,
    from_location:locations!from_location_id(name),
    to_location:locations!to_location_id(name),
    employees!inner(name)
  ''');

      if (fromLocationId != null) {
        query = query.eq('from_location_id', fromLocationId);
      }

      if (toLocationId != null) {
        query = query.eq('to_location_id', toLocationId);
      }

      if (startDate != null && endDate != null) {
        query = query
            .gte('created_at', startDate.toIso8601String())
            .lte('created_at', endDate.toIso8601String());
      }

      final data = await query.order('created_at', ascending: false);

      return (data as List).map((item) {
        return TransferModel.fromJson({
          ...item,
          'from_location_name': item['from_location']['name'],
          'to_location_name': item['to_location']['name'],
          'employee_name': item['employees']['name'],
        });
      }).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
