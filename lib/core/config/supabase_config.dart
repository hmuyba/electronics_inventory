class SupabaseConfig {
  // TODO: Reemplazar con tus credenciales de Supabase
  static const String url = 'https://xfjfaacgpakxnqaznzpj.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhmamZhYWNncGFreG5xYXpuenBqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1MDk3NzcsImV4cCI6MjA3OTA4NTc3N30.VutCvsBuyGMpyx9vJYITBxBDQ_fjLT46RCzDVZFlql8';

  // Nombres de tablas
  static const String employeesTable = 'employees';
  static const String locationsTable = 'locations';
  static const String employeeLocationsTable = 'employee_locations';
  static const String productsTable = 'products';
  static const String inventoryTable = 'inventory';
  static const String purchasesTable = 'purchases';
  static const String purchaseDetailsTable = 'purchase_details';
  static const String salesTable = 'sales';
  static const String saleDetailsTable = 'sale_details';
  static const String transfersTable = 'transfers';
  static const String transferDetailsTable = 'transfer_details';
}
