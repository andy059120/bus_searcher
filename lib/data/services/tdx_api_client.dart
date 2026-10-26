import 'dart:async';

import 'package:bus_project/config/tdx_credentials.dart';
import 'package:bus_project/data/services/tdx_exception.dart';
import 'package:bus_project/data/services/tdx_token_service.dart';
import 'package:http/http.dart' as http;

final tdxApiClient = TdxApiClient.fromEnvironment();

class TdxApiClient {
  TdxApiClient({
    required http.Client client,
    required TdxTokenService tokenService,
    this.requestTimeout = const Duration(seconds: 15),
  })  : _client = client,
        _tokenService = tokenService;

  factory TdxApiClient.fromEnvironment() {
    final client = http.Client();
    return TdxApiClient(
      client: client,
      tokenService: TdxTokenService(
        client: client,
        credentials: const TdxCredentials.fromEnvironment(),
      ),
    );
  }

  final http.Client _client;
  final TdxTokenService _tokenService;
  final Duration requestTimeout;

  Future<http.Response> get(Uri uri) async {
    if (uri.scheme != 'https' ||
        uri.host != 'tdx.transportdata.tw' ||
        uri.port != 443 ||
        uri.userInfo.isNotEmpty ||
        !uri.path.startsWith('/api/')) {
      throw const TdxException('不允許的 TDX API 位址。');
    }

    final token = await _tokenService.getAccessToken();
    final response = await _send(uri, token);
    if (response.statusCode != 401) return response;

    _tokenService.invalidate(token);
    final renewedToken = await _tokenService.getAccessToken();
    // Retry once only. Permission and rate-limit errors do not trigger refresh.
    return _send(uri, renewedToken);
  }

  Future<http.Response> _send(Uri uri, String token) async {
    final request = http.Request('GET', uri)
      ..followRedirects = false
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json';
    try {
      return await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(requestTimeout);
    } on TimeoutException {
      throw const TdxException('TDX 資料查詢逾時，請稍後重試。');
    } on http.ClientException {
      throw const TdxException('無法連線至 TDX 資料服務，請稍後重試。');
    }
  }

  void close() => _client.close();
}
