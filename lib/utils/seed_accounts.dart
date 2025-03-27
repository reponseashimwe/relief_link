import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

/// This class is used to seed initial user accounts for testing.
/// It should only be used in development environments.
class AccountSeeder {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Seed emergency service accounts
  static Future<void> seedEmergencyAccounts() async {
    // Admin account
    await _createUserIfNotExists(
      email: 'admin@relieflink.com',
      password: 'admin123',
      name: 'Admin User',
      role: UserRole.admin,
    );

    // Emergency service accounts
    await _createUserIfNotExists(
      email: 'medical@relieflink.com',
      password: 'medical123',
      name: 'Medical Services',
      role: UserRole.emergencyService,
    );

    await _createUserIfNotExists(
      email: 'police@relieflink.com',
      password: 'police123',
      name: 'Police Department',
      role: UserRole.emergencyService,
    );

    await _createUserIfNotExists(
      email: 'fire@relieflink.com',
      password: 'fire123',
      name: 'Fire Department',
      role: UserRole.emergencyService,
    );

    await _createUserIfNotExists(
      email: 'rescue@relieflink.com',
      password: 'rescue123',
      name: 'Rescue Team',
      role: UserRole.emergencyService,
    );

    await _createUserIfNotExists(
      email: 'hazmat@relieflink.com',
      password: 'hazmat123',
      name: 'HazMat Team',
      role: UserRole.emergencyService,
    );

    // Regular user account
    await _createUserIfNotExists(
      email: 'user@relieflink.com',
      password: 'user123',
      name: 'Regular User',
      role: UserRole.user,
    );
  }
  
  static Future<void> _createUserIfNotExists({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      // Check if user exists
      final userDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        // Create new user
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await userCredential.user?.updateDisplayName(name);

        // Save user data to Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'email': email,
          'role': role.name,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('Created account for $email with role ${role.name}');
      } else {
        print('Account already exists for $email');
      }
    } catch (e) {
      print('Error creating account for $email: $e');
    }
  }
}

// Example usage:
// final seeder = AccountSeeder();
// seeder.seedEmergencyAccounts(); 