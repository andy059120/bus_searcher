import 'package:flutter/material.dart';
import 'package:bus_project/config/tdx_credentials.dart';
import 'package:bus_project/data/services/bus_repository.dart';
import 'package:bus_project/data/services/tdx_api_client.dart';
import 'package:bus_project/features/home/presentation/home_page.dart';
import 'package:bus_project/shared/widgets/query_message.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.credentialsLoader});

  // 可注入讀取方式，測試啟動流程時不需要接觸真正的本機金鑰。
  final Future<TdxCredentials> Function()? credentialsLoader;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<BusRepository> _repository;
  TdxApiClient? _api;

  @override
  void initState() {
    super.initState();
    _repository = _initialize();
  }

  Future<BusRepository> _initialize() async {
    // 先讀設定再建立服務；首頁與所有子頁共用已設定的 client。
    // 此處只建立連線物件，不向 TDX 請求 token 或資料。
    final credentials =
        await (widget.credentialsLoader?.call() ?? TdxCredentials.load());
    final api = TdxApiClient.fromCredentials(credentials);
    if (!mounted) {
      api.close();
    } else {
      _api = api;
    }
    return BusRepository(api: api);
  }

  void _retry() {
    final repository = _initialize();
    setState(() {
      _repository = repository;
    });
  }

  @override
  void dispose() {
    _api?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '公車查詢',
        home: FutureBuilder<BusRepository>(
          future: _repository,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('設定讀取失敗')),
                body: Center(
                    child: QueryMessage(
                  message: queryErrorMessage(snapshot.error!),
                  onRetry: _retry,
                )),
              );
            }
            return HomePage(repository: snapshot.data!);
          },
        ),
        // 全 app 共用一個 MaterialApp，統一主題與 Navigator。
        theme: ThemeData(
          useMaterial3: false,
          colorSchemeSeed: Colors.blue,
          scaffoldBackgroundColor: const Color.fromARGB(255, 184, 232, 255),
        ),
      );
}
