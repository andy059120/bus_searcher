import 'dart:async';
import 'dart:convert';

import 'package:bus_project/config/tdx_credentials.dart';
import 'package:bus_project/data/services/tdx_exception.dart';
import 'package:bus_project/data/services/tdx_request_limiter.dart';
import 'package:http/http.dart' as http;

class TdxTokenService {
  TdxTokenService({
    required http.Client client,
    required TdxCredentials credentials,
    TdxRequestLimiter? limiter,
    DateTime Function()? now,
    this.requestTimeout = const Duration(seconds: 10),
  })  : _client = client,
        _credentials = credentials,
        limiter = limiter ?? TdxRequestLimiter(now: now),
        _now = now ?? DateTime.now;

  static final _tokenUri = Uri.https('tdx.transportdata.tw',
      '/auth/realms/TDXConnect/protocol/openid-connect/token');

  final http.Client _client;
  final TdxCredentials _credentials;
  final TdxRequestLimiter limiter;
  final DateTime Function() _now;
  final Duration requestTimeout;
  _CachedToken? _cached;
  Future<_CachedToken>? _pending;

  Future<String> getAccessToken() async {
    final cached = _cached;
    if (cached != null && _now().isBefore(cached.refreshAt)) {
      return cached.value;
    }

    // All callers share one authentication request, including concurrent pages.
    final pending = _pending ??= _requestToken();
    try {
      return (await pending).value;
    } finally {
      if (identical(_pending, pending)) _pending = null;
    }
  }

  void invalidate(String rejectedToken) {
    // A delayed 401 for an old token must not discard an already renewed token.
    if (_cached?.value == rejectedToken) _cached = null;
  }

  Future<_CachedToken> _requestToken() async {
    if (!_credentials.isConfigured) {
      throw const TdxException('尚未設定 TDX API 憑證。');
    }

    final requestedAt = _now();
    // 正式 app 與資料 API 共用限流器，保守地計入認證的流量。
    limiter.acquire();
    final request = http.Request('POST', _tokenUri)
      ..followRedirects = false
      ..headers['Accept'] = 'application/json'
      ..bodyFields = {
        'grant_type': 'client_credentials',
        'client_id': _credentials.clientId,
        'client_secret': _credentials.clientSecret,
      };

    final http.Response response;
    try {
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(requestTimeout);
    } on TimeoutException {
      throw const TdxException('TDX 認證逾時，請稍後重試。');
    } on http.ClientException {
      throw const TdxException('無法連線至 TDX 認證服務，請稍後重試。');
    }

    if (response.statusCode != 200) {
      if (response.statusCode == 429) {
        limiter.recordRateLimit(response.headers['retry-after']);
        throw const TdxException('TDX 認證暫時受限，請稍後重試。', statusCode: 429);
      }
      throw TdxException(
          'TDX 認證失敗（HTTP ${response.statusCode}），請確認 API 金鑰與服務權限。',
          statusCode: response.statusCode);
    }

    final dynamic json;
    try {
      json = jsonDecode(response.body);
    } on FormatException {
      throw const TdxException('TDX 認證服務回傳了無效資料。');
    }

    if (json is! Map<String, dynamic>) {
      throw const TdxException('TDX 認證服務回傳了無效資料。');
    }
    final token = json['access_token'];
    final expiresIn = json['expires_in'];
    final tokenType = json['token_type'];
    if (token is! String ||
        token.isEmpty ||
        RegExp(r'\s').hasMatch(token) ||
        expiresIn is! int ||
        expiresIn <= 0 ||
        tokenType is! String ||
        tokenType.toLowerCase() != 'bearer') {
      throw const TdxException('TDX 認證服務回傳了無效資料。');
    }

    final lifetime = Duration(seconds: expiresIn);
    // Refresh up to 60 seconds early, capped at 10% for short-lived tokens.
    final marginMicroseconds = lifetime.inMicroseconds ~/ 10;
    final margin = Duration(
      microseconds:
          marginMicroseconds < const Duration(minutes: 1).inMicroseconds
              ? marginMicroseconds
              : const Duration(minutes: 1).inMicroseconds,
    );
    final refreshAt = requestedAt.add(lifetime).subtract(margin);
    if (!_now().isBefore(refreshAt)) {
      throw const TdxException('TDX 認證回應過慢，請稍後重試。');
    }
    final cached = _CachedToken(token, refreshAt);
    _cached = cached;
    return cached;
  }
}

class _CachedToken {
  const _CachedToken(this.value, this.refreshAt);

  final String value;
  final DateTime refreshAt;
}
