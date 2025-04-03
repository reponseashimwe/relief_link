import 'package:cloud_firestore/cloud_firestore.dart';

class Disaster {
  final String id;
  final String title;
  final String description;
  final String location;
  final List<String> images;
  final GeoPoint coordinates;
  final String category;
  final String userId;
  final String userName;
  final DateTime createdAt;
  final bool isVerified;
  final String type;
  final String severity;
  
  String get imageUrl => images.isNotEmpty ? images[0] : '';

  Disaster({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.images,
    required this.coordinates,
    required this.category,
    required this.userId,
    required this.userName,
    required this.createdAt,
    this.isVerified = false,
    this.type = 'Other',
    this.severity = 'Medium',
  });

  factory Disaster.fromMap(Map<String, dynamic> map, String id) {
    return Disaster(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      coordinates: map['coordinates'] ?? const GeoPoint(0, 0),
      category: map['category'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isVerified: map['isVerified'] ?? false,
      type: map['type'] ?? 'Other',
      severity: map['severity'] ?? 'Medium',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'images': images,
      'coordinates': coordinates,
      'category': category,
      'userId': userId,
      'userName': userName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVerified': isVerified,
      'type': type,
      'severity': severity,
    };
  }
} 