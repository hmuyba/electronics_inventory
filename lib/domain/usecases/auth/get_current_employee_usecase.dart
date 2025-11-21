import '../../entities/employee.dart';
import '../../repositories/auth_repository.dart';
import '../usecase.dart';

class GetCurrentEmployeeUseCase implements UseCase<Employee?, NoParams> {
  final AuthRepository repository;

  GetCurrentEmployeeUseCase(this.repository);

  @override
  Future<Employee?> call(NoParams params) async {
    return await repository.getCurrentEmployee();
  }
}
