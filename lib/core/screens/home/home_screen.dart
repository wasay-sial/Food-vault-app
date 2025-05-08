import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import '../search/search_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final AnimationController _editButtonController;
  final RecipeService _recipeService = RecipeService();
  final UserService _userService = UserService();

  final GlobalKey<CurvedNavigationBarState> _bottomNavKey = GlobalKey();

  // Cached widgets
  late final _searchScreen = const SearchScreen();

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

  Widget _buildRecipeGrid(List<Recipe> recipes, BuildContext context) {
    if (recipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No recipes yet', style: AppTheme.headingStyle),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddRecipeScreen(),
                      ),
                    );
                  },
                  style: AppTheme.elevatedButtonStyle.copyWith(
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                  ),
                  child: const Text(
                    'Add First Recipe',
                    style: AppTheme.buttonTextStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount;
          if (constraints.maxWidth < 600) {
            crossAxisCount = 2;
          } else if (constraints.maxWidth < 900) {
            crossAxisCount = 3;
          } else {
            crossAxisCount = 4;
          }

          return MasonryGridView.builder(
            gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
            ),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            itemCount: recipes.length,
            cacheExtent: 1000, // Cache more items for smoother scrolling
            addAutomaticKeepAlives: true,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              final aspectRatio = index % 2 == 0 ? 0.8 : 1.1;
              return RecipeCard(
                key: ValueKey(recipe.id),
                recipe: recipe,
                onTap: () => _navigateToRecipeDetail(recipe),
                aspectRatio: aspectRatio,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHomeFeed(BuildContext context, String? userId) {
    return StreamBuilder<List<Recipe>>(
      stream: _recipeService.getRecipes(),
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
        return _buildRecipeGrid(recipes, context);
      },
    );
  }

  Widget _buildMyRecipes(BuildContext context, String userId) {
    return StreamBuilder<List<Recipe>>(
      stream: _recipeService.getUserRecipes(userId),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 24.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No recipes yet',
                    style: AppTheme.headingStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddRecipeScreen(),
                          ),
                        );
                      },
                      style: AppTheme.elevatedButtonStyle.copyWith(
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(
                            horizontal: 48.0,
                            vertical: 16.0,
                          ),
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Add Your First Recipe',
                        style: AppTheme.buttonTextStyle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return _buildRecipeGrid(recipes, context);
      },
    );
  }

  // Helper to map between navigation bar index and selected index
  int _navIndexFromSelected(int selected) {
    // 0: Home, 1: Search, 2: My Recipes, 3: Profile
    // Nav bar: 0: Home, 1: Search, 2: Add, 3: My Recipes, 4: Profile
    if (selected < 2) return selected;
    return selected + 1;
  }

  int _selectedFromNavIndex(int navIndex) {
    if (navIndex < 2) return navIndex;
    if (navIndex > 2) return navIndex - 1;
    // navIndex == 2 is the Add button
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;

    // If user is not authenticated, redirect to login
    if (user == null) {
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return GestureDetector(
      onTap: () {
        // Unfocus any text field when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.backgroundGradient,
              ),
            ),
            // Animated stars/particles
            ...List.generate(20, (index) {
              final top = index * 30.0;
              final left = (index % 2 == 0) ? index * 40.0 : index * 20.0;
              return Positioned(
                top: top,
                left: left,
                child: Container(
                  width: 2,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            }),
            // Main content
            Column(
              children: [
                // Custom app bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor.withOpacity(0.95),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/app_icon.png',
                        height: 32,
                        width: 32,
                      ),
                      const SizedBox(width: 8),
                      const Text('Food Vault', style: AppTheme.headingStyle),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.black87),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  backgroundColor: AppTheme.surfaceColor,
                                  title: const Text(
                                    'Confirm Logout',
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to logout?',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(color: Colors.black54),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Provider.of<AuthService>(
                                          context,
                                          listen: false,
                                        ).signOut();
                                      },
                                      child: const Text(
                                        'Logout',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Content area
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      // Home Feed
                      _buildHomeFeed(context, user.uid),
                      // Search Screen
                      _searchScreen,
                      // My Recipes Screen
                      _buildMyRecipes(context, user.uid),
                      // Profile Screen
                      StreamBuilder<UserProfile?>(
                        stream: _userService.getUserProfile(user.uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const CircleAvatar(
                                            radius: 32,
                                            backgroundColor:
                                                AppTheme.primaryColor,
                                            child: Icon(
                                              Icons.person,
                                              size: 32,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  profile?.displayName ??
                                                      'Anonymous',
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.textColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  user.email ?? '',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: AppTheme.textColor
                                                        .withOpacity(0.7),
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
                                        profile?.description ??
                                            'No description provided',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textColor.withOpacity(
                                            0.9,
                                          ),
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.cake,
                                            size: 18,
                                            color: AppTheme.textColor
                                                .withOpacity(0.7),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Age: ${profile?.age ?? 'Not specified'}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppTheme.textColor
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(
                                            Icons.update,
                                            size: 18,
                                            color: AppTheme.textColor
                                                .withOpacity(0.7),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Updated: ${profile?.lastUpdated?.toString().split('.')[0] ?? 'Never'}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.textColor
                                                    .withOpacity(0.7),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      // Add a red bin icon in the bottom right corner
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 32,
                                          ),
                                          tooltip: 'Delete Profile',
                                          onPressed: () async {
                                            bool confirmed = await showDialog(
                                              context: context,
                                              builder:
                                                  (context) => AlertDialog(
                                                    title: const Text(
                                                      'Delete Account?',
                                                    ),
                                                    content: const Text(
                                                      'Are you sure you want to delete your account? This action cannot be undone.',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              false,
                                                            ),
                                                        child: const Text(
                                                          'Cancel',
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              true,
                                                            ),
                                                        child: const Text(
                                                          'Yes, Continue',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );
                                            if (!confirmed) return;
                                            confirmed = await showDialog(
                                              context: context,
                                              builder:
                                                  (context) => AlertDialog(
                                                    title: const Text(
                                                      'Are You Really Sure?',
                                                    ),
                                                    content: const Text(
                                                      'Deleting your account will remove all your recipes and data. This cannot be undone.',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              false,
                                                            ),
                                                        child: const Text(
                                                          'Cancel',
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              true,
                                                            ),
                                                        child: const Text(
                                                          'Yes, Continue',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );
                                            if (!confirmed) return;
                                            confirmed = await showDialog(
                                              context: context,
                                              builder:
                                                  (context) => AlertDialog(
                                                    title: const Text(
                                                      'Final Warning!',
                                                    ),
                                                    content: const Text(
                                                      'This is your last chance. Deleting your account will permanently erase all your recipes and cannot be undone. Do you want to proceed?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              false,
                                                            ),
                                                        child: const Text(
                                                          'Cancel',
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              true,
                                                            ),
                                                        child: const Text(
                                                          'Yes, Delete Everything',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );
                                            if (!confirmed) return;
                                            try {
                                              final authService =
                                                  Provider.of<AuthService>(
                                                    context,
                                                    listen: false,
                                                  );
                                              final recipeService =
                                                  RecipeService();
                                              final userId =
                                                  authService.currentUser?.uid;
                                              if (userId != null) {
                                                await recipeService
                                                    .deleteAllRecipesByUser(
                                                      userId,
                                                    );
                                              }
                                              await authService.deleteAccount();
                                              if (mounted) {
                                                Navigator.pushReplacementNamed(
                                                  context,
                                                  '/login',
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Account and all recipes deleted.',
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Error deleting account: ${e.toString()}',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
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
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: CurvedNavigationBar(
          key: _bottomNavKey,
          index: _navIndexFromSelected(_selectedIndex),
          height: 65.0,
          backgroundColor: Colors.transparent,
          color: AppTheme.primaryColor,
          buttonBackgroundColor: AppTheme.primaryColor,
          animationCurve: Curves.bounceInOut,
          animationDuration: const Duration(milliseconds: 200),
          items: <Widget>[
            AnimatedScale(
              scale: _selectedIndex == 0 ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.home,
                size: 30,
                color:
                    _selectedIndex == 0
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
              ),
            ),
            AnimatedScale(
              scale: _selectedIndex == 1 ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.search,
                size: 30,
                color:
                    _selectedIndex == 1
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.add, size: 36, color: Colors.white),
            ),
            AnimatedScale(
              scale: _selectedIndex == 2 ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.book_outlined,
                size: 30,
                color:
                    _selectedIndex == 2
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
              ),
            ),
            AnimatedScale(
              scale: _selectedIndex == 3 ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.person_outline,
                size: 30,
                color:
                    _selectedIndex == 3
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
              ),
            ),
          ],
          onTap: (navIndex) {
            if (navIndex == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddRecipeScreen(),
                ),
              );
            } else {
              final newSelected = _selectedFromNavIndex(navIndex);
              if (newSelected != -1) {
                setState(() {
                  _selectedIndex = newSelected;
                });
              }
            }
          },
        ),
      ),
    );
  }

  void _navigateToRecipeDetail(Recipe recipe) {
    // Unfocus any text field before navigation
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                RecipeDetailScreen(recipe: recipe),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.05);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
