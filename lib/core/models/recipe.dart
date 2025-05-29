import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final String imageUrl;
  final String userId;
  final String userName;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final List<String> categories;
  final int cookingTime; // in minutes
  final int servings;
  final String difficulty; // 'Easy', 'Medium', 'Hard'

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.imageUrl,
    required this.userId,
    required this.userName,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    required this.categories,
    required this.cookingTime,
    required this.servings,
    required this.difficulty,
  });

  // Convert Recipe to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'imageUrl': imageUrl,
      'userId': userId,
      'userName': userName,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'comments': comments,
      'categories': categories,
      'cookingTime': cookingTime,
      'servings': servings,
      'difficulty': difficulty,
    };
  }

  // Create Recipe from Firestore Document
  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Recipe(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      ingredients: List<String>.from(data['ingredients'] ?? []),
      instructions: List<String>.from(data['instructions'] ?? []),
      imageUrl: data['imageUrl'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      categories: List<String>.from(data['categories'] ?? []),
      cookingTime: data['cookingTime'] ?? 0,
      servings: data['servings'] ?? 1,
      difficulty: data['difficulty'] ?? 'Medium',
    );
  }
}
