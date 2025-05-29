import 'dart:ui'; // Add this at the top if not already present
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
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
import '../../services/image_service.dart';

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
  String? _photoUrl;
  double _uploadProgress = 0;
  bool _isUploading = false;
  String? _uploadError;
  final ImageService _imageService = ImageService();

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

  Future<void> _pickAndUploadProfileImage() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadError = null;
    });
    try {
      final url = await _imageService.pickAndUploadImage(
        ImageSource.gallery,
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );
      if (url != null) {
        final user =
            Provider.of<AuthService>(context, listen: false).currentUser;
        if (user != null) {
          final currentProfile =
              await _userService.getUserProfileFuture(user.uid);
          if (currentProfile != null) {
            final updatedProfile = currentProfile.copyWith(photoUrl: url);
            await _userService.updateUserProfile(updatedProfile);
            setState(() => _photoUrl = url);
          }
        }
      }
    } catch (e) {
      setState(() => _uploadError = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
      });
    }
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
                PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: SafeArea(
                    top: true,
                    bottom: false,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Color(0xFFADC66A),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                height: 36.0,
                                width: 36.0,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Center(
                              child: Text(
                                'Food Vault',
                                style: TextStyle(
                                  fontFamily: 'PlayfairDisplay',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 23.0,
                                  color: Colors.white,
                                  letterSpacing: 1.25,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            Spacer(),
                            if (_selectedIndex == 3)
                              IconButton(
                                icon: Icon(
                                  Icons.logout,
                                  color: Colors.white,
                                  size: 24.0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                tooltip: 'Logout',
                                onPressed: () async {
                                  try {
                                    await Provider.of<AuthService>(context,
                                            listen: false)
                                        .signOut();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Logged out successfully')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Logout failed: \\${e.toString()}')),
                                      );
                                    }
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Content area
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      // Home Feed
                      Padding(
                        padding: EdgeInsets.zero, // Remove any top padding
                        child: _buildHomeFeed(context, user.uid),
                      ),
                      // Search Screen
                      _searchScreen,
                      // My Recipes Screen
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                            child: Text(
                              'My Recipes',
                              style:
                                  AppTheme.headingStyle.copyWith(fontSize: 28),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  top: 0), // No extra top padding
                              child: _buildMyRecipes(context, user.uid),
                            ),
                          ),
                        ],
                      ),
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
                          return Column(
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    // --- Blurred background layer ---
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.zero,
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: AppTheme.backgroundColor.withOpacity(0.5),
                                              borderRadius: BorderRadius.zero,
                                              border: Border.all(
                                                  color: Colors.white.withOpacity(0.1)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // --- Main profile content ---
                                    SingleChildScrollView(
                                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFDFCEAC),
                                              borderRadius: BorderRadius.circular(24),
                                              border: Border.all(
                                                  color: Colors.white.withOpacity(0.1)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Stack(
                                                  alignment: Alignment.bottomRight,
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        Stack(
                                                          alignment: Alignment.bottomRight,
                                                          children: [
                                                            CircleAvatar(
                                                              radius: 32,
                                                              backgroundColor: AppTheme.primaryColor,
                                                              backgroundImage: (profile?.photoUrl != null && profile!.photoUrl!.isNotEmpty)
                                                                  ? NetworkImage(profile.photoUrl!)
                                                                  : null,
                                                              child: (profile?.photoUrl == null || profile!
                                                                  .photoUrl!
                                                                  .isEmpty)
                                                                  ? Text(
                                                                      (profile?.displayName?.isNotEmpty == true
                                                                          ? profile!.displayName[0]
                                                                          : (user.email?.isNotEmpty == true
                                                                              ? user.email![0]
                                                                              : '?'))
                                                                      .toUpperCase(),
                                                                  style: const TextStyle(
                                                                    fontSize: 28,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Colors.white,
                                                                    fontFamily: 'PlayfairDisplay',
                                                                  ),
                                                                )
                                                              : null,
                                                            ),
                                                            Positioned(
                                                              bottom: 0,
                                                              right: 0,
                                                              child: GestureDetector(
                                                                onTap: _isUploading ? null : _pickAndUploadProfileImage,
                                                                child: Container(
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.white,
                                                                    shape: BoxShape.circle,
                                                                    border: Border.all(color: AppTheme.primaryColor, width: 2),
                                                                  ),
                                                                  padding: const EdgeInsets.all(2),
                                                                  child: Icon(
                                                                    Icons.add_a_photo,
                                                                    color: AppTheme.primaryColor,
                                                                    size: 14,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            if (_isUploading)
                                                              Positioned.fill(
                                                                child: Container(
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.black38,
                                                                    shape: BoxShape.circle,
                                                                  ),
                                                                  child: Center(
                                                                    child: CircularProgressIndicator(
                                                                      value: _uploadProgress > 0 && _uploadProgress < 1
                                                                          ? _uploadProgress
                                                                          : null,
                                                                      color: Colors.white,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                        const SizedBox(width: 16),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                profile?.displayName ?? 'Anonymous',
                                                                style: TextStyle(
                                                                  fontSize: 20,
                                                                  fontWeight: FontWeight.w700,
                                                                  color: Colors.black,
                                                                  fontFamily: 'PlayfairDisplay',
                                                                ),
                                                              ),
                                                              const SizedBox(height: 4),
                                                              Text(
                                                                user.email ?? '',
                                                                style: const TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight: FontWeight.w400,
                                                                  color: Colors.black,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.edit),
                                                          color: Colors.black,
                                                          onPressed: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (context) => const EditProfileScreen(),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'About Me',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.black,
                                                    fontFamily: 'PlayfairDisplay',
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  profile?.description ?? 'No description provided',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: Colors.black,
                                                    height: 1.4,
                                                    fontFamily: 'PlayfairDisplay',
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.cake,
                                                      size: 18,
                                                      color: Colors.black,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Age: ',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black,
                                                        fontFamily: 'PlayfairDisplay',
                                                        fontWeight: FontWeight.w400,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${profile?.age ?? 'Not specified'}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black,
                                                        fontFamily: '', // Default system font
                                                        fontWeight: FontWeight.w400,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Icon(
                                                      Icons.update,
                                                      size: 18,
                                                      color: Colors.black,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Updated: ',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black,
                                                        fontFamily: 'PlayfairDisplay',
                                                        fontWeight: FontWeight.w400,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        profile?.lastUpdated != null
                                                            ? profile!.lastUpdated.toString().split('.')[0]
                                                            : 'Never',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.black,
                                                          fontFamily: '', // Default system font
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
                                                        builder: (context) => AlertDialog(
                                                          title: const Text('Delete Account?'),
                                                          content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(context, false),
                                                              child: const Text('Cancel'),
                                                            ),
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(context, true),
                                                              child: const Text('Yes, Continue'),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      if (!confirmed) return;
                                                      confirmed = await showDialog(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          title: const Text('Are You Really Sure?'),
                                                          content: const Text('Deleting your account will remove all your recipes and data. This cannot be undone.'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(context, false),
                                                              child: const Text('Cancel'),
                                                            ),
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(context, true),
                                                              child: const Text('Yes, Continue'),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      if (!confirmed) return;
                                                      confirmed = await showDialog(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          title: const Text('Final Warning!'),
                                                          content: const Text('This is your last chance. Deleting your account will permanently erase all your recipes and cannot be undone. Do you want to proceed?'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(context, false),
                                                              child: const Text('Cancel'),
                                                            ),
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(context, true),
                                                              child: const Text('Yes, Delete Everything'),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      if (!confirmed) return;
                                                      try {
                                                        final authService = Provider.of<AuthService>(context, listen: false);
                                                        final recipeService = RecipeService();
                                                        final userId = authService.currentUser?.uid;
                                                        if (userId != null) {
                                                          await recipeService.deleteAllRecipesByUser(userId);
                                                        }
                                                        await authService.deleteAccount();
                                                        if (mounted) {
                                                          Navigator.pushReplacementNamed(context, '/login');
                                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account and all recipes deleted.')));
                                                        }
                                                      } catch (e) {
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting account: \\${e.toString()}')));
                                                        }
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 32),
                                          if (profile != null && profile.savedRecipes.isNotEmpty) ...[
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'Saved Recipes',
                                                style: AppTheme.headingStyle.copyWith(fontSize: 28),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            StreamBuilder<List<Recipe>>(
                                              stream: _recipeService.getRecipesByIds(profile.savedRecipes),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return const Center(child: CircularProgressIndicator());
                                                }
                                                if (snapshot.hasError) {
                                                  return Center(child: Text('Error: ${snapshot.error}'));
                                                }
                                                final saved = snapshot.data ?? [];
                                                if (saved.isEmpty) {
                                                  return const Text('No saved recipes yet.');
                                                }
                                                return Padding(
                                                  padding: EdgeInsets.zero,
                                                  child: MasonryGridView.count(
                                                    shrinkWrap: true,
                                                    physics: const NeverScrollableScrollPhysics(),
                                                    crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
                                                    mainAxisSpacing: 16,
                                                    crossAxisSpacing: 16,
                                                    itemCount: saved.length,
                                                    itemBuilder: (context, index) {
                                                      final recipe = saved[index];
                                                      final aspectRatio = index % 2 == 0 ? 0.8 : 1.1;
                                                      return RecipeCard(
                                                        recipe: recipe,
                                                        onTap: () => _navigateToRecipeDetail(recipe),
                                                        aspectRatio: aspectRatio,
                                                      );
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                          ] else if (profile != null) ...[
                                            const SizedBox(height: 32),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'Saved Recipes',
                                                style: AppTheme.headingStyle.copyWith(fontSize: 28),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            const Text('No saved recipes yet.'),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
          color: Color(0xFFADC66A),
          buttonBackgroundColor: Color(0xFFADC66A),
          animationCurve: Curves.bounceInOut,
          animationDuration: const Duration(milliseconds: 200),
          items: <Widget>[
            AnimatedScale(
              scale: _selectedIndex == 0 ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.home,
                size: 30,
                color: _selectedIndex == 0 ? Colors.white : AppTheme.textColor,
              ),
            ),
            AnimatedScale(
              scale: _selectedIndex == 1 ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.search,
                size: 30,
                color: _selectedIndex == 1 ? Colors.white : AppTheme.textColor,
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.textColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                size: 36,
                color: Colors.white,
              ),
            ),
            AnimatedScale(
              scale: _selectedIndex == 2 ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.restaurant_menu,
                size: 30,
                color: _selectedIndex == 2 ? Colors.white : AppTheme.textColor,
              ),
            ),
            AnimatedScale(
              scale: _selectedIndex == 3 ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.person_outline,
                size: 30,
                color: _selectedIndex == 3 ? Colors.white : AppTheme.textColor,
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
        pageBuilder: (context, animation, secondaryAnimation) => RecipeDetailScreen(recipe: recipe),
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
