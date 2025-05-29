import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/recipe.dart';
import '../../services/recipe_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/recipe_card.dart';
import '../recipe/recipe_detail_screen.dart';
import '../../models/user_profile.dart';
import 'dart:ui';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  final _recipeService = RecipeService();
  final _userService = UserService();
  final ValueNotifier<List<Recipe>> _allRecipesNotifier =
      ValueNotifier<List<Recipe>>([]);
  final ValueNotifier<List<Recipe>> _filteredRecipesNotifier =
      ValueNotifier<List<Recipe>>([]);
  final ValueNotifier<List<String>> _selectedCategoriesNotifier =
      ValueNotifier<List<String>>([]);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isSearchingByCreatorNotifier = ValueNotifier<bool>(
    false,
  );
  final ValueNotifier<bool> _hasSearchedNotifier = ValueNotifier<bool>(false);

  static const _categories = [
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
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _allRecipesNotifier.dispose();
    _filteredRecipesNotifier.dispose();
    _selectedCategoriesNotifier.dispose();
    _isLoadingNotifier.dispose();
    _isSearchingByCreatorNotifier.dispose();
    _hasSearchedNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    _recipeService.getRecipes().listen((recipes) {
      _allRecipesNotifier.value = recipes;
    });
  }

  void _filterRecipes(String query) async {
    if (query.isEmpty && _selectedCategoriesNotifier.value.isEmpty) {
      _filteredRecipesNotifier.value = [];
      _hasSearchedNotifier.value = false;
      _isLoadingNotifier.value = false;
      return;
    }

    _isLoadingNotifier.value = true;
    _hasSearchedNotifier.value = true;

    if (_isSearchingByCreatorNotifier.value) {
      final List<Recipe> creatorResults = [];
      for (final recipe in _allRecipesNotifier.value) {
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

      if (!mounted) return;

      var filtered = creatorResults;
      if (_selectedCategoriesNotifier.value.isNotEmpty) {
        filtered =
            filtered
                .where(
                  (recipe) => recipe.categories.any(
                    (category) =>
                        _selectedCategoriesNotifier.value.contains(category),
                  ),
                )
                .toList();
      }
      _filteredRecipesNotifier.value = filtered;
    } else {
      if (!mounted) return;

      var filtered =
          _allRecipesNotifier.value
              .where(
                (recipe) =>
                    recipe.title.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

      if (_selectedCategoriesNotifier.value.isNotEmpty) {
        filtered =
            filtered
                .where(
                  (recipe) => recipe.categories.any(
                    (category) =>
                        _selectedCategoriesNotifier.value.contains(category),
                  ),
                )
                .toList();
      }
      _filteredRecipesNotifier.value = filtered;
    }

    if (mounted) {
      _isLoadingNotifier.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _SearchHeaderDelegate(
            searchController: _searchController,
            isSearchingByCreator: _isSearchingByCreatorNotifier,
            selectedCategories: _selectedCategoriesNotifier,
            onSearch: _filterRecipes,
            categories: _categories,
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _isLoadingNotifier,
          builder: (context, isLoading, _) {
            if (isLoading) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            return ValueListenableBuilder<bool>(
              valueListenable: _hasSearchedNotifier,
              builder: (context, hasSearched, _) {
                if (!hasSearched) {
                  return const SliverFillRemaining(child: _EmptySearchState());
                }

                return ValueListenableBuilder<List<Recipe>>(
                  valueListenable: _filteredRecipesNotifier,
                  builder: (context, recipes, _) {
                    if (recipes.isEmpty) {
                      return const SliverFillRemaining(
                        child: _NoResultsState(),
                      );
                    }

                    return SliverPadding(
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width < 600 ? 8.0 : 16.0,
                      ),
                      sliver: SliverMasonryGrid.count(
                        crossAxisCount: _getColumnCount(
                          MediaQuery.of(context).size.width,
                        ),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return RepaintBoundary(
                            child: RecipeCard(
                              key: ValueKey(recipe.id),
                              recipe: recipe,
                              onTap: () => _navigateToRecipe(context, recipe),
                              aspectRatio: index % 2 == 0 ? 0.8 : 1.0,
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _navigateToRecipe(BuildContext context, Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }

  int _getColumnCount(double width) {
    if (width < 600) return 2;
    if (width < 840) return 3;
    return 4;
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final ValueNotifier<bool> isSearchingByCreator;
  final ValueNotifier<List<String>> selectedCategories;
  final Function(String) onSearch;
  final List<String> categories;

  const _SearchHeaderDelegate({
    required this.searchController,
    required this.isSearchingByCreator,
    required this.selectedCategories,
    required this.onSearch,
    required this.categories,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Color(0xFFFFF0DB),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildSearchBar(), _buildCategoryList()],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(Icons.search, color: Colors.black87, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isSearchingByCreator,
                    builder: (context, isSearchingByCreator, _) {
                      return TextField(
                        controller: searchController,
                        style: const TextStyle(color: Colors.black87, fontSize: 16),
                        decoration: InputDecoration(
                          hintText:
                              isSearchingByCreator
                                  ? 'Search by creator name...'
                                  : 'Search recipes...',
                          hintStyle: const TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: onSearch,
                      );
                    },
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: isSearchingByCreator,
                  builder: (context, value, _) {
                    return IconButton(
                      icon: Icon(
                        value ? Icons.person : Icons.restaurant,
                        color: Colors.black54,
                        size: 20,
                      ),
                      onPressed: () {
                        isSearchingByCreator.value = !value;
                        searchController.clear();
                        onSearch('');
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 32,
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ValueListenableBuilder<List<String>>(
                valueListenable: selectedCategories,
                builder: (context, selected, _) {
                  final isSelected = selected.contains(category);
                  return FilterChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.black87 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (value) {
                      final newCategories = List<String>.from(selected);
                      if (value) {
                        newCategories.add(category);
                      } else {
                        newCategories.remove(category);
                      }
                      selectedCategories.value = newCategories;
                      onSearch(searchController.text);
                    },
                    backgroundColor: AppTheme.cardColor.withOpacity(0.5),
                    selectedColor: AppTheme.primaryColor,
                    checkmarkColor: Colors.white,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  double get maxExtent => 96;

  @override
  double get minExtent => 96;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search, size: 48, color: Colors.black38),
          const SizedBox(height: 16),
          const Text(
            'Search for recipes or creators',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No recipes found',
        style: TextStyle(color: Colors.black54, fontSize: 14),
      ),
    );
  }
}
