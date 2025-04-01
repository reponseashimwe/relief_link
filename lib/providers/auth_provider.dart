import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  static const String _authKey = 'is_authenticated';
  static const String _roleKey = 'user_role';
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
        await _fetchUserRole();
        notifyListeners();
        return true;
      }
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

        // Pass service if this is an emergency service user
        await _saveUserToFirestore(userCredential.user!, role,
            service: role == UserRole.emergencyService ? service : null);

        _userRole = role;
        await _prefs?.setString(_roleKey, role.name);
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

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!, UserRole.user);
      }

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveUserToFirestore(User user, UserRole role,
      {EmergencyService? service}) async {
    // Base user data all users need
    final userData = {
      'name': user.displayName,
      'email': user.email,
      'photoURL': user.photoURL,
      'role': role.name,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Add service-specific fields if this is an emergency service user
    if (role == UserRole.emergencyService && service != null) {
      userData['serviceId'] = service.id;
      userData['serviceName'] = service.name;
      userData['serviceRole'] = service.id; // Using ID for consistency
    }

    // Save to Firestore
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userData, SetOptions(merge: true));

    // Also create emergency_services document if needed
    if (role == UserRole.emergencyService && service != null) {
      await _firestore
          .collection(Collections.emergencyServices)
          .doc(service.id)
          .set({
        'userId': user.uid,
        'name': service.name,
        'role': service.id,
        'description': service.description,
        'phoneNumber': service.phoneNumber,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    _userRole = role;
    if (_prefs != null) {
      await _prefs!.setString(_roleKey, role.name);
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

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _auth.signOut();
      _user = null;
      _userRole = UserRole.user;
      await _prefs?.remove(_roleKey);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ignore: unused_element
  Future<void> _updateAuthStatus(bool isAuth) async {
    if (_prefs != null) {
      await _prefs!.setBool(_authKey, isAuth);
    }
  }
}
