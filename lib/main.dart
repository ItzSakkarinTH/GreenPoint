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
    final authState = ref.watch(authProvider);
    
    return authState.when(
      data: (isLoggedIn) => MaterialApp(
        title: 'GreenPoint Customer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Modern Typography using Google Fonts
          textTheme: GoogleFonts.interTextTheme(),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32), // primaryGreen
            primary: const Color(0xFF2E7D32),
            secondary: const Color(0xFF81C784), // lightGreen
          ),
          useMaterial3: true,
        ),
        home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
      ),
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
        ),
        home: const Scaffold(
          backgroundColor: Color(0xFFF9FBE7),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.eco_rounded,
                  size: 80,
                  color: Color(0xFF2E7D32),
                ),
                SizedBox(height: 24),
                CircularProgressIndicator(
                  color: Color(0xFF2E7D32),
                ),
              ],
            ),
          ),
        ),
      ),
      error: (err, stack) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Text('Error: $err'),
          ),
        ),
      ),
    );
  }
}
