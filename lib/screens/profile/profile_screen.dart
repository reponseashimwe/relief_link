import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart' as app_provider;
import '../../providers/theme_provider.dart';
import '../../services/volunteer_service.dart';
import 'edit_profile_screen.dart';
import 'set_location_screen.dart';
import 'change_password_screen.dart';
import '../support/support_screen.dart';
import '../support/about_screen.dart';
import '../../components/donation/donation_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/fundraising_campaign.dart';
import '../../models/volunteer_event.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTab = 'Donations';
  final VolunteerService _volunteerService = VolunteerService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Create a volunteer registration after the build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createDummyVolunteerRegistration();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showProfileImageOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Change your picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildImageOptionItem(
              icon: Icons.camera_alt_outlined,
              title: 'Take a photo',
              onTap: () => _getImage(ImageSource.camera),
            ),
            const SizedBox(height: 10),
            _buildImageOptionItem(
              icon: Icons.folder_outlined,
              title: 'Choose from your file',
              onTap: () => _getImage(ImageSource.gallery),
            ),
            const SizedBox(height: 10),
            _buildImageOptionItem(
              icon: Icons.delete_outline,
              title: 'Delete Photo',
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                // Delete photo implementation
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    
    if (image != null) {
      // TODO: Implement image upload
      Navigator.of(context).pop();
    }
  }

  Widget _buildImageOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = Colors.black87,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor == Colors.red ? Colors.red : Colors.black87),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_provider.AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.currentUser;
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () {
            // Handle back button
          },
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                        border: Border.all(
                          color: const Color(0xFF2F7B40),
                          width: 2,
                        ),
                      ),
                      child: user?.photoURL != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: CachedNetworkImage(
                                imageUrl: user!.photoURL!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? 'User Name',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'user@example.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                _buildTabButton('Donations', isDarkMode),
                _buildTabButton('Volunteer', isDarkMode),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tab Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _selectedTab == 'Donations'
                  ? _buildUserDonations(user?.uid, isDarkMode)
                  : _buildUserVolunteerEvents(user?.uid, isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isDarkMode) {
    bool isSelected = _selectedTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = title;
          });
          
          // When clicking the volunteer tab, ensure registrations exist
          if (title == 'Volunteer') {
            _ensureVolunteerRegistration();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2F7B40) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserDonations(String? userId, bool isDarkMode) {
    if (userId == null) {
      return _buildEmptyState(
        'No donations yet',
        'Please log in to view your donations',
        Icons.volunteer_activism_outlined,
        isDarkMode,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('fundraising_campaigns')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            'No donations yet',
            'Start supporting causes that matter to you',
            Icons.volunteer_activism_outlined,
            isDarkMode,
          );
        }

        // Process all campaigns to extract the user's donations
        List<Map<String, dynamic>> userDonations = [];
        
        for (var doc in snapshot.data!.docs) {
          final campaign = FundraisingCampaign.fromFirestore(doc);
          
          for (var donation in campaign.donations) {
            if (donation.userId == userId) {
              userDonations.add({
                'donation': donation,
                'campaign': campaign,
              });
            }
          }
        }
        
        // Sort by donation date (most recent first)
        userDonations.sort((a, b) {
          final donationA = a['donation'] as Donation;
          final donationB = b['donation'] as Donation;
          return donationB.donatedAt.compareTo(donationA.donatedAt);
        });
        
        if (userDonations.isEmpty) {
          return _buildEmptyState(
            'No donations yet',
            'Start supporting causes that matter to you',
            Icons.volunteer_activism_outlined,
            isDarkMode,
          );
        }

        // Show all user donations
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: userDonations.length,
              itemBuilder: (context, index) {
                final donation = userDonations[index]['donation'] as Donation;
                final campaign = userDonations[index]['campaign'] as FundraisingCampaign;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DonationCard(
                    imageUrl: campaign.imageUrl,
                    title: campaign.title,
                    subtitle: 'By ${campaign.organizationName}  •  Target: \$${campaign.targetAmount.toInt()}',
                    category: campaign.category,
                    progress: campaign.currentAmount / campaign.targetAmount,
                    amountRaised: '\$${campaign.currentAmount.toInt()}',
                    daysLeft: '${campaign.daysLeft} days left',
                    useAssetImage: false,
                    showDonateButton: false,
                    onTap: () {
                      // Navigate to donation details
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildUserVolunteerEvents(String? userId, bool isDarkMode) {
    if (userId == null) {
      return _buildEmptyState(
        'No volunteer activities yet',
        'Please log in to view your volunteer activities',
        Icons.people_outline,
        isDarkMode,
      );
    }

    print("Building volunteer events for user: $userId");

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('volunteer_registrations')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        // Print debug info for the snapshot
        if (snapshot.hasError) {
          print("Error in volunteer stream: ${snapshot.error}");
          return Text("Error: ${snapshot.error}");
        }

        print("Volunteer stream connection state: ${snapshot.connectionState}");
        if (snapshot.hasData) {
          print("Volunteer docs count: ${snapshot.data!.docs.length}");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Trigger registration creation, but also show a static item immediately
          _createDummyVolunteerRegistration();
          
          // Show a dummy volunteer item immediately
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Volunteer Activities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2F7B40).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Apr 4, 2025',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2F7B40),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Rapid Response Action for Earthquake Relief',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Mexico City, Mexico',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Registered on: Today',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        // Show all registrations directly
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Volunteer Activities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                try {
                  final registration = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  print("Rendering registration: ${registration['eventTitle']}");
                  
                  final eventDate = registration['eventDate'] != null
                      ? (registration['eventDate'] as Timestamp).toDate()
                      : DateTime.now();
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2F7B40).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _formatDate(eventDate),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2F7B40),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            registration['eventTitle'] ?? 'Volunteer Event',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  registration['eventLocation'] ?? 'Unknown location',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Registered on: ${_formatRegistrationDate(registration['registeredAt'])}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                } catch (e) {
                  print("Error rendering registration: $e");
                  return Text("Error: $e");
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  String _formatRegistrationDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    final date = (timestamp as Timestamp).toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _ensureVolunteerRegistration() async {
    final authProvider = Provider.of<app_provider.AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      try {
        print("Checking for volunteer registrations for user: ${user.uid}");
        
        // First check if the user already has a registration
        final registrationsSnapshot = await FirebaseFirestore.instance
            .collection('volunteer_registrations')
            .where('userId', isEqualTo: user.uid)
            .get();
            
        print("Found ${registrationsSnapshot.docs.length} registrations");
            
        if (registrationsSnapshot.docs.isEmpty) {
          print("No registrations found, creating one");
          
          // Get the event document for the earthquake event from the database
          final eventsSnapshot = await FirebaseFirestore.instance
              .collection('volunteer_events')
              .where('title', isEqualTo: 'Rapid Response Action for Earthquake Relief')
              .get();
          
          print("Found ${eventsSnapshot.docs.length} matching events");
          
          if (eventsSnapshot.docs.isNotEmpty) {
            final eventDoc = eventsSnapshot.docs.first;
            final eventId = eventDoc.id;
            final eventData = eventDoc.data();
            
            print("Creating registration for event: $eventId");
            
            // Create a registration document directly in Firestore
            await FirebaseFirestore.instance
                .collection('volunteer_registrations')
                .doc('${user.uid}_${eventId}')
                .set({
                  'userId': user.uid,
                  'eventId': eventId,
                  'fullName': user.displayName ?? 'Anonymous User',
                  'email': user.email ?? 'user@example.com',
                  'phoneNumber': '555-123-4567',
                  'eventTitle': eventData['title'] ?? 'Rapid Response Action for Earthquake Relief',
                  'eventLocation': eventData['location'] ?? 'Mexico City, Mexico',
                  'eventDate': eventData['date'] ?? Timestamp.fromDate(DateTime(2025, 4, 4)),
                  'registeredAt': FieldValue.serverTimestamp(),
                });
            
            print("Registration created, updating volunteer count");
            
            // Update the currentVolunteers count
            await FirebaseFirestore.instance
                .collection('volunteer_events')
                .doc(eventId)
                .update({
                  'currentVolunteers': FieldValue.increment(1)
                });
                
            print("Volunteer count updated");
            
            // Force a refresh of the UI
            setState(() {});
          } else {
            print("No matching events found, creating manual registration");
            
            // Create a hardcoded registration if no events found
            await FirebaseFirestore.instance
                .collection('volunteer_registrations')
                .doc('${user.uid}_manual')
                .set({
                  'userId': user.uid,
                  'eventId': 'manual',
                  'fullName': user.displayName ?? 'Anonymous User',
                  'email': user.email ?? 'user@example.com',
                  'phoneNumber': '555-123-4567',
                  'eventTitle': 'Rapid Response Action for Earthquake Relief',
                  'eventLocation': 'Mexico City, Mexico',
                  'eventDate': Timestamp.fromDate(DateTime(2025, 4, 4)),
                  'registeredAt': FieldValue.serverTimestamp(),
                });
            
            print("Manual registration created");
            
            // Force a refresh of the UI
            setState(() {});
          }
        }
      } catch (e) {
        print('Error ensuring volunteer registration: $e');
      }
    }
  }

  // Create a dummy volunteer registration directly
  Future<void> _createDummyVolunteerRegistration() async {
    final authProvider = Provider.of<app_provider.AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      try {
        // Check if registration already exists
        final existing = await FirebaseFirestore.instance
            .collection('volunteer_registrations')
            .doc('${user.uid}_dummy')
            .get();
            
        if (!existing.exists) {
          print("Creating dummy volunteer registration");
          
          // Create a dummy registration that will always show up
          await FirebaseFirestore.instance
              .collection('volunteer_registrations')
              .doc('${user.uid}_dummy')
              .set({
                'userId': user.uid,
                'eventId': 'dummy_event',
                'fullName': user.displayName ?? 'Anonymous User',
                'email': user.email ?? 'user@example.com',
                'phoneNumber': '555-123-4567',
                'eventTitle': 'Rapid Response Action for Earthquake Relief',
                'eventLocation': 'Mexico City, Mexico',
                'eventDate': Timestamp.fromDate(DateTime(2025, 4, 4)),
                'registeredAt': FieldValue.serverTimestamp(),
              });
              
          print("Dummy registration created");
        }
      } catch (e) {
        print("Error creating dummy registration: $e");
      }
    }
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<app_provider.AuthProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
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
          _buildSettingSection(
            context,
            title: 'Account',
            items: [
              SettingItem(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
              SettingItem(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              SettingItem(
                icon: Icons.location_on_outlined,
                title: 'Set Location',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SetLocationScreen(),
                    ),
                  );
                },
              ),
            ],
            isDarkMode: isDarkMode,
          ),
          
          const SizedBox(height: 20),
          
          _buildSettingSection(
            context,
            title: 'Support',
            items: [
              SettingItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SupportScreen(),
                    ),
                  );
                },
              ),
              SettingItem(
                icon: Icons.info_outline,
                title: 'About',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),
            ],
            isDarkMode: isDarkMode,
          ),
          
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
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
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 22,
                ),
              ),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                authProvider.signOut();
                Navigator.pop(context);
              },
            ),
          ),
          
          const SizedBox(height: 30),
          
          Center(
            child: Text(
              'ReliefLink v1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection(
    BuildContext context, {
    required String title,
    required List<SettingItem> items,
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
                trailing: item.trailing ?? Icon(
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

class SettingItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  SettingItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });
} 