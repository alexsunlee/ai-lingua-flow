class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException: $message (code: $statusCode)';
}

class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class GeminiException implements Exception {
  final String message;
  final int? statusCode;

  const GeminiException({required this.message, this.statusCode});

  bool get isRetryable =>
      statusCode == 429 || (statusCode != null && statusCode! >= 500);

  @override
  String toString() => 'GeminiException: $message (code: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'Network connection failed'});

  @override
  String toString() => 'NetworkException: $message';
}
