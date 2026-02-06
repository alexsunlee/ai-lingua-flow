import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = '网络连接失败，请检查网络设置',
    super.code,
  });
}

class GeminiFailure extends Failure {
  final int? statusCode;

  const GeminiFailure({
    required super.message,
    super.code,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, code, statusCode];
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code});
}

class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = '权限被拒绝',
    super.code,
  });
}
