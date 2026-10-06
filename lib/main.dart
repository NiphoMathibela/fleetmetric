import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_gate.dart';
import 'services/notification_service.dart';

void main() async {
  // Supabase Initialisation
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://lfwhpfexxqnqnfurmkvq.supabase.co',
    publishableKey: 'sb_publishable_inMUG1x78xKUCEoT9GR_XQ__U6wN44B',
  );

  // Initialize notification service
  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Theme Palette Constants
    const primaryOrange = Color(0xFFFFA33C);
    const bgBlack = Color(0xFF0D0D0D);
    const cardDark = Color(0xFF1C1C1E);
    const secondaryDark = Color(0xFF26262A);
    const textPrimary = Color(0xFFFFFFFF);
    const textSecondary = Color(0xFF8E8E93);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),

      // Dark UI Theme Setup
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgBlack,
        primaryColor: primaryOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,

        colorScheme: const ColorScheme.dark(
          primary: primaryOrange,
          onPrimary: Colors.black,
          surface: cardDark,
          onSurface: textPrimary,
        ),

        // Custom styling for Action Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryOrange,
            foregroundColor: Colors.black,
            elevation: 0,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Bottom Navigation Bar Styling
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: secondaryDark,
          selectedItemColor: primaryOrange,
          unselectedItemColor: textSecondary,
          elevation: 0,
        ),

        // Text Styles
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSecondary),
        ),
      ),
    );
  }
}