import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const BantoraApp());
}

class BantoraApp extends StatelessWidget {
  const BantoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    // API Service - can be configured via environment variables
    final apiService = ApiService(
      baseUrl: const String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://localhost:8081',
      ),
    );

    return MaterialApp(
      title: 'Bantora - African Polling Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
        ),
      ),
      home: HomeScreen(apiService: apiService),
    );
  }
}

