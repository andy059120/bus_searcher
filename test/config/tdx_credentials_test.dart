import 'dart:convert';

import 'package:bus_project/config/tdx_credentials.dart';
import 'package:bus_project/data/services/tdx_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const emptyEnvironment = TdxCredentials(clientId: '', clientSecret: '');

class MemoryBundle extends CachingAssetBundle {
  MemoryBundle(this.contents);

  final String? contents;
  int reads = 0;

  @override
  Future<ByteData> load(String key) async {
    reads++;
    expect(key, TdxCredentials.assetPath);
    if (contents == null) throw FlutterError('missing asset');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(contents!)));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('plain launch loads both credentials from the bundled local file',
      () async {
    final bundle = MemoryBundle(jsonEncode({
      'TDX_CLIENT_ID': 'test-id',
      'TDX_CLIENT_SECRET': 'test-secret',
    }));
    final credentials = await TdxCredentials.load(
        bundle: bundle, environment: emptyEnvironment);
    expect(credentials.isConfigured, isTrue);
    expect(credentials.clientId, 'test-id');
    expect(credentials.clientSecret, 'test-secret');
    expect(bundle.reads, 1);
  });

  test('explicit complete environment overrides the asset without reading it',
      () async {
    final bundle = MemoryBundle(null);
    const environment = TdxCredentials(
        clientId: 'override-id', clientSecret: 'override-secret');
    expect(await TdxCredentials.load(bundle: bundle, environment: environment),
        same(environment));
    expect(bundle.reads, 0);
  });

  test('partial environment is rejected instead of mixing credential sources',
      () async {
    final bundle = MemoryBundle(jsonEncode({
      'TDX_CLIENT_ID': 'asset-id',
      'TDX_CLIENT_SECRET': 'asset-secret',
    }));
    await expectLater(
        TdxCredentials.load(
            bundle: bundle,
            environment: const TdxCredentials(
                clientId: 'override-id', clientSecret: '')),
        throwsA(isA<TdxException>()));
    expect(bundle.reads, 0);
  });

  for (final contents in <String?>[
    null,
    'secret-invalid-json',
    '[]',
    '{}',
    '{"TDX_CLIENT_ID":1,"TDX_CLIENT_SECRET":"test-secret"}',
    '{"TDX_CLIENT_ID":"id","TDX_CLIENT_SECRET":" "}',
  ]) {
    test(
        'invalid local setup returns a sanitized error: case ${contents?.length}',
        () async {
      await expectLater(
          TdxCredentials.load(
              bundle: MemoryBundle(contents), environment: emptyEnvironment),
          throwsA(isA<TdxException>().having(
              (error) => error.message,
              'safe message',
              allOf(isNot(contains('test-secret')),
                  isNot(contains('secret-invalid-json'))))));
    });
  }
}
