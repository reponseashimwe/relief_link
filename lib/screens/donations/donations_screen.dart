import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:relief_link/widgets/campaign_card.dart';
import '../../models/fundraising_campaign.dart';
import '../../providers/auth_provider.dart';
import 'create_campaign_screen.dart';

class DonationsScreen extends StatefulWidget {
  const DonationsScreen({Key? key}) : super(key: key);

  @override
  State<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.currentUser?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Fundraising',
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
          
          const SizedBox(height: 16),
          
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
                  final data = doc.data() as Map<String, dynamic>;
                  return FundraisingCampaign.fromMap(data);
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
                
                return CustomScrollView(
                  slivers: [
                    // Featured campaign
                    if (hasFeatured)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Featured Campaign',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              CampaignCard(
                                campaign: featuredCampaign!,
                                featured: true,
                              ),
                              const Divider(height: 32),
                              const Text(
                                'All Campaigns',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    
                    // Regular campaigns
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return CampaignCard(
                              campaign: regularCampaigns[index],
                              showDonateButton: true,
                            );
                          },
                          childCount: regularCampaigns.length,
                        ),
                      ),
                    ),
                    
                    // Bottom padding
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 16),
                    ),
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