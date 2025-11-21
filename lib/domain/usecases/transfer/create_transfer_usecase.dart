import 'package:equatable/equatable.dart';
import '../../entities/transfer.dart';
import '../../repositories/transfer_repository.dart';
import '../usecase.dart';

class CreateTransferUseCase implements UseCase<Transfer, CreateTransferParams> {
  final TransferRepository repository;

  CreateTransferUseCase(this.repository);

  @override
  Future<Transfer> call(CreateTransferParams params) async {
    return await repository.create(params.transfer, params.details);
  }
}

class CreateTransferParams extends Equatable {
  final Transfer transfer;
  final List<TransferDetail> details;

  const CreateTransferParams({
    required this.transfer,
    required this.details,
  });

  @override
  List<Object?> get props => [transfer, details];
}
