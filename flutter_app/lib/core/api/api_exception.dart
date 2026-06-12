class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() {
    if (errors != null && errors is List) {
      final buffer = StringBuffer(message);
      buffer.write('\nDetails:');
      for (var err in errors) {
        if (err is Map && err.containsKey('message')) {
          buffer.write('\n- ${err['message']}');
        }
      }
      return buffer.toString();
    }
    return message;
  }
}
