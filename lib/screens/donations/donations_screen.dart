import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/disaster.dart';

class DonationsScreen extends StatefulWidget {
  const DonationsScreen({Key? key}) : super(key: key);

  @override
  _DonationsScreenState createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsScreen> {
  String selectedCategory = 'All'; // Default category filter

  // Mock donation data (since Firestore doesn't have these fields)
  final Map<String, Map<String, dynamic>> mockDonationData = {
    'Floods': {
      'amountRaised': 866950,
      'target': 1000000,
      'daysLeft': 45,
      'organization': 'Wecare Foundation',
    },
    // Add more mock data for other disasters if needed
  };

  // Helper method to map Firestore category to UI category
  String mapToUICategory(String firestoreCategory) {
    switch (firestoreCategory.toLowerCase()) {
      case 'flood':
      case 'earthquake':
      case 'hurricane':
        return 'Disaster';
      // Add more mappings as needed
      default:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fundraising'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // TODO: Implement more options
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest Donations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Category Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'All',
                    isSelected: selectedCategory == 'All',
                    onTap: () {
                      setState(() {
                        selectedCategory = 'All';
                      });
                    },
                  ),
                  _CategoryChip(
                    label: 'Disaster',
                    isSelected: selectedCategory == 'Disaster',
                    onTap: () {
                      setState(() {
                        selectedCategory = 'Disaster';
                      });
                    },
                  ),
                  _CategoryChip(
                    label: 'Education',
                    isSelected: selectedCategory == 'Education',
                    onTap: () {
                      setState(() {
                        selectedCategory = 'Education';
                      });
                    },
                  ),
                  _CategoryChip(
                    label: 'Medical',
                    isSelected: selectedCategory == 'Medical',
                    onTap: () {
                      setState(() {
                        selectedCategory = 'Medical';
                      });
                    },
                  ),
                  _CategoryChip(
                    label: 'No Poverty',
                    isSelected: selectedCategory == 'No Poverty',
                    onTap: () {
                      setState(() {
                        selectedCategory = 'No Poverty';
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Donation Campaigns List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('disasters')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading data'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No disasters found'));
                  }

                  // Manually map Firestore documents to Disaster objects
                  final disasters = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Disaster(
                      id: doc.id,
                      category: data['category'] as String? ?? 'Unknown',
                      coordinates: data['coordinates'] != null
                          ? GeoPoint(
                              (data['coordinates'] as GeoPoint).latitude,
                              (data['coordinates'] as GeoPoint).longitude,
                            )
                          : const GeoPoint(0, 0),
                      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
                          DateTime.now(), // Convert Timestamp to DateTime
                      description:
                          data['description'] as String? ?? 'No description',
                      images: List<String>.from(data['images'] ?? []),
                      isVerified: data['isVerified'] as bool? ?? false,
                      location: data['location'] as String? ?? 'Unknown',
                      title: data['title'] as String? ?? 'Untitled',
                      userId: data['userId'] as String? ?? 'Unknown',
                      userName: data['userName'] as String? ?? 'Anonymous',
                    );
                  }).toList();

                  // Filter disasters by category
                  final filteredDisasters = selectedCategory == 'All'
                      ? disasters
                      : disasters
                          .where((disaster) =>
                              mapToUICategory(disaster.category) ==
                              selectedCategory)
                          .toList();

                  return ListView.builder(
                    itemCount: filteredDisasters.length,
                    itemBuilder: (context, index) {
                      final disaster = filteredDisasters[index];
                      final donationData = mockDonationData[disaster.title] ??
                          {
                            'amountRaised': 0,
                            'target': 100000,
                            'daysLeft': 30,
                            'organization': 'Unknown Organization',
                          };

                      return DonationCard(
                        title: disaster.description,
                        description:
                            'By ${donationData['organization']}  Target: \$${donationData['target'].toString()}',
                        imageUrl: disaster.images.isNotEmpty
                            ? disaster.images[0]
                            : 'https://via.placeholder.com/150',
                        amountRaised: donationData['amountRaised'],
                        target: donationData['target'],
                        daysLeft: donationData['daysLeft'],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Category Chip Widget
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.grey.shade200,
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

// Donation Card Widget
class DonationCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final int amountRaised;
  final int target;
  final int daysLeft;

  const DonationCard({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.amountRaised,
    required this.target,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (amountRaised / target).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${amountRaised.toString()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$daysLeft days left',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
