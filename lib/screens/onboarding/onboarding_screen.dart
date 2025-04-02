import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> _navigateToAuth() async {
    _timer?.cancel();
    
    // Save that user has seen onboarding
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/auth/signin');
    }
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Allow tapping on pagination to navigate
                      int targetPage = (_currentPage + 1) % _onboardingData.length;
                      _goToPage(targetPage);
                    },
                    child: OnboardingPagination(
                      currentPage: _currentPage,
                      totalPages: _onboardingData.length,
                      onDotTap: _goToPage,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _navigateToAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4332),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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