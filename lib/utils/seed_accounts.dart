import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

/// This class is used to seed initial user accounts for testing.
/// It should only be used in development environments.
class AccountSeeder {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Seed emergency service accounts
  Future<void> seedEmergencyAccounts() async {
    await _createUserIfNotExists(
      email: 'admin@relieflink.com',
      password: 'Admin123!',
      name: 'Admin',
      role: UserRole.admin,
    );
    
    await _createUserIfNotExists(
      email: 'ambulance@relieflink.com',
      password: 'Ambulance123!',
      name: 'Ambulance Service',
      role: UserRole.ambulance,
    );
    
    await _createUserIfNotExists(
      email: 'hospital@relieflink.com',
      password: 'Hospital123!',
      name: 'Hospital Service',
      role: UserRole.hospital,
    );
    
    await _createUserIfNotExists(
      email: 'police@relieflink.com',
      password: 'Police123!',
      name: 'Police Department',
      role: UserRole.police,
    );
    
    await _createUserIfNotExists(
      email: 'firefighter@relieflink.com',
      password: 'Fire123!',
      name: 'Fire Department',
      role: UserRole.firefighter,
    );
    
    await _createUserIfNotExists(
      email: 'electricity@relieflink.com',
      password: 'Electric123!',
      name: 'Electricity Service',
      role: UserRole.electricity,
    );
    
    await _createUserIfNotExists(
      email: 'hazmat@relieflink.com',
      password: 'Hazmat123!',
      name: 'HazMat Team',
      role: UserRole.hazmat,
    );
    
    await _createUserIfNotExists(
      email: 'user@relieflink.com',
      password: 'User123!',
      name: 'Regular User',
      role: UserRole.user,
    );
  }
  
  Future<void> _createUserIfNotExists({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      // Check if user already exists
      final result = await _auth.fetchSignInMethodsForEmail(email);
      if (result.isNotEmpty) {
        print('User $email already exists');
        return;
      }
      
      // Create user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(name);
      
      // Save to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('Created user $email with role $role');
    } catch (e) {
      print('Error creating user $email: $e');
    }
  }
}

// Example usage:
// final seeder = AccountSeeder();
// seeder.seedEmergencyAccounts(); 