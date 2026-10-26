import 'dart:convert';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:bus_project/data/services/tdx_exception.dart';

class TdxCredentials {
  final String clientId;
  final String clientSecret;

  const TdxCredentials({required this.clientId, required this.clientSecret});

  const TdxCredentials.fromEnvironment()
      : clientId = const String.fromEnvironment('TDX_CLIENT_ID'),
        clientSecret = const String.fromEnvironment('TDX_CLIENT_SECRET');

  static const assetPath = 'config/tdx.local.json';

  /// 一般 flutter run 自動載入 asset；明確傳入的編譯期設定優先。
  static Future<TdxCredentials> load({
    AssetBundle? bundle,
    TdxCredentials environment = const TdxCredentials.fromEnvironment(),
  }) async {
    if (environment.clientId.isNotEmpty ||
        environment.clientSecret.isNotEmpty) {
      // 不混用不同來源的 ID／secret，避免誤用不成對的憑證。
      if (!environment.isConfigured) {
        throw const TdxException('TDX 編譯期憑證不完整，請同時設定 ID 與 Secret。');
      }
      return environment;
    }

    final String contents;
    try {
      contents =
          await (bundle ?? rootBundle).loadString(assetPath, cache: false);
    } on FlutterError {
      throw const TdxException('找不到 TDX 本機設定，請建立 config/tdx.local.json 後重新執行。');
    }

    try {
      final json = jsonDecode(contents);
      if (json is! Map<String, dynamic>) throw const FormatException();
      final id = json['TDX_CLIENT_ID'];
      final secret = json['TDX_CLIENT_SECRET'];
      if (id is! String || secret is! String) throw const FormatException();
      final credentials = TdxCredentials(clientId: id, clientSecret: secret);
      if (!credentials.isConfigured) {
        throw const TdxException(
            'TDX 本機憑證尚未填寫，請設定 config/tdx.local.json 後重新執行。');
      }
      return credentials;
    } on FormatException {
      // 固定訊息不包含 JSON 內容，避免解析錯誤洩漏 secret。
      throw const TdxException('TDX 本機設定格式不正確，請確認兩個憑證欄位皆為字串。');
    }
  }

  bool get isConfigured =>
      clientId.trim().isNotEmpty && clientSecret.trim().isNotEmpty;
}
