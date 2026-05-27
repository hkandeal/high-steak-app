import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const HighSteakApp());
}

class HighSteakApp extends StatelessWidget {
  const HighSteakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'High Steak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFC43A2A),
          secondary: const Color(0xFFD4A054),
          surface: const Color(0xFF1F0F0C),
        ),
        scaffoldBackgroundColor: const Color(0xFF120806),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}
