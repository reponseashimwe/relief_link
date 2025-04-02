import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerEvent {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String imageUrl;
  final int currentVolunteers;
  final int targetVolunteers;
  final List<String> photoUrls;

  VolunteerEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.imageUrl,
    required this.currentVolunteers,
    required this.targetVolunteers,
    required this.photoUrls,
  });

  factory VolunteerEvent.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return VolunteerEvent(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'] ?? '',
      currentVolunteers: data['currentVolunteers'] ?? 0,
      targetVolunteers: data['targetVolunteers'] ?? 0,
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'imageUrl': imageUrl,
      'currentVolunteers': currentVolunteers,
      'targetVolunteers': targetVolunteers,
      'photoUrls': photoUrls,
    };
  }
}