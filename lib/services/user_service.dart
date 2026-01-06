// File: lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create user profile
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'hasCompletedAssessment': false,
        'hasSetGoals': false,
      });
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Mark assessment as completed
  Future<void> markAssessmentCompleted(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'hasCompletedAssessment': true,
        'assessmentCompletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking assessment completed: $e');
      rethrow;
    }
  }

  // Mark goals as set
  Future<void> markGoalsSet(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'hasSetGoals': true,
        'goalsSetAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking goals set: $e');
      rethrow;
    }
  }

  // Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      return data?['hasCompletedAssessment'] == true;
    } catch (e) {
      print('Error checking onboarding: $e');
      return false;
    }
  }
}
