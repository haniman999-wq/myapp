import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'theme.dart';

void main() {
  runApp(const MyCustomersApp());
}

class MyCustomersApp extends StatelessWidget {
  const MyCustomersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '내 고객의 모든 것',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryGreen),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
