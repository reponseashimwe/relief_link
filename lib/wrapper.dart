import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart' as app_provider;
import 'screens/auth/sign_in_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/community/community_screen.dart';
import 'screens/emergency/emergency_screen.dart';
import 'screens/emergency/service_dashboard.dart';
import 'screens/funds/funds_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'components/navigation/custom_bottom_nav.dart';
import 'components/navigation/custom_app_bar.dart';
import 'constants/app_constants.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_provider.AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return const SignInScreen();
    }

    // Emergency service providers see different UI
    if (authProvider.isEmergencyService) {
      return const ServiceDashboard();
    }

    // Regular users see the normal UI
    final List<Widget> _screens = [
      const HomeScreen(),
      const CommunityScreen(),
      const EmergencyScreen(),
      const FundsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
