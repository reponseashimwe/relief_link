import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'wrapper.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/disaster/post_disaster_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
