import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/fundraising_campaign.dart';

class DonorsListScreen extends StatelessWidget {
  final FundraisingCampaign campaign;

  const DonorsListScreen({
    Key? key,
    required this.campaign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('MMM d, yyyy');
    
    // Sort donations by date (most recent first)
    final sortedDonations = [...campaign.donations]
      ..sort((a, b) => b.donatedAt.compareTo(a.donatedAt));
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Donors',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Campaign summary card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Raised: ${currencyFormat.format(campaign.currentAmount)}',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${campaign.donations.length} donors',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Donors list header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'All Donors',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                // You could add filters here if needed
              ],
            ),
          ),
          
          // Divider
          Divider(color: Colors.grey[300], height: 1),
          
          // Donors list
          Expanded(
            child: sortedDonations.isEmpty
                ? Center(
                    child: Text(
                      'No donations yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: sortedDonations.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.grey[200],
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final donation = sortedDonations[index];
                      final donorName = donation.anonymous
                          ? 'Anonymous Donor'
                          : (donation.userName ?? 'Unknown User');
                      
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: donation.anonymous || donation.userPhotoUrl == null
                              ? Colors.grey[300]
                              : null,
                          backgroundImage: donation.anonymous || donation.userPhotoUrl == null
                              ? null
                              : NetworkImage(donation.userPhotoUrl!),
                          child: donation.anonymous || donation.userPhotoUrl == null
                              ? Text(
                                  donation.anonymous ? 'A' : donorName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          donorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          dateFormat.format(donation.donatedAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        trailing: Text(
                          currencyFormat.format(donation.amount),
                          style: const TextStyle(
                            color: Color(0xFF2F7B40),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 