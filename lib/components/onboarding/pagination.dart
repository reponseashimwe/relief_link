import 'package:flutter/material.dart';

class OnboardingPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int)? onDotTap;

  const OnboardingPagination({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    this.onDotTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => GestureDetector(
          onTap: () {
            if (onDotTap != null) {
              onDotTap!(index);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: currentPage == index ? 24 : 8,
            decoration: BoxDecoration(
              color: currentPage == index ? const Color(0xFF1B4332) : const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
} 