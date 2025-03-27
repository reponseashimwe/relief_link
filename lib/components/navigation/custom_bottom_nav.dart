import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home, 'Home', context),
          _buildNavItem(1, Icons.chat_bubble_outline, 'Community', context),
          _buildEmergencyButton(context),
          _buildNavItem(3, Icons.favorite_border, 'Funds', context),
          _buildNavItem(4, Icons.person_outline, 'My Profile', context),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, BuildContext context) {
    final isSelected = index == currentIndex;
    final color = isSelected ? Theme.of(context).primaryColor : Colors.grey;
    
    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(2),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.phone,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}