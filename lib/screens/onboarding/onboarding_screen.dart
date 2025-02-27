import 'package:flutter/material.dart';
import 'dart:async';
import '../../components/buttons/custom_button.dart';
import '../../components/onboarding/onboarding_item.dart';
import '../../components/onboarding/pagination.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Your Trusted Guide in Times of Disaster',
      'description': 'Discover peace of mind with real-time guidance and resources designed to keep you safe. Prepare, act, and recover with ease.',
      'image': 'assets/images/onboarding-1.png',
    },
    {
      'title': 'Empowering Safety, One Step at a Time',
      'description': 'Stay one step ahead in any emergency with tailored solutions that protect you and your loved ones. Safety starts here.',
      'image': 'assets/images/onboarding-2.png',
    },
    {
      'title': 'Preparedness at Your Fingertips',
      'description': 'Take charge of your safety with expert tools and advice that prepare you for the unexpected. Confidence is key.',
      'image': 'assets/images/onboarding-3.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _onboardingData.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _navigateToAuth() {
    _timer?.cancel(); // Cancel auto-slide before navigation
    Navigator.pushReplacementNamed(context, '/auth/signin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) => OnboardingItem(
                  title: _onboardingData[index]['title']!,
                  description: _onboardingData[index]['description']!,
                  imagePath: _onboardingData[index]['image']!,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  OnboardingPagination(
                    currentPage: _currentPage,
                    totalPages: _onboardingData.length,
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Get Started',
                    onPressed: _navigateToAuth,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 