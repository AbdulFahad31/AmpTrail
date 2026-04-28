import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class UserService {
  // Singleton Pattern
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'stations31',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // In-memory cache
  Map<String, dynamic>? _cachedProfile;
  DateTime? _lastProfileFetch;
  final Duration _cacheDuration = const Duration(minutes: 10);

  Future<void> saveUserProfile(String name) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final identifier = user.phoneNumber ?? user.email;
      if (identifier == null) return;

      debugPrint("DEBUG: Saving user profile to Firestore for $identifier");
      
      final Map<String, dynamic> data = {
        'name': name,
        'phone': user.phoneNumber,
        'email': user.email,
        'uid': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(identifier).set(
        data, 
        SetOptions(merge: true)
      );
      
      // Update cache
      _cachedProfile = data;
      _lastProfileFetch = DateTime.now();

      debugPrint("DEBUG: User profile saved successfully.");
    } catch (e) {
      debugPrint("ERROR: Error saving user profile: $e");
    }
  }

  Future<Map<String, dynamic>?> getUserProfile({bool forceRefresh = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final identifier = user.phoneNumber ?? user.email;
      if (identifier == null) return null;

      if (!forceRefresh && _cachedProfile != null && _lastProfileFetch != null) {
        if (DateTime.now().difference(_lastProfileFetch!) < _cacheDuration) {
          return _cachedProfile;
        }
      }

      final doc = await _firestore.collection('users').doc(identifier).get(
        const GetOptions(source: Source.serverAndCache),
      );
      
      if (doc.exists) {
        _cachedProfile = doc.data();
        _lastProfileFetch = DateTime.now();
      }
      
      return doc.data();
    } catch (e) {
      debugPrint("ERROR: Error fetching user profile: $e");
      if (_cachedProfile != null) return _cachedProfile;
      return null;
    }
  }
}
