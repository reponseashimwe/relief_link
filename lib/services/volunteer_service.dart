import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/volunteer_event.dart';

class VolunteerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<VolunteerEvent>> getVolunteerEvents() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('volunteer_events')
          .orderBy('date')
          .get();

      return snapshot.docs
          .map((doc) => VolunteerEvent.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching volunteer events: $e');
      return [];
    }
  }

  Future<VolunteerEvent?> getVolunteerEventById(String id) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('volunteer_events')
          .doc(id)
          .get();

      if (doc.exists) {
        return VolunteerEvent.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching volunteer event: $e');
      return null;
    }
  }

  Future<String?> createVolunteerEvent({
    required String title,
    required String description,
    required String location,
    required DateTime date,
    required String imageUrl,
    required int targetVolunteers,
  }) async {
    try {
      final docRef = await _firestore.collection('volunteer_events').add({
        'title': title,
        'description': description,
        'location': location,
        'date': Timestamp.fromDate(date),
        'imageUrl': imageUrl,
        'currentVolunteers': 0,
        'targetVolunteers': targetVolunteers,
        'photoUrls': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Error creating volunteer event: $e');
      return null;
    }
  }

  Future<void> seedSampleEvents() async {
    final now = DateTime.now();
    
    final sampleEvents = [
      {
        'title': 'Providing flood disaster relief in Australia',
        'description': 'Join us in providing essential aid and support to communities affected by severe flooding in Australia. Your help can make a real difference.',
        'location': 'Sydney, Australia',
        'date': now,
        'imageUrl': 'https://images.unsplash.com/photo-1469571486292-0ba58a3f068b',
        'targetVolunteers': 50,
      },
      {
        'title': 'Helping Hands Supporting Tsunami Survivors',
        'description': 'Support survivors of the recent tsunami by providing medical aid, supplies, and reconstruction assistance.',
        'location': 'California, CA',
        'date': now.add(const Duration(days: 1)),
        'imageUrl': 'https://images.unsplash.com/photo-1603393518079-71d7c59e7717',
        'targetVolunteers': 30,
      },
      {
        'title': 'Rapid Response Action for Earthquake Relief',
        'description': 'Immediate assistance needed for earthquake victims. Help with rescue operations and emergency supplies distribution.',
        'location': 'Mexico City, Mexico',
        'date': now.add(const Duration(days: 2)),
        'imageUrl': 'https://images.unsplash.com/photo-1587502537745-84b86da1204f',
        'targetVolunteers': 40,
      },
      {
        'title': 'Hurricane Recovery Support Team',
        'description': 'Join our team helping communities rebuild after the devastating hurricane. Skills in construction and logistics are welcome.',
        'location': 'New Orleans, LA',
        'date': now.add(const Duration(days: 3)),
        'imageUrl': 'https://images.unsplash.com/photo-1556767576-5ec41e3239ea',
        'targetVolunteers': 25,
      },
    ];

    // Check if events already exist
    final existing = await _firestore.collection('volunteer_events').limit(1).get();
    if (existing.docs.isEmpty) {
      for (final event in sampleEvents) {
        await createVolunteerEvent(
          title: event['title'] as String,
          description: event['description'] as String,
          location: event['location'] as String,
          date: event['date'] as DateTime,
          imageUrl: event['imageUrl'] as String,
          targetVolunteers: event['targetVolunteers'] as int,
        );
      }
    }
  }

  Future<bool> joinVolunteerEvent({
    required String eventId,
    required String userId,
    required String fullName,
    required String email,
    required String phoneNumber,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final DocumentReference eventRef = _firestore.collection('volunteer_events').doc(eventId);
        final DocumentSnapshot eventDoc = await transaction.get(eventRef);

        if (!eventDoc.exists) {
          throw Exception('Event does not exist');
        }

        final currentVolunteers = eventDoc.get('currentVolunteers') as int;
        final targetVolunteers = eventDoc.get('targetVolunteers') as int;

        if (currentVolunteers >= targetVolunteers) {
          throw Exception('Event is full');
        }

        transaction.update(eventRef, {
          'currentVolunteers': currentVolunteers + 1,
        });

        final volunteerRef = _firestore
            .collection('volunteer_events')
            .doc(eventId)
            .collection('volunteers')
            .doc(userId);

        transaction.set(volunteerRef, {
          'fullName': fullName,
          'email': email,
          'phoneNumber': phoneNumber,
          'joinedAt': FieldValue.serverTimestamp(),
        });
        
        // Also create a record in volunteer_registrations collection for the profile screen
        final registrationRef = _firestore
            .collection('volunteer_registrations')
            .doc('${userId}_${eventId}');
            
        final eventData = eventDoc.data() as Map<String, dynamic>;
        
        transaction.set(registrationRef, {
          'userId': userId,
          'eventId': eventId,
          'fullName': fullName,
          'email': email,
          'phoneNumber': phoneNumber,
          'eventTitle': eventData['title'] ?? '',
          'eventLocation': eventData['location'] ?? '',
          'eventDate': eventData['date'],
          'registeredAt': FieldValue.serverTimestamp(),
        });
      });

      return true;
    } catch (e) {
      print('Error joining volunteer event: $e');
      return false;
    }
  }

  // Add a simple method to create a volunteer registration directly
  // This is helpful for testing or initial data population
  Future<bool> createVolunteerRegistration({
    required String eventId,
    required String userId,
    required Map<String, dynamic> eventData,
    required String fullName,
    required String email,
    String phoneNumber = '',
  }) async {
    try {
      // Create the registration document directly
      await _firestore
          .collection('volunteer_registrations')
          .doc('${userId}_${eventId}')
          .set({
        'userId': userId,
        'eventId': eventId,
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'eventTitle': eventData['title'] ?? '',
        'eventLocation': eventData['location'] ?? '',
        'eventDate': eventData['date'],
        'registeredAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error creating volunteer registration: $e');
      return false;
    }
  }
}