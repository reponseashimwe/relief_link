import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> createCommunityPost({
  required String title,
  required String description,
  required String type,
  required String urgency,
  required Map<String, dynamic> location,
  List<String>? media,
}) async {
  try {
    // Get the current user (assuming Firebase Auth is set up)
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    // Reference to the community_posts collection
    CollectionReference posts =
        FirebaseFirestore.instance.collection('community_posts');

    // Add a new document with auto-generated ID
    await posts.add({
      'title': title,
      'description': description,
      'userId': user.uid, // From Firebase Auth
      'userName': 'Jean-Pierre', // Fetch from user profile (or hardcode for now)
      'userRole': 'Responder', // Fetch from user profile
      'timestamp': FieldValue.serverTimestamp(), // Firestore server timestamp
      'type': type,
      'urgency': urgency,
      'location': location,
      'media': media ?? [],
      'likes': 0, // Initial likes
      'status': 'Open',
      'comments': [], // Empty comments array initially
    });
  } catch (e) {
    print("Error creating post: $e");
    throw e;
  }
}