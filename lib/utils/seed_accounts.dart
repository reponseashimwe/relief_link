import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import 'package:flutter/foundation.dart';

/// This class is used to seed initial user accounts for testing.
/// It should only be used in development environments.
class AccountSeeder {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a single emergency service user if it doesn't exist
  static Future<void> _createEmergencyServiceUser({
    required String email,
    required String password,
    required String name,
    required EmergencyService service,
  }) async {
    try {
      // Better way to check if user exists - check Auth first
      try {
        final methods = await _auth.fetchSignInMethodsForEmail(email);
        if (methods.isNotEmpty) {
          debugPrint(
              'User $email already exists in Authentication, skipping creation');
          return;
        }
      } catch (e) {
        debugPrint('Error checking user in Auth: $e');
      }

      // Also check Firestore as a secondary verification
      final existingUser = await _firestore
          .collection(Collections.users)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        debugPrint(
            'User $email already exists in Firestore, skipping creation');
        return;
      }

      debugPrint('Creating emergency service user: $email');

      // Create the user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);
      
      // Save user data to Firestore
      await _firestore
          .collection(Collections.users)
          .doc(userCredential.user!.uid)
          .set({
        'name': name,
        'email': email,
        'role': UserRole.emergencyService.name,
        'serviceId': service.id,
        'serviceName': service.name,
        'serviceRole': service.id,
        'emailVerified': true,  // Mark as verified in Firestore
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create emergency service association
      await _firestore
          .collection(Collections.emergencyServices)
          .doc(service.id)
          .set({
        'userId': userCredential.user!.uid,
        'name': service.name,
        'role': service.id,
        'description': service.description,
        'phoneNumber': service.phoneNumber,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Created emergency service: $email');
      
      // Special handling for test users in development - sign in and get ID token
      // to refresh the emailVerified status (this is a workaround)
      if (kDebugMode) {
        try {
          // Log them in once to get an ID token
          await _auth.signInWithEmailAndPassword(email: email, password: password);
          
          // Force token refresh - this helps with emailVerified status in some cases
          await _auth.currentUser?.getIdToken(true);
          
          debugPrint('Signed in seeded account to refresh token: $email');
          
          // Sign out afterward to return to clean state
          await _auth.signOut();
          debugPrint('Signed out after token refresh: $email');
        } catch (e) {
          debugPrint('Error during token refresh process: $e');
        }
      }
    } catch (e) {
      debugPrint('Error creating emergency service account for $email: $e');
    }
  }

  /// Seed all emergency service accounts
  static Future<void> seedEmergencyAccounts() async {
    try {
      debugPrint('Starting to seed emergency accounts...');

      // Create accounts for each emergency service
      for (final service in EmergencyService.services) {
        await _createEmergencyServiceUser(
          email: '${service.id}@relieflink.com',
          password: '${service.id}123',
          name: service.name,
          service: service,
        );
      }

      // Create admin account
      await _createUserIfNotExists(
        email: 'admin@relieflink.com',
        password: 'admin123',
        name: 'Admin User',
        role: UserRole.admin,
      );

      debugPrint('Successfully completed seeding all emergency accounts');
    } catch (e) {
      debugPrint('Error in seedEmergencyAccounts: $e');
      rethrow;
    }
  }

  /// Helper method to create regular users
  static Future<void> _createUserIfNotExists({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      // Check if user exists
      final existingUser = await _firestore
          .collection(Collections.users)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        debugPrint('User $email already exists');
        return;
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);

      await _firestore
          .collection(Collections.users)
          .doc(userCredential.user!.uid)
          .set({
        'name': name,
        'email': email,
        'role': role.name,
        'emailVerified': true,  // Mark as verified in Firestore
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Created user account for $email');
      
      // Special handling for test users in development - sign in and get ID token
      // to refresh the emailVerified status (this is a workaround)
      if (kDebugMode) {
        try {
          // Log them in once to get an ID token
          await _auth.signInWithEmailAndPassword(email: email, password: password);
          
          // Force token refresh - this helps with emailVerified status in some cases
          await _auth.currentUser?.getIdToken(true);
          
          debugPrint('Signed in seeded account to refresh token: $email');
          
          // Sign out afterward to return to clean state
          await _auth.signOut();
          debugPrint('Signed out after token refresh: $email');
        } catch (e) {
          debugPrint('Error during token refresh process: $e');
        }
      }
    } catch (e) {
      debugPrint('Error creating user account for $email: $e');
    }
  }
}

// Example usage:
// final seeder = AccountSeeder();
// seeder.seedEmergencyAccounts();
