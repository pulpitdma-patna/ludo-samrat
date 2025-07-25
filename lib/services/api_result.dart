class ApiResult<T> {
  final T? data;
  final String? error;
  final String? code;
  const ApiResult._(this.data, this.error, this.code);

  factory ApiResult.success([T? data]) => ApiResult._(data, null, null);
  factory ApiResult.failure(String message, [String? code]) =>
      ApiResult._(null, message, code);

  bool get isSuccess => error == null;
}
