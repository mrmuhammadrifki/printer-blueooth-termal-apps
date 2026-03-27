import 'package:flutter/material.dart';
import 'services/printer_service.dart';
import 'ui/main_screen.dart';

void main() {
  runApp(const OrbitPrintApp());
}

class OrbitPrintApp extends StatelessWidget {
  const OrbitPrintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrbitPrint',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D9FF),
          brightness: Brightness.dark,
          primary: const Color(0xFF00D9FF),
          secondary: const Color(0xFF00FFA3),
          surface: const Color(0xFF1A1F2E),
          background: const Color(0xFF0F1419),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F1419),
        cardTheme: CardTheme(
          color: const Color(0xFF1A1F2E),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1F2E),
          elevation: 0,
          centerTitle: false,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1F2E),
          selectedItemColor: Color(0xFF00D9FF),
          unselectedItemColor: Color(0xFF6B7280),
          type: BottomNavigationBarType.fixed,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D9FF),
            foregroundColor: const Color(0xFF0F1419),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1F2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2D3748)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00D9FF), width: 2),
          ),
        ),
      ),
      home: MainScreen(printerService: PrinterService()),
    );
  }
}
