import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart' as app_provider;
import '../../providers/theme_provider.dart';
import '../../components/navigation/custom_app_bar.dart';
import '../../utils/seed_accounts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedCategory = 'All';
  bool _isDeveloperMode = false;
  int _devModeClickCount = 0;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_provider.AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Profile',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              setState(() {
                _devModeClickCount++;
                if (_devModeClickCount >= 7) {
                  _isDeveloperMode = true;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Developer mode activated!'),
                    ),
                  );
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (user?.photoURL != null)
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: CachedNetworkImageProvider(
                        user!.photoURL!,
                      ),
                    )
                  else
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade200,
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'User',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'No email provided',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          'Role: ${authProvider.userRole.name}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Dark/Light mode toggle
            ListTile(
              leading: Icon(
                themeProvider.themeMode == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
              title: Text(
                themeProvider.themeMode == ThemeMode.dark
                    ? 'Dark Mode'
                    : 'Light Mode',
              ),
              trailing: Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              ),
            ),

            // Sign out button
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                authProvider.signOut();
              },
            ),

            if (_isDeveloperMode) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Developer Options',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Seed Emergency Accounts'),
                subtitle: const Text('Create test accounts for services'),
                onTap: () async {
                  if (_devModeClickCount >= 7) {
                    setState(() => _isLoading = true);
                    try {
                      await AccountSeeder.seedEmergencyAccounts();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Developer accounts created successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error creating accounts: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                    _devModeClickCount = 0;
                  }
                },
              ),
            ],

            const Divider(),

            // Categories
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('All', _selectedCategory == 'All'),
                        _buildCategoryChip('Donations', _selectedCategory == 'Donations'),
                        _buildCategoryChip('Volunteer', _selectedCategory == 'Volunteer'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Latest Donations
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Latest Donations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _DonationCard(
                    title: 'Helping Hands for Karen Communities in Australia After Earthquake',
                    organization: 'Wecare Health',
                    targetAmount: 200000,
                    raisedAmount: 16950,
                    daysLeft: 20,
                    imageUrl: 'assets/images/earthquake.png',
                  ),
                ],
              ),
            ),

            // Last Read
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Last Read',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _LastReadCard(
                    title: 'The Great East Japan Earthquake and Tsunami',
                    category: 'Earthquake',
                    timeToRead: '5 mins read',
                    imageUrl: 'assets/images/earthquake.png',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = label;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final String title;
  final String organization;
  final double targetAmount;
  final double raisedAmount;
  final int daysLeft;
  final String imageUrl;

  const _DonationCard({
    required this.title,
    required this.organization,
    required this.targetAmount,
    required this.raisedAmount,
    required this.daysLeft,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final progress = raisedAmount / targetAmount;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Progress bar
          Container(
            height: 6,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: Row(
              children: [
                Container(
                  height: 6,
                  width: MediaQuery.of(context).size.width * progress * 0.9, // 0.9 to account for padding
                  color: Colors.green,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${raisedAmount.toInt()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '$daysLeft days left',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Organization and target
                Row(
                  children: [
                    Text(
                      'By $organization',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      ' • Target: \$${targetAmount.toInt()}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LastReadCard extends StatelessWidget {
  final String title;
  final String category;
  final String timeToRead;
  final String imageUrl;

  const _LastReadCard({
    required this.title,
    required this.category,
    required this.timeToRead,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Just Now • $timeToRead',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 