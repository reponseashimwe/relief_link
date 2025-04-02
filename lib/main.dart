import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:relief_link/constants/app_constants.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/volunteer_provider.dart';
import 'wrapper.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/seed_accounts.dart';

const bool isDevelopment = true; // Set to false for production

Future<void> _initializeEmergencyAccounts() async {
  try {
    // First check if any emergency accounts exist
    final emergencyAccounts = await FirebaseFirestore.instance
        .collection(Collections.users)
        .where('role', isEqualTo: UserRole.emergencyService.name)
        .get();

    if (emergencyAccounts.docs.isEmpty) {
      debugPrint('No emergency accounts found. Creating new ones...');
      await AccountSeeder.seedEmergencyAccounts();
      debugPrint('Emergency accounts created successfully');
    } else {
      debugPrint(
          'Emergency accounts already exist. Count: ${emergencyAccounts.docs.length}');
    }
  } catch (e) {
    debugPrint('Error in _initializeEmergencyAccounts: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (isDevelopment) {
    debugPrint('Development mode: Initializing emergency accounts...');
    await _initializeEmergencyAccounts();
  }

  // Initialize Google Maps
  if (defaultTargetPlatform == TargetPlatform.android) {
    AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => VolunteerProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final ThemeData baseTheme = ThemeData(
            useMaterial3: true,
            fontFamily: 'Poppins',
          );

          final lightTheme = baseTheme.copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A73E8),
              brightness: Brightness.light,
            ),
            textTheme: baseTheme.textTheme.apply(
              fontFamily: 'Poppins',
              bodyColor: Colors.black87,
              displayColor: Colors.black,
            ),
          );

          final darkTheme = baseTheme.copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A73E8),
              brightness: Brightness.dark,
            ),
            textTheme: baseTheme.textTheme.apply(
              fontFamily: 'Poppins',
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
          );

          return MaterialApp(
            title: 'ReliefLink',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const Wrapper(),
              '/auth/signin': (context) => const SignInScreen(),
              '/auth/signup': (context) => const SignUpScreen(),
              '/auth/forgot-password': (context) =>
                  const ForgotPasswordScreen(),
            },
          );
        },
      ),
    );
  }
}
