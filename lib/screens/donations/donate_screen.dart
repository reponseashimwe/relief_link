import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/disaster.dart';
import '../../components/buttons/custom_button.dart';
import '../../providers/auth_provider.dart' as app_provider;

class DonateScreen extends StatefulWidget {
  final Disaster disaster;
  final String organization;

  const DonateScreen({
    Key? key,
    required this.disaster,
    required this.organization,
  }) : super(key: key);

  @override
  _DonateScreenState createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  int selectedAmount = 50; // Default donation amount
  bool hideName = false;
  bool addSupportWords = false;
  final TextEditingController supportWordsController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    supportWordsController.dispose();
    super.dispose();
  }

  Future<void> _handleDonation() async {
    setState(() {
      isLoading = true;
    });

    try {
      final authProvider =
          Provider.of<app_provider.AuthProvider>(context, listen: false);
      final user = authProvider.currentUser!;

      // Simulate payment processing (replace with actual payment gateway integration)
      await Future.delayed(
          const Duration(seconds: 2)); // Simulate network delay

      // Save donation to Firestore
      await FirebaseFirestore.instance.collection('donations').add({
        'disasterId': widget.disaster.id,
        'userId': user.uid,
        'userName': hideName ? 'Anonymous' : (user.displayName ?? 'Anonymous'),
        'amount': selectedAmount,
        'supportWords': addSupportWords ? supportWordsController.text : null,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update the amountRaised in the disaster document (if stored in Firestore)
      // For now, this is a placeholder since amountRaised is mock data
      // await FirebaseFirestore.instance
      //     .collection('disasters')
      //     .doc(widget.disaster.id)
      //     .update({
      //       'amountRaised': FieldValue.increment(selectedAmount),
      //     });

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Thank you for your donation!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to DonationDetailScreen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donate'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campaign Info
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: widget.disaster.images.isNotEmpty
                        ? widget.disaster.images[0]
                        : 'https://via.placeholder.com/150',
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.disaster.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By ${widget.organization}',
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
            const SizedBox(height: 24),
            // Donation Amount
            Center(
              child: Text(
                '\$${selectedAmount.toString()},00',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Predefined Amount Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [50, 100, 150, 200, 250].map((amount) {
                return ChoiceChip(
                  label: Text('\$$amount'),
                  selected: selectedAmount == amount,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        selectedAmount = amount;
                      });
                    }
                  },
                  selectedColor: Colors.green,
                  backgroundColor: Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color:
                        selectedAmount == amount ? Colors.white : Colors.black,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Donation Impact Message
            Row(
              children: [
                const Icon(
                  Icons.favorite,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You support REBUILDING LIVES After Disasters your donation means a lot!',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You’re donating to verified organiser, the money will be guarantee by WEcare.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Hide Name Checkbox
            CheckboxListTile(
              title: const Text('Hide my name from the donations list'),
              value: hideName,
              onChanged: (value) {
                setState(() {
                  hideName = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Colors.green,
            ),
            // Add Words of Support Checkbox
            CheckboxListTile(
              title: const Text('Add words of support'),
              value: addSupportWords,
              onChanged: (value) {
                setState(() {
                  addSupportWords = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Colors.green,
            ),
            // Words of Support Text Field (visible if checkbox is checked)
            if (addSupportWords)
              TextField(
                controller: supportWordsController,
                decoration: const InputDecoration(
                  hintText: 'Add words of support here',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            const SizedBox(height: 24),
            // Pay Now Button
            CustomButton(
              child: const Text('Pay Now'),
              onPressed: _handleDonation,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
