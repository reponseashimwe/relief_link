import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'constants/colors.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ReliefLinkApp());
}

class ReliefLinkApp extends StatelessWidget {
  const ReliefLinkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Relief Link',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'Poppins',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.text),
            titleTextStyle: TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
              fontFamily: 'Poppins',
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              color: AppColors.text,
              fontFamily: 'Poppins',
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
              fontFamily: 'Poppins',
            ),
          ).apply(
            fontFamily: 'Poppins',
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                builder: (_) => const OnboardingScreen(),
              );
            case '/auth/signin':
              return MaterialPageRoute(
                builder: (_) => const SignInScreen(),
              );
            case '/auth/signup':
              return MaterialPageRoute(
                builder: (_) => const SignUpScreen(),
              );
            case '/auth/forgot-password':
              return MaterialPageRoute(
                builder: (_) => ForgotPasswordScreen(),
              );
            case '/auth/otp':
              final email = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => OtpVerificationScreen(email: email),
              );
            default:
              return MaterialPageRoute(
                builder: (_) => const OnboardingScreen(),
              );
          }
        },
      ),
    );
  }
}
