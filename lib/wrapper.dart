import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/community/community_screen.dart';
import 'screens/emergency/emergency_screen.dart';
import 'screens/funds/funds_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'components/navigation/custom_bottom_nav.dart';
import 'components/navigation/custom_app_bar.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CommunityScreen(),
    const EmergencyScreen(),
    const FundsScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = [
    'Home',
    'Community',
    'Emergency',
    'Funds',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return const SignInScreen();
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: _titles[_currentIndex],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
} 