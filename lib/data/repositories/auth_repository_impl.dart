import '../../domain/entities/employee.dart' as entity;
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/supabase_datasource.dart';
import '../datasources/local/database.dart';
import '../models/employee_model.dart';
import 'package:drift/drift.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseDataSource remoteDataSource;
  final AppDatabase localDatabase;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDatabase,
  });

  @override
  Future<entity.Employee> login(String email, String password) async {
    // Intentar login en Supabase
    final employeeModel = await remoteDataSource.login(email, password);

    // Guardar en local
    await localDatabase.into(localDatabase.employees).insert(
          EmployeesCompanion.insert(
            id: employeeModel.id,
            userId: employeeModel.userId,
            name: employeeModel.name,
            email: employeeModel.email,
            role: employeeModel.role,
            isActive: Value(employeeModel.isActive),
            createdAt: Value(employeeModel.createdAt),
            updatedAt: Value(employeeModel.updatedAt),
            syncedAt: Value(employeeModel.syncedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );

    return employeeModel;
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
  }

  @override
  Future<entity.Employee?> getCurrentEmployee() async {
    // Intentar obtener de Supabase primero
    try {
      final employee = await remoteDataSource.getCurrentEmployee();
      if (employee != null) {
        return employee;
      }
    } catch (e) {
      // Si falla, intentar obtener de local
    }

    // Obtener de la base de datos local
    final localEmployee =
        await localDatabase.select(localDatabase.employees).getSingleOrNull();

    if (localEmployee == null) return null;

    return EmployeeModel(
      id: localEmployee.id,
      userId: localEmployee.userId,
      name: localEmployee.name,
      email: localEmployee.email,
      role: localEmployee.role,
      isActive: localEmployee.isActive,
      createdAt: localEmployee.createdAt,
      updatedAt: localEmployee.updatedAt,
      syncedAt: localEmployee.syncedAt,
    );
  }

  @override
  Stream<entity.Employee?> get authStateChanges {
    return remoteDataSource.authStateChanges();
  }
}
