import 'package:flutter/material.dart';
import './pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      title: 'Bus App',
      theme: ThemeData(
          scaffoldBackgroundColor: const Color.fromARGB(255, 133, 214, 251),
          primaryColor: const Color.fromARGB(255, 220, 220, 57)),

      /*initialRoute: '/home',
      routes: {
        '/home': (_) => const HomePage(),
        //'/routeDetail': (_) => const MyRouteDetailPage(),
        //'/third': (_) => ThirdWidget(),
      },*/
    );
  }
}
