import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String userId;
  final String displayName;
  final int age;
  final String description;
  final DateTime lastUpdated;

  UserProfile({
    required this.userId,
    required this.displayName,
    required this.age,
    required this.description,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'age': age,
      'description': description,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return UserProfile(
      userId: data['userId'] ?? '',
      displayName: data['displayName'] ?? '',
      age: data['age'] ?? 0,
      description: data['description'] ?? '',
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  UserProfile copyWith({String? displayName, int? age, String? description}) {
    return UserProfile(
      userId: this.userId,
      displayName: displayName ?? this.displayName,
      age: age ?? this.age,
      description: description ?? this.description,
      lastUpdated: DateTime.now(),
    );
  }
}
