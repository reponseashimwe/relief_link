import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AuthProvider extends ChangeNotifier {
  static const String _authKey = 'is_authenticated';
  static const String _roleKey = 'user_role';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  SharedPreferences? _prefs;
  bool _isLoading = false;
  String? _error;
  User? _user;
  UserRole _userRole = UserRole.user;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user == null) {
        _userRole = UserRole.user;
      } else {
        await _fetchUserRole();
        
        // Check if this is a seeded account or test account - set onboarding completed automatically
        if (user.email?.endsWith('@relieflink.com') == true) {
          // Set onboarding completed for test accounts
          try {
            final doc = await _firestore.collection('users').doc(user.uid).get();
            if (doc.exists) {
              final userData = doc.data();
              if (userData != null && userData['onboardingCompleted'] != true) {
                await setOnboardingCompleted();
              }
            }
          } catch (e) {
            print('Error setting onboarding for test account: $e');
          }
        }
      }
      notifyListeners();
    });
  }

  Future<void> _fetchUserRole() async {
    try {
      final roleStr = _prefs?.getString(_roleKey);
      if (roleStr != null) {
        _userRole = UserRole.values.firstWhere(
          (role) => role.name == roleStr,
          orElse: () => UserRole.user,
        );
      } else {
        final userDoc =
            await _firestore.collection('users').doc(_user!.uid).get();
        if (userDoc.exists) {
          final roleStr = userDoc.data()?['role'] as String?;
          if (roleStr != null) {
            _userRole = UserRole.values.firstWhere(
              (role) => role.name == roleStr,
              orElse: () => UserRole.user,
            );
            await _prefs?.setString(_roleKey, _userRole.name);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      _userRole = UserRole.user;
    }
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _user;
  UserRole get userRole => _userRole;
  bool get isAuthenticated => _user != null;
  bool get isEmailVerified => _user?.emailVerified ?? false;
  bool get isEmergencyService => _userRole == UserRole.emergencyService;
  bool get isAdmin => _userRole == UserRole.admin;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }
  
  void clearError() {
    _setError(null);
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        _user = userCredential.user;
        
        // Get user data from Firestore
        final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
        final userData = userDoc.exists ? userDoc.data() : null;
        
        // Skip email verification check for test accounts from relieflink.com domain
        // or if the Firestore document has emailVerified=true
        final bool isTestAccount = email.endsWith('@relieflink.com');
        final bool isMarkedVerified = userData != null && userData['emailVerified'] == true;
        
        if (!_user!.emailVerified && !isTestAccount && !isMarkedVerified) {
          _setError('email-not-verified');
          await signOut();
          return false;
        }
        
        await _fetchUserRole();
        
        // Automatically set onboarding as completed for ALL users upon successful login
        if (_prefs == null) {
          _prefs = await SharedPreferences.getInstance();
        }
        
        // Save to local preferences
        await _prefs?.setBool(_onboardingCompletedKey, true);
        
        // Also save to Firestore
        try {
          await _firestore.collection('users').doc(_user!.uid).set({
            'onboardingCompleted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          print('Error updating onboarding status in Firestore: $e');
        }
        
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'invalid-email';
          break;
        case 'user-not-found':
          errorMessage = 'user-not-found';
          break;
        case 'wrong-password':
          errorMessage = 'wrong-password';
          break;
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          errorMessage = 'invalid-credential';
          break;
        case 'too-many-requests':
          errorMessage = 'too-many-requests';
          break;
        default:
          errorMessage = e.code;
          break;
      }
      
      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp(String name, String email, String password,
      {UserRole role = UserRole.user, EmergencyService? service}) async {
    try {
      _setLoading(true);
      _setError(null);

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        
        // Send email verification
        await userCredential.user!.sendEmailVerification();

        // Pass service if this is an emergency service user
        await _saveUserToFirestore(userCredential.user!, role,
            service: role == UserRole.emergencyService ? service : null);

        _userRole = role;
        await _prefs?.setString(_roleKey, role.name);
        
        // Sign out after registration to force email verification
        await signOut();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';

      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists for this email';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
      }

      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      _setLoading(true);
      _setError(null);
      
      if (_user != null && !_user!.emailVerified) {
        await _user!.sendEmailVerification();
      }
    } catch (e) {
      _setError('Failed to send verification email');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';

      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email';
          break;
      }

      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
      if (gUser == null) {
        _setError('Google sign in was cancelled');
        return false;
      }

      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        _user = userCredential.user;
        
        // Check if this is a new user
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          await _saveUserToFirestore(_user!, UserRole.user);
          _userRole = UserRole.user;
          await _prefs?.setString(_roleKey, UserRole.user.name);
        } else {
          await _fetchUserRole();
        }
        
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to sign in with Google');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _userRole = UserRole.user;
      await _prefs?.clear();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to sign out');
      return false;
    }
  }

  Future<void> _saveUserToFirestore(User user, UserRole role, {EmergencyService? service}) async {
    try {
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName,
        'role': role.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (service != null) {
        userData['service'] = service.name;
      }

      await _firestore.collection('users').doc(user.uid).set(userData);
    } catch (e) {
      debugPrint('Error saving user to Firestore: $e');
    }
  }

  Future<void> updateProfile({String? name, String? photoURL}) async {
    try {
      _setLoading(true);
      _setError(null);

      if (currentUser == null) throw Exception('No user logged in');

      if (name != null) {
        await currentUser!.updateDisplayName(name);
      }

      if (photoURL != null) {
        await currentUser!.updatePhotoURL(photoURL);
      }

      // Update Firestore
      await _firestore.collection('users').doc(currentUser!.uid).update({
        if (name != null) 'name': name,
        if (photoURL != null) 'photoURL': photoURL,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword({
    required String currentPassword, 
    required String newPassword
  }) async {
    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }
      
      // Get credential for reauthentication
      final email = user.email;
      if (email == null) {
        throw Exception('Current user has no email associated with account');
      }
      
      // Create credentials
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      
      // Reauthenticate user
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
      
      return true;
    } catch (e) {
      print('Error changing password: $e');
      
      // Provide more user-friendly error messages
      if (e.toString().contains('wrong-password')) {
        throw Exception('The current password is incorrect');
      } else if (e.toString().contains('requires-recent-login')) {
        throw Exception('Please log in again before changing your password');
      } else {
        throw Exception('Failed to change password: ${e.toString()}');
      }
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }
      
      // Get additional user data from Firestore
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      
      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;
        return {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          ...userData,
        };
      } else {
        return {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
        };
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<bool> updateUserData(Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }
      
      // Update data in Firestore
      await _firestore.collection('users').doc(user.uid).set(
        data,
        SetOptions(merge: true),
      );
      
      // If the update includes display name or photo URL, update the auth profile too
      if (data.containsKey('displayName') || data.containsKey('photoURL')) {
        await user.updateProfile(
          displayName: data['displayName'],
          photoURL: data['photoURL'],
        );
      }
      
      // Update UserModel if needed
      if (_user != null) {
        // Update the local user reference with Firebase Auth user
        _user = _auth.currentUser;
        
        // Update UI
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      print('Error updating user data: $e');
      return false;
    }
  }

  Future<bool> updateUserProfile({String? name}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }
      
      if (name != null) {
        await user.updateDisplayName(name);
        
        // Update in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'name': name,
          'displayName': name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  Future<bool> updateProfilePicture(File imageFile) async {
    try {
      _setLoading(true);
      
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }
      
      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child('${user.uid}.jpg');
      
      // Upload the file
      final uploadTask = await storageRef.putFile(imageFile);
      
      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      // Update user profile
      await user.updatePhotoURL(downloadUrl);
      
      // Update in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'photoURL': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating profile picture: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> removeProfilePicture() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }
      
      // Remove photo URL from user profile
      await user.updatePhotoURL(null);
      
      // Remove from Firebase Storage if exists
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_photos')
            .child('${user.uid}.jpg');
        await storageRef.delete();
      } catch (e) {
        // Ignore if file doesn't exist
        print('Storage file may not exist: $e');
      }
      
      // Update in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'photoURL': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error removing profile picture: $e');
      return false;
    }
  }

  // ignore: unused_element
  Future<void> _updateAuthStatus(bool isAuth) async {
    if (_prefs != null) {
      await _prefs!.setBool(_authKey, isAuth);
    }
  }

  Future<bool> isOnboardingCompleted() async {
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      
      // First check if we have a local preference saved
      final bool? isCompleted = _prefs?.getBool(_onboardingCompletedKey);
      if (isCompleted == true) {
        return true;
      }
      
      // If not found locally, check Firestore
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final userData = doc.data();
          // Check if onboardingCompleted exists and is true
          if (userData != null && userData['onboardingCompleted'] == true) {
            // Save to local preferences for faster access next time
            await _prefs?.setBool(_onboardingCompletedKey, true);
            return true;
          }
          
          // Special case: For seeded accounts or test accounts, auto-complete onboarding
          if (user.email?.endsWith('@relieflink.com') == true || 
              (userData != null && userData['emailVerified'] == true)) {
            await setOnboardingCompleted();
            return true;
          }
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking onboarding status: $e');
      return false;
    }
  }
  
  Future<void> setOnboardingCompleted() async {
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      
      // Save to local preferences
      await _prefs?.setBool(_onboardingCompletedKey, true);
      
      // Also save to Firestore if user is logged in
      final user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore.collection('users').doc(user.uid).update({
            'onboardingCompleted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          print('Error updating Firestore with onboarding status: $e');
          // Try to create the document if it doesn't exist
          await _firestore.collection('users').doc(user.uid).set({
            'onboardingCompleted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      print('Error setting onboarding completed: $e');
    }
  }
}
