import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/recipe.dart';
import '../../services/recipe_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/recipe_card.dart';
import '../recipe/recipe_detail_screen.dart';
import '../../models/user_profile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _recipeService = RecipeService();
  final _userService = UserService();
  List<Recipe> _allRecipes = [];
  List<Recipe> _filteredRecipes = [];
  List<String> _selectedCategories = [];
  bool _isLoading = false;
  bool _isSearchingByCreator = false;
  bool _hasSearched = false;

  final List<String> _categories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Dessert',
    'Snack',
    'Vegetarian',
    'Vegan',
    'Gluten-free',
    'Quick & Easy',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    _recipeService.getRecipes().listen((recipes) {
      setState(() {
        _allRecipes = recipes;
      });
    });
  }

  void _filterRecipes(String query) async {
    if (query.isEmpty && _selectedCategories.isEmpty) {
      setState(() {
        _filteredRecipes = [];
        _hasSearched = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    if (_isSearchingByCreator) {
      // Search by creator name
      final List<Recipe> creatorResults = [];
      for (final recipe in _allRecipes) {
        final userProfile = await _userService.getUserProfileFuture(
          recipe.userId,
        );
        final creatorName =
            userProfile?.displayName?.toLowerCase() ??
            recipe.userName.toLowerCase();
        if (creatorName.contains(query.toLowerCase())) {
          creatorResults.add(recipe);
        }
      }
      if (mounted) {
        setState(() {
          _filteredRecipes = creatorResults;
          if (_selectedCategories.isNotEmpty) {
            _filteredRecipes =
                _filteredRecipes
                    .where(
                      (recipe) => recipe.categories.any(
                        (category) => _selectedCategories.contains(category),
                      ),
                    )
                    .toList();
          }
        });
      }
    } else {
      // Search by recipe name
      if (mounted) {
        setState(() {
          _filteredRecipes =
              _allRecipes
                  .where(
                    (recipe) => recipe.title.toLowerCase().contains(
                      query.toLowerCase(),
                    ),
                  )
                  .toList();
          if (_selectedCategories.isNotEmpty) {
            _filteredRecipes =
                _filteredRecipes
                    .where(
                      (recipe) => recipe.categories.any(
                        (category) => _selectedCategories.contains(category),
                      ),
                    )
                    .toList();
          }
        });
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  int _getColumnCount(double width) {
    if (width < 600) {
      return 2; // Compact width: 2 columns for better visibility on phones
    } else if (width < 840) {
      return 3; // Medium width: 3 columns
    } else {
      return 4; // Expanded width: 4 columns
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 8.0 : 16.0;

    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search bar with reduced height
                Container(
                  height: 48, // Standard Android touch target
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(
                        Icons.search,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                _isSearchingByCreator
                                    ? 'Search by creator name...'
                                    : 'Search recipes...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                          ),
                          onChanged: _filterRecipes,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isSearchingByCreator
                              ? Icons.person
                              : Icons.restaurant,
                          color: Colors.white.withOpacity(0.7),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSearchingByCreator = !_isSearchingByCreator;
                            _searchController.clear();
                            _filterRecipes('');
                          });
                        },
                        tooltip:
                            _isSearchingByCreator
                                ? 'Search by recipe name'
                                : 'Search by creator',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Category filters with reduced height
                SizedBox(
                  height: 32,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategories.contains(category);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(category);
                              } else {
                                _selectedCategories.remove(category);
                              }
                              _filterRecipes(_searchController.text);
                            });
                          },
                          backgroundColor: AppTheme.cardColor.withOpacity(0.5),
                          selectedColor: AppTheme.primaryColor,
                          checkmarkColor: Colors.white,
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color:
                                  isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : !_hasSearched
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search,
                            size: 48,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Search for recipes or creators',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                    : _filteredRecipes.isEmpty
                    ? Center(
                      child: Text(
                        'No recipes found',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    )
                    : Padding(
                      padding: EdgeInsets.all(horizontalPadding),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final columnCount = _getColumnCount(
                            constraints.maxWidth,
                          );

                          return MasonryGridView.count(
                            crossAxisCount: columnCount,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            itemCount: _filteredRecipes.length,
                            itemBuilder: (context, index) {
                              final recipe = _filteredRecipes[index];
                              final aspectRatio = index % 2 == 0 ? 0.8 : 1.0;
                              return RecipeCard(
                                recipe: recipe,
                                onTap:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => RecipeDetailScreen(
                                              recipe: recipe,
                                            ),
                                      ),
                                    ),
                                aspectRatio: aspectRatio,
                              );
                            },
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
