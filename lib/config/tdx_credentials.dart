class TdxCredentials {
  final String clientId;
  final String clientSecret;

  const TdxCredentials({required this.clientId, required this.clientSecret});

  const TdxCredentials.fromEnvironment()
      : clientId = const String.fromEnvironment('TDX_CLIENT_ID'),
        clientSecret = const String.fromEnvironment('TDX_CLIENT_SECRET');

  bool get isConfigured =>
      clientId.trim().isNotEmpty && clientSecret.trim().isNotEmpty;
}
