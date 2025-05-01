import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/recipe_service.dart';
import '../../models/recipe.dart';
import '../../theme/app_theme.dart';
import 'add_recipe_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../../services/user_service.dart';
import '../../models/user_profile.dart';
import '../../widgets/recipe_card.dart';
import '../recipe/recipe_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final AnimationController _editButtonController;

  @override
  void initState() {
    super.initState();
    _editButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _editButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final recipeService = RecipeService();

    // If user is not authenticated, redirect to login
    if (user == null) {
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Community Cookbook',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black.withOpacity(0.7),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed:
                () =>
                    Provider.of<AuthService>(context, listen: false).signOut(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home Feed
          StreamBuilder<List<Recipe>>(
            stream: recipeService.getRecipes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: AppTheme.errorColor),
                  ),
                );
              }

              final recipes = snapshot.data ?? [];

              if (recipes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No recipes yet',
                        style: AppTheme.headingStyle,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddRecipeScreen(),
                            ),
                          );
                        },
                        style: AppTheme.elevatedButtonStyle,
                        child: const Text(
                          'Add First Recipe',
                          style: AppTheme.buttonTextStyle,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return StreamBuilder<UserProfile?>(
                    stream: UserService().getUserProfile(recipe.userId),
                    builder: (context, profileSnapshot) {
                      final displayName =
                          profileSnapshot.data?.displayName ?? 'Anonymous';
                      return RecipeCard(
                        recipe: recipe,
                        authorName: displayName,
                        onTap: () => _navigateToRecipeDetail(recipe),
                      );
                    },
                  );
                },
              );
            },
          ),
          // Search Screen
          Center(
            child: Text('Search Coming Soon', style: AppTheme.headingStyle),
          ),
          // My Recipes Screen
          StreamBuilder<List<Recipe>>(
            stream: recipeService.getUserRecipes(user?.uid ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: AppTheme.errorColor),
                  ),
                );
              }

              final recipes = snapshot.data ?? [];

              if (recipes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No recipes yet',
                        style: AppTheme.headingStyle,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddRecipeScreen(),
                            ),
                          );
                        },
                        style: AppTheme.elevatedButtonStyle,
                        child: const Text(
                          'Add First Recipe',
                          style: AppTheme.buttonTextStyle,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return StreamBuilder<UserProfile?>(
                    stream: UserService().getUserProfile(recipe.userId),
                    builder: (context, profileSnapshot) {
                      final displayName =
                          profileSnapshot.data?.displayName ?? 'Anonymous';
                      return RecipeCard(
                        recipe: recipe,
                        authorName: displayName,
                        onTap: () => _navigateToRecipeDetail(recipe),
                      );
                    },
                  );
                },
              );
            },
          ),
          // Profile Screen
          StreamBuilder<UserProfile?>(
            stream: UserService().getUserProfile(user?.uid ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final profile = snapshot.data;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.glassDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 32,
                                backgroundColor: AppTheme.primaryColor,
                                child: Icon(
                                  Icons.person,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile?.displayName ?? 'Anonymous',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user?.email ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textColor.withOpacity(
                                          0.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                color: AppTheme.primaryColor,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const EditProfileScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'About Me',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profile?.description ?? 'No description provided',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textColor.withOpacity(0.9),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.cake,
                                size: 18,
                                color: AppTheme.textColor.withOpacity(0.7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Age: ${profile?.age ?? 'Not specified'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textColor.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.update,
                                size: 18,
                                color: AppTheme.textColor.withOpacity(0.7),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Updated: ${profile?.lastUpdated?.toString().split('.')[0] ?? 'Never'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textColor.withOpacity(0.7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected:
            (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'My Recipes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToRecipeDetail(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }
}
