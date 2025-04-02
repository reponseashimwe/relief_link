import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({Key? key}) : super(key: key);

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
          'Help & Support',
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
          // Header image
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF2F7B40).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent,
                size: 60,
                color: Color(0xFF2F7B40),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'How can we help you?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Get support or provide feedback about ReliefLink',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 32),
          
          _buildSupportSection(
            context,
            title: 'Contact Support',
            items: [
              SupportItem(
                icon: Icons.email_outlined,
                title: 'Email Support',
                subtitle: 'support@relieflink.com',
                onTap: () => _launchURL('mailto:support@relieflink.com'),
              ),
              SupportItem(
                icon: Icons.chat_outlined,
                title: 'Live Chat',
                subtitle: 'Available 24/7',
                onTap: () {},
              ),
              SupportItem(
                icon: Icons.phone_outlined,
                title: 'Call Support',
                subtitle: '+1 (555) 123-4567',
                onTap: () => _launchURL('tel:+15551234567'),
              ),
            ],
            isDarkMode: isDarkMode,
          ),
          
          const SizedBox(height: 24),
          
          _buildSupportSection(
            context,
            title: 'Frequently Asked Questions',
            items: [
              SupportItem(
                icon: Icons.info_outline,
                title: 'How to report an emergency?',
                subtitle: 'Learn about emergency reporting',
                onTap: () {},
              ),
              SupportItem(
                icon: Icons.info_outline,
                title: 'How to make a donation?',
                subtitle: 'Step-by-step guide',
                onTap: () {},
              ),
              SupportItem(
                icon: Icons.info_outline,
                title: 'How to volunteer?',
                subtitle: 'Opportunities and requirements',
                onTap: () {},
              ),
            ],
            isDarkMode: isDarkMode,
          ),
          
          const SizedBox(height: 24),
          
          _buildSupportSection(
            context,
            title: 'Submit Feedback',
            items: [
              SupportItem(
                icon: Icons.star_outline,
                title: 'Rate the App',
                subtitle: 'Share your experience',
                onTap: () {},
              ),
              SupportItem(
                icon: Icons.feedback_outlined,
                title: 'Suggest a Feature',
                subtitle: 'Help us improve',
                onTap: () {},
              ),
              SupportItem(
                icon: Icons.bug_report_outlined,
                title: 'Report a Bug',
                subtitle: 'Let us know if something went wrong',
                onTap: () {},
              ),
            ],
            isDarkMode: isDarkMode,
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSupportSection(
    BuildContext context, {
    required String title,
    required List<SupportItem> items,
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
          child: Column(
            children: items.map((item) {
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F7B40).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    color: const Color(0xFF2F7B40),
                    size: 22,
                  ),
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                onTap: item.onTap,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class SupportItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  SupportItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
} 