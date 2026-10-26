/// Only fixed, user-safe messages belong here; never include response bodies.
class TdxException implements Exception {
  final String message;
  final int? statusCode;

  const TdxException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
