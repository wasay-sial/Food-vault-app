import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import 'package:rxdart/rxdart.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all recipes
  Stream<List<Recipe>> getRecipes() {
    return _firestore
        .collection('recipes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
        });
  }

  // Get user's recipes
  Stream<List<Recipe>> getUserRecipes(String userId) {
    return _firestore
        .collection('recipes')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
        });
  }

  // Add new recipe
  Future<void> addRecipe(Recipe recipe) async {
    await _firestore.collection('recipes').add(recipe.toMap());
  }

  // Update recipe
  Future<void> updateRecipe(Recipe recipe) async {
    await _firestore
        .collection('recipes')
        .doc(recipe.id)
        .update(recipe.toMap());
  }

  // Delete recipe
  Future<void> deleteRecipe(String recipeId) async {
    await _firestore.collection('recipes').doc(recipeId).delete();
  }

  // Like recipe
  Future<void> likeRecipe(String recipeId) async {
    await _firestore.collection('recipes').doc(recipeId).update({
      'likes': FieldValue.increment(1),
    });
  }

  // Unlike recipe
  Future<void> unlikeRecipe(String recipeId) async {
    await _firestore.collection('recipes').doc(recipeId).update({
      'likes': FieldValue.increment(-1),
    });
  }

  // Search recipes
  Stream<List<Recipe>> searchRecipes(String query) {
    return _firestore
        .collection('recipes')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
        });
  }

  // Get recipes by category
  Stream<List<Recipe>> getRecipesByCategory(String category) {
    return _firestore
        .collection('recipes')
        .where('categories', arrayContains: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
        });
  }

  // Get recipes by user ID
  Stream<List<Recipe>> getRecipesByUser(String userId) {
    return _firestore
        .collection('recipes')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
        });
  }

  // Delete all recipes by user ID
  Future<void> deleteAllRecipesByUser(String userId) async {
    final snapshot =
        await _firestore
            .collection('recipes')
            .where('userId', isEqualTo: userId)
            .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Get recipes by a list of IDs
  Stream<List<Recipe>> getRecipesByIds(List<String> recipeIds) {
    if (recipeIds.isEmpty) {
      return Stream.value([]); // Return empty list if no IDs
    }
    // Firestore 'whereIn' has a limit of 10. Split IDs into chunks if necessary.
    final chunks = <List<String>>[];
    for (var i = 0; i < recipeIds.length; i += 10) {
      chunks.add(recipeIds.sublist(
          i, i + 10 > recipeIds.length ? recipeIds.length : i + 10));
    }

    // Combine streams from multiple queries
    final streams = chunks.map((chunk) {
      return _firestore
          .collection('recipes')
          .where(FieldPath.documentId, whereIn: chunk)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList());
    });

    // Merge all streams into a single stream of lists
    return Rx.combineLatestList(streams).map(
        (lists) =>
            lists.expand((list) => list).toList()); // Flatten the list of lists
  }
}
