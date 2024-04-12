import 'dart:convert';
import 'package:http/http.dart' as http;

class AccessToken {
  final String accessToken;

  const AccessToken({required this.accessToken});

  factory AccessToken.fromJson(Map<String, dynamic> json) {
    return AccessToken(
      accessToken: json['access_token'],
    );
  }
}

Future<String> getAccessToken() async {
  var url = Uri.https('tdx.transportdata.tw',
      'auth/realms/TDXConnect/protocol/openid-connect/token');
  var response = await http.post(url, body: {
    'grant_type': 'client_credentials',
    'client_id': 'u10948055-f0f2779f-1da9-4ef4',
    'client_secret': '89496e5f-e2a7-4a30-ac77-0126c6427a38'
  });
  if (response.statusCode == 200) {
    return AccessToken.fromJson(jsonDecode(response.body)).accessToken;
  } else {
    throw Exception('Failed to get accessToken');
  }
}
