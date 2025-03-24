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
  String _userRole = UserRole.user;

  AuthProvider() {
    _initPrefs();
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _updateAuthStatus(true);
        await _fetchUserRole(user.uid);
      } else {
        await _updateAuthStatus(false);
        _userRole = UserRole.user;
      }
      notifyListeners();
    });
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _userRole = _prefs?.getString(_roleKey) ?? UserRole.user;
    notifyListeners();
  }

  Future<void> _updateAuthStatus(bool isAuth) async {
    if (_prefs != null) {
      await _prefs!.setBool(_authKey, isAuth);
    }
  }

  Future<void> _fetchUserRole(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data()!.containsKey('role')) {
        _userRole = userDoc.data()!['role'];
        if (_prefs != null) {
          await _prefs!.setString(_roleKey, _userRole);
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _auth.currentUser;
  String get userRole => _userRole;
  bool get isAuthenticated => _auth.currentUser != null || (_prefs?.getBool(_authKey) == true);
  bool get isEmergencyService => 
      _userRole == UserRole.ambulance || 
      _userRole == UserRole.hospital || 
      _userRole == UserRole.police || 
      _userRole == UserRole.firefighter || 
      _userRole == UserRole.electricity || 
      _userRole == UserRole.hazmat;
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
      
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
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

  Future<bool> signUp(String name, String email, String password, {String role = UserRole.user}) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await userCredential.user?.updateDisplayName(name);
      
      // Save user data to Firestore
      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!, role);
      }
      
      return true;
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

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
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

  Future<void> _saveUserToFirestore(User user, String role) async {
    await _firestore.collection('users').doc(user.uid).set({
      'name': user.displayName,
      'email': user.email,
      'photoURL': user.photoURL,
      'role': role,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    _userRole = role;
    if (_prefs != null) {
      await _prefs!.setString(_roleKey, role);
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
    await _googleSignIn.signOut();
    await _auth.signOut();
    await _updateAuthStatus(false);
    if (_prefs != null) {
      await _prefs!.remove(_roleKey);
    }
    _userRole = UserRole.user;
    notifyListeners();
  }
} 