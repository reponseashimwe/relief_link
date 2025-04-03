import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../widgets/campaign_card.dart';
import '../../models/fundraising_campaign.dart';
import '../../providers/auth_provider.dart';
import '../donations/create_campaign_screen.dart';

class FundsScreen extends StatefulWidget {
  const FundsScreen({Key? key}) : super(key: key);

  @override
  State<FundsScreen> createState() => _FundsScreenState();
}

class _FundsScreenState extends State<FundsScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Emergency Relief',
    'Medical Support',
    'Shelter',
    'Food & Water',
    'Education',
    'Infrastructure',
    'Other'
  ];
  
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _campaignsKey = GlobalKey();
  
  void _scrollToCampaigns() {
    if (_campaignsKey.currentContext != null) {
      Scrollable.ensureVisible(
        _campaignsKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Donation & Funds',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2F7B40), size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateCampaignScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              // Search functionality would go here
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _scrollToCampaigns,
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.volunteer_activism,
                      color: Colors.green.shade700,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Make a Donation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Support disaster relief efforts',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
          
          // Categories
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2F7B40) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2F7B40) : Colors.grey[300]!,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            key: _campaignsKey,
            child: const Text(
              'Recent Campaigns',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Campaigns
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                .collection('fundraising_campaigns')
                .orderBy('createdAt', descending: true)
                .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No fundraising campaigns yet.\nHelp is needed for those affected by disasters.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }
                
                // Convert documents to campaigns
                final campaigns = snapshot.data!.docs.map((doc) {
                  return FundraisingCampaign.fromFirestore(doc);
                }).toList();
                
                // Filter by category if not "All"
                final filteredCampaigns = _selectedCategory == 'All'
                    ? campaigns
                    : campaigns.where((c) => c.category == _selectedCategory).toList();
                
                if (filteredCampaigns.isEmpty) {
                  return Center(
                    child: Text(
                      'No $_selectedCategory campaigns yet.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }
                
                // Find featured campaign (if any)
                final featuredCampaigns = filteredCampaigns.where((c) => c.featured).toList();
                final hasFeatured = featuredCampaigns.isNotEmpty;
                final FundraisingCampaign? featuredCampaign = hasFeatured ? featuredCampaigns.first : null;
                
                // Regular campaigns (excluding featured)
                final regularCampaigns = hasFeatured
                    ? filteredCampaigns.where((c) => !c.featured).toList()
                    : filteredCampaigns;
                
                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Featured campaign
                    if (hasFeatured) ...[
                      CampaignCard(
                        campaign: featuredCampaign!,
                        featured: true,
                        showDonateButton: true,
                      ),
                      const Divider(height: 24),
                    ],
                    
                    // Regular campaigns
                    ...regularCampaigns.map((campaign) => CampaignCard(
                      campaign: campaign,
                      showDonateButton: true,
                    )),
                    
                    // Bottom padding
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 