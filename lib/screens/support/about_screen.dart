import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'About',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // App Logo
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF2F7B40).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety,
                size: 60,
                color: Color(0xFF2F7B40),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'ReliefLink',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Version 1.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Mission section
          _buildAboutSection(
            context,
            title: 'Our Mission',
            content: 'ReliefLink is dedicated to providing critical support and resources during natural disasters and emergencies. We connect those in need with assistance, facilitate donations, and coordinate volunteer efforts to build stronger, more resilient communities.',
            isDarkMode: isDarkMode,
          ),
          
          const SizedBox(height: 20),
          
          // Features section
          _buildAboutSection(
            context,
            title: 'Key Features',
            content: '• Real-time disaster alerts and information\n• Donation platform for disaster relief\n• Volunteer coordination and management\n• Emergency resource locator\n• Community support network\n• Educational resources for disaster preparedness',
            isDarkMode: isDarkMode,
          ),
          
          const SizedBox(height: 20),
          
          // Our team section
          _buildAboutSection(
            context,
            title: 'Our Team',
            content: 'ReliefLink was developed by a dedicated team of engineers, disaster response specialists, and community advocates committed to leveraging technology for humanitarian purposes.',
            isDarkMode: isDarkMode,
          ),
          
          const SizedBox(height: 20),
          
          // Contact information
          _buildAboutSection(
            context,
            title: 'Contact Information',
            content: 'Email: info@relieflink.com\nWebsite: www.relieflink.com\nHeadquarters: Kigali, Rwanda',
            isDarkMode: isDarkMode,
          ),
          
          const SizedBox(height: 20),
          
          // Social media links
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Follow Us',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSocialButton(
                      icon: Icons.facebook,
                      color: const Color(0xFF1877F2),
                      onTap: () => _launchURL('https://facebook.com'),
                      isDarkMode: isDarkMode,
                    ),
                    _buildSocialButton(
                      icon: Icons.camera_alt,
                      color: const Color(0xFFE1306C),
                      onTap: () => _launchURL('https://instagram.com'),
                      isDarkMode: isDarkMode,
                    ),
                    _buildSocialButton(
                      icon: Icons.chat_bubble,
                      color: const Color(0xFF1DA1F2),
                      onTap: () => _launchURL('https://twitter.com'),
                      isDarkMode: isDarkMode,
                    ),
                    _buildSocialButton(
                      icon: Icons.link,
                      color: const Color(0xFF0A66C2),
                      onTap: () => _launchURL('https://linkedin.com'),
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Legal links
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {},
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF2F7B40),
                  ),
                ),
              ),
              Container(
                height: 12,
                width: 1,
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Terms of Service',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF2F7B40),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Copyright text
          Text(
            '© 2023 ReliefLink. All rights reserved.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildAboutSection(
    BuildContext context, {
    required String title,
    required String content,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }
} 