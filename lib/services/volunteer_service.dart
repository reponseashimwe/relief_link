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
      });

      return true;
    } catch (e) {
      print('Error joining volunteer event: $e');
      return false;
    }
  }
}