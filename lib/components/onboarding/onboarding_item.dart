import 'package:flutter/material.dart';

class OnboardingItem extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;

  const OnboardingItem({
    Key? key,
    required this.title,
    required this.description,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              ClipPath(
                clipper: _CustomClipPath(),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Custom clipper to create the curved corners based on the image
class _CustomClipPath extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Start at top-left
    path.lineTo(0, 0);
    
    // Line down to bottom-left with some offset before the curve begins
    path.lineTo(0, size.height - 60);
    
    // Create a curved path for the bottom-left corner
    path.quadraticBezierTo(
      size.width * 0.15, size.height, // Control point
      size.width * 0.4, size.height, // End point
    );
    
    // Line to the point where the bottom-right curve starts
    path.lineTo(size.width * 0.7, size.height);
    
    // Create a curve for the bottom-right corner
    // This creates the effect of a large circle cutting into the right bottom corner
    path.quadraticBezierTo(
      size.width + 50, size.height, // Control point outside the image
      size.width + 50, size.height * 0.7, // End point outside right edge
    );
    
    // Return to top-right corner
    path.lineTo(size.width, 0);
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
} 