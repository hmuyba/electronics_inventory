class Roles {
  static const String admin = 'admin';
  static const String storeManager = 'store_manager';
  static const String warehouseManager = 'warehouse_manager';
  static const String seller = 'seller';

  static List<String> get all => [
        admin,
        storeManager,
        warehouseManager,
        seller,
      ];

  static String getDisplayName(String role) {
    switch (role) {
      case admin:
        return 'Administrador';
      case storeManager:
        return 'Encargado de Tienda';
      case warehouseManager:
        return 'Encargado de Almacén';
      case seller:
        return 'Vendedor';
      default:
        return role;
    }
  }
}

class LocationTypes {
  static const String store = 'store';
  static const String warehouse = 'warehouse';

  static String getDisplayName(String type) {
    switch (type) {
      case store:
        return 'Tienda';
      case warehouse:
        return 'Almacén';
      default:
        return type;
    }
  }
}

class TransferStatus {
  static const String pending = 'pending';
  static const String completed = 'completed';
  static const String failed = 'failed';
}

class SyncStatus {
  static const String pending = 'pending';
  static const String syncing = 'syncing';
  static const String synced = 'synced';
  static const String failed = 'failed';
}

class OperationType {
  static const String purchase = 'purchase';
  static const String sale = 'sale';
  static const String transfer = 'transfer';
}

class ProductCategories {
  static const String laptops = 'laptops';
  static const String smartphones = 'smartphones';
  static const String tablets = 'tablets';
  static const String accessories = 'accessories';
  static const String monitors = 'monitors';
  static const String components = 'components';

  static List<String> get all => [
        laptops,
        smartphones,
        tablets,
        accessories,
        monitors,
        components,
      ];

  static String getDisplayName(String category) {
    switch (category) {
      case laptops:
        return 'Laptops';
      case smartphones:
        return 'Smartphones';
      case tablets:
        return 'Tablets';
      case accessories:
        return 'Accesorios';
      case monitors:
        return 'Monitores';
      case components:
        return 'Componentes';
      default:
        return category;
    }
  }
}
