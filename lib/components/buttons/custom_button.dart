import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class CustomButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isFullWidth;
  final bool isLoading;
  final Color? color;

  const CustomButton({
    Key? key,
    required this.child,
    required this.onPressed,
    this.isOutlined = false,
    this.isFullWidth = true,
    this.isLoading = false,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined
              ? Colors.white
              : (color ?? const Color(0xFF1B4332)),
          foregroundColor: isOutlined ? const Color(0xFF1B4332) : Colors.white,
          side: isOutlined 
              ? const BorderSide(color: Color(0xFF1B4332)) 
              : null,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28), // More rounded shape
          ),
          elevation: isOutlined ? 0 : 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
                child: child,
              ),
      ),
    );
  }
}