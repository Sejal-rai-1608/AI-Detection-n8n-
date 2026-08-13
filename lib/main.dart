import 'package:flutter/material.dart';
import 'package:n8ntrial/screens/dashboard_screen.dart';
import 'package:n8ntrial/screens/auth_screen.dart';
import 'package:n8ntrial/screens/onboarding_screen.dart';
import 'package:n8ntrial/models/app_state.dart';

void main() {
  runApp(const TruthTraceApp());
}

class TruthTraceApp extends StatefulWidget {
  const TruthTraceApp({super.key});

  @override
  State<TruthTraceApp> createState() => _TruthTraceAppState();
}

class _TruthTraceAppState extends State<TruthTraceApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    appState.addListener(_updateTheme);
    _loadSplash();
  }

  @override
  void dispose() {
    appState.removeListener(_updateTheme);
    super.dispose();
  }

  void _updateTheme() {
    if (mounted) {
      setState(() {});
    }
  }

  void _loadSplash() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate theme dynamically based on appState.isDarkMode
    final isDark = appState.isDarkMode;
    
    return MaterialApp(
      title: 'TruthLens AI // Facts & Forensics',
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: const Color(0xFF4338CA),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF4338CA),
          secondary: Color(0xFF10B981),
          surface: Colors.white,
          error: Color(0xFFEF4444),
          background: Color(0xFFF8FAFC),
        ),
        dividerColor: const Color(0xFFE2E8F0),
        textTheme: const TextTheme(
          displayMedium: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
          bodyLarge: TextStyle(fontFamily: 'monospace', color: Color(0xFF0F172A)),
          bodyMedium: TextStyle(fontFamily: 'monospace', color: Color(0xFF64748B)),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF4338CA),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4338CA),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
          error: Color(0xFFEF4444),
          background: Color(0xFF0F172A),
        ),
        dividerColor: const Color(0xFF334155),
        textTheme: const TextTheme(
          displayMedium: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
          bodyLarge: TextStyle(fontFamily: 'monospace', color: Colors.white),
          bodyMedium: TextStyle(fontFamily: 'monospace', color: Color(0xFF94A3B8)),
        ),
      ),
      home: _showSplash
          ? const TruthLensSplashScreen()
          : (!appState.hasSeenOnboarding
              ? const OnboardingScreen()
              : (appState.isLoggedIn
                  ? const DashboardScreen()
                  : const TruthLensAuthScreen())),
    );
  }
}

class TruthLensSplashScreen extends StatelessWidget {
  const TruthLensSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shield Graphic
            Icon(
              Icons.shield_outlined,
              size: 80,
              color: Color(0xFF4338CA),
            ),
            SizedBox(height: 24),
            Text(
              "TruthLens AI",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0,
                fontFamily: 'monospace',
              ),
            ),
            SizedBox(height: 8),
            Text(
              "DEEP AI INTEGRITY SCANNER",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
