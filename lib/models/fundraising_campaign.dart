import 'package:cloud_firestore/cloud_firestore.dart';

class FundraisingCampaign {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final String organizationName;
  final double targetAmount;
  final double currentAmount;
  final int daysLeft;
  final DateTime createdAt;
  final DateTime endDate;
  final String disasterId; // Reference to the disaster this campaign is for
  final List<Donation> donations;
  final bool featured;

  FundraisingCampaign({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.organizationName,
    required this.targetAmount,
    required this.currentAmount,
    required this.daysLeft,
    required this.createdAt,
    required this.endDate,
    required this.disasterId,
    required this.donations,
    this.featured = false,
  });

  // Factory constructor to create a FundraisingCampaign from a Firestore document
  factory FundraisingCampaign.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAt = (data['createdAt'] as Timestamp).toDate();
    final endDate = (data['endDate'] as Timestamp).toDate();

    // Calculate days left
    final now = DateTime.now();
    final daysLeft = endDate.difference(now).inDays;

    // Parse donations if they exist
    List<Donation> donations = [];
    if (data['donations'] != null) {
      donations = (data['donations'] as List)
          .map((item) => Donation.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    return FundraisingCampaign(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Disaster',
      imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/300x200',
      organizationName: data['organizationName'] ?? 'Wecare Foundation',
      targetAmount: (data['targetAmount'] ?? 0.0).toDouble(),
      currentAmount: (data['currentAmount'] ?? 0.0).toDouble(),
      daysLeft: daysLeft > 0 ? daysLeft : 0,
      createdAt: createdAt,
      endDate: endDate,
      disasterId: data['disasterId'] ?? '',
      donations: donations,
      featured: data['featured'] ?? false,
    );
  }

  // Constructor to create a FundraisingCampaign from a Map
  factory FundraisingCampaign.fromMap(Map<String, dynamic> data) {
    final createdAt = (data['createdAt'] as Timestamp).toDate();
    final endDate = (data['endDate'] as Timestamp).toDate();

    // Calculate days left
    final now = DateTime.now();
    final daysLeft = endDate.difference(now).inDays;

    // Parse donations if they exist
    List<Donation> donations = [];
    if (data['donations'] != null) {
      donations = (data['donations'] as List)
          .map((item) => Donation.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    return FundraisingCampaign(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Disaster',
      imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/300x200',
      organizationName: data['organizationName'] ?? 'Relief Link',
      targetAmount: (data['targetAmount'] ?? 0.0).toDouble(),
      currentAmount: (data['currentAmount'] ?? 0.0).toDouble(),
      daysLeft: daysLeft > 0 ? daysLeft : 0,
      createdAt: createdAt,
      endDate: endDate,
      disasterId: data['disasterId'] ?? '',
      donations: donations,
      featured: data['featured'] ?? false,
    );
  }

  // Convert this FundraisingCampaign to a Map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'organizationName': organizationName,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'endDate': Timestamp.fromDate(endDate),
      'disasterId': disasterId,
      'donations': donations.map((donation) => donation.toMap()).toList(),
      'featured': featured,
    };
  }
}

class Donation {
  final String id;
  final String userId;
  final String? userName;
  final String? userPhotoUrl;
  final double amount;
  final String? message;
  final DateTime donatedAt;
  final bool anonymous;

  Donation({
    required this.id,
    required this.userId,
    this.userName,
    this.userPhotoUrl,
    required this.amount,
    this.message,
    required this.donatedAt,
    this.anonymous = false,
  });

  factory Donation.fromMap(Map<String, dynamic> data) {
    return Donation(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'],
      userPhotoUrl: data['userPhotoUrl'],
      amount: (data['amount'] ?? 0.0).toDouble(),
      message: data['message'],
      donatedAt: (data['donatedAt'] as Timestamp).toDate(),
      anonymous: data['anonymous'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'amount': amount,
      'message': message,
      'donatedAt': Timestamp.fromDate(donatedAt),
      'anonymous': anonymous,
    };
  }
} 