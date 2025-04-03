import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/fundraising_campaign.dart';
import '../../providers/auth_provider.dart';

class DonateScreen extends StatefulWidget {
  final FundraisingCampaign campaign;

  const DonateScreen({
    Key? key,
    required this.campaign,
  }) : super(key: key);

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  final TextEditingController _amountController = TextEditingController(text: '50');
  bool _isAnonymous = false;
  bool _sendingDonation = false;
  final List<double> _presetAmounts = [50, 100, 150, 200, 250];
  
  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
  
  void _selectAmount(double amount) {
    setState(() {
      _amountController.text = amount.toString();
    });
  }
  
  Future<void> _makeDonation() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    
    setState(() {
      _sendingDonation = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need to be logged in to donate')),
        );
        setState(() {
          _sendingDonation = false;
        });
        return;
      }
      
      // Create new donation object
      final donation = Donation(
        id: const Uuid().v4(),
        userId: user.uid,
        userName: _isAnonymous ? null : user.displayName,
        userPhotoUrl: _isAnonymous ? null : user.photoURL,
        amount: amount,
        message: null,
        donatedAt: DateTime.now(),
        anonymous: _isAnonymous,
      );
      
      // Update campaign in Firestore
      final campaignRef = FirebaseFirestore.instance
          .collection('fundraising_campaigns')
          .doc(widget.campaign.id);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(campaignRef);
        
        if (!snapshot.exists) {
          throw Exception('Campaign does not exist!');
        }
        
        final data = snapshot.data()!;
        final currentAmount = (data['currentAmount'] ?? 0.0) + amount;
        final donations = List<dynamic>.from(data['donations'] ?? []);
        donations.add(donation.toMap());
        
        transaction.update(campaignRef, {
          'currentAmount': currentAmount,
          'donations': donations,
        });
      });
      
      // Show appreciation message
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Thank You!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F7B40),
              ),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite,
                  color: Color(0xFF2F7B40),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your donation of \$${amount.toStringAsFixed(0)} will help ${widget.campaign.title}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Together we can make a difference!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to detail screen
                    Navigator.pop(context); // Go back to listing screen
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF2F7B40),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    minimumSize: const Size(200, 50),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() {
        _sendingDonation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Donate',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campaign info
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.campaign.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 40, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.campaign.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'By ${widget.campaign.organizationName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${widget.campaign.daysLeft} days left',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Donation progress
              Row(
                children: [
                  Text(
                    '\$${widget.campaign.currentAmount.toInt()}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F7B40),
                    ),
                  ),
                  Text(
                    ' of \$${widget.campaign.targetAmount.toInt()}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${((widget.campaign.currentAmount / widget.campaign.targetAmount) * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (widget.campaign.currentAmount / widget.campaign.targetAmount).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  color: const Color(0xFF2F7B40),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 32),
              
              // Donation amount
              const Text(
                'Select Amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Preset amounts
              Wrap(
                spacing: 8,
                runSpacing: 12,
                children: _presetAmounts.map((amount) => GestureDetector(
                  onTap: () => _selectAmount(amount),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: double.tryParse(_amountController.text) == amount
                            ? const Color(0xFF2F7B40)
                            : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      color: double.tryParse(_amountController.text) == amount
                          ? const Color(0xFF2F7B40)
                          : Colors.white,
                    ),
                    child: Text(
                      '\$${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: double.tryParse(_amountController.text) == amount
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),
              
              // Custom amount
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'Enter Custom Amount',
                  prefixText: '\$',
                  prefixStyle: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Privacy option
              Row(
                children: [
                  Checkbox(
                    value: _isAnonymous,
                    onChanged: (value) {
                      setState(() {
                        _isAnonymous = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF2F7B40),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Donate anonymously',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Donate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sendingDonation ? null : _makeDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: _sendingDonation
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Donate Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
} 