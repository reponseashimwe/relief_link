import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:relief_link/constants/app_constants.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/volunteer_provider.dart';
import 'wrapper.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/seed_accounts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bool isDevelopment = true; // Set to false for production

Future<void> _initializeEmergencyAccounts() async {
  try {
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();
  }

  if (isDevelopment) {
    debugPrint('Development mode: Initializing emergency accounts...');
    await _initializeEmergencyAccounts();
  }

  // Initialize Google Maps
  if (defaultTargetPlatform == TargetPlatform.android) {
    final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
    }
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
              seedColor: const Color(0xFF1B4332),
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
              seedColor: const Color(0xFF1B4332),
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
              '/': (context) => FutureBuilder<SharedPreferences>(
                future: SharedPreferences.getInstance(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final hasSeenOnboarding = snapshot.data!.getBool('has_seen_onboarding') ?? false;

                  if (!hasSeenOnboarding) {
                    return const OnboardingScreen();
                  }

                  return const Wrapper();
                },
              ),
              '/auth/signin': (context) => const SignInScreen(),
              '/auth/signup': (context) => const SignUpScreen(),
              '/auth/forgot-password': (context) => const ForgotPasswordScreen(),
              '/auth/otp': (context) => const OtpVerificationScreen(email: ''),
            },
          );
        },
      ),
    );
  }
}
