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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000), // Pure black
        colorScheme: ColorScheme.dark(
          brightness: Brightness.dark,
          primary: const Color(0xFF00A859), // African Green
          secondary: const Color(0xFFFFD700), // African Yellow/Gold
          error: const Color(0xFFDC143C), // African Red
          background: const Color(0xFF000000), // Pure black
          surface: const Color(0xFF0F0F0F), // Near black for cards
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onError: Colors.white,
          onBackground: Colors.white,
          onSurface: Colors.white,
        ),
        useMaterial3: true,
        
        // Card theme with dark background and subtle border
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF0F0F0F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Color(0xFF1E1E1E),
              width: 1,
            ),
          ),
        ),
        
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0F0F0F),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1E1E1E)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1E1E1E)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF00A859), width: 2),
          ),
        ),
        
        // Text theme for high contrast
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Color(0xFFA0A0A0)), // Light gray for secondary text
          labelLarge: TextStyle(color: Colors.white),
          labelMedium: TextStyle(color: Color(0xFFA0A0A0)),
          labelSmall: TextStyle(color: Color(0xFFA0A0A0)),
        ),
        
        // AppBar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        
        // Button themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A859), // Green for primary actions
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF00A859),
          ),
        ),
        
        // Divider theme
        dividerTheme: const DividerThemeData(
          color: Color(0xFF1E1E1E),
          thickness: 1,
        ),
      ),
      home: HomeScreen(apiService: apiService),
    );
  }
}

