import 'package:equatable/equatable.dart';
import '../../entities/employee.dart';
import '../../repositories/auth_repository.dart';
import '../usecase.dart';

class LoginUseCase implements UseCase<Employee, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Employee> call(LoginParams params) async {
    return await repository.login(params.email, params.password);
  }
}

class LoginParams extends Equatable {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}