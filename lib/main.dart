import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/dashboard/dashboard_screen.dart';
import 'features/auth/login_screen.dart';
import 'core/providers/auth_provider.dart';

void main() {
  runApp(
    // Wrap the entire app with ProviderScope for Riverpod state management
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the auth state
    final isLoggedIn = ref.watch(authProvider);
    
    return MaterialApp(
      title: 'GreenPoint Customer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Modern Typography using Google Fonts
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // primaryGreen
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF81C784), // lightGreen
        ),
        useMaterial3: true,
      ),
      home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
