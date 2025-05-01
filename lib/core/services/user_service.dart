import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user profile
  Stream<UserProfile?> getUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    });
  }

  // Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    await _firestore
        .collection('users')
        .doc(profile.userId)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  // Create initial user profile
  Future<void> createUserProfile(String userId, String? displayName) async {
    final profile = UserProfile(
      userId: userId,
      displayName: displayName ?? 'User',
      age: 0,
      description: '',
      lastUpdated: DateTime.now(),
    );
    await _firestore.collection('users').doc(userId).set(profile.toMap());
  }
}
