import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'services/api_service.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

SemanticsHandle? _webSemanticsHandle;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BantoraApp());

  if (kIsWeb) {
    _webSemanticsHandle ??= SemanticsBinding.instance.ensureSemantics();
  }
}

class BantoraApp extends StatelessWidget {
  const BantoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    // API Service - can be configured via environment variables
    final apiUrl = const String.fromEnvironment('API_URL');
    if (apiUrl.isEmpty) {
      throw StateError(
        'Missing required compile-time environment variable API_URL. '
        'Build with --dart-define=API_URL=<base-url>.',
      );
    }

    final apiService = ApiService(baseUrl: apiUrl);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService: apiService)),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, _) {
          return MaterialApp(
            key: ValueKey<bool>(authProvider.isAuthenticated),
            title: 'Bantora - African Polling Platform',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF00A859),
                onPrimary: Colors.white,
                secondary: Color(0xFF0F0F0F),
                surface: Colors.white,
                onSurface: Colors.black,
                error: Color(0xFFDC143C),
                onError: Colors.white,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              scaffoldBackgroundColor: Colors.white,
            ),
            darkTheme: ThemeData(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF00A859),
                onPrimary: Colors.white,
                secondary: Color(0xFFFFD700),
                surface: Color(0xFF000000),
                onSurface: Colors.white,
                error: Color(0xFFDC143C),
                onError: Colors.white,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF000000),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              scaffoldBackgroundColor: const Color(0xFF000000),
            ),
            home: authProvider.isInitialized
                ? (authProvider.isAuthenticated
                    ? HomeScreen(apiService: apiService)
                    : const LoginScreen())
                : const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
          );
        },
      ),
    );
  }
}

