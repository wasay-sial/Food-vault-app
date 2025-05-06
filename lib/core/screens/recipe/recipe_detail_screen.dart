import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/recipe.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../services/recipe_service.dart';
import '../../models/user_profile.dart';
import '../../widgets/recipe_card.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final RecipeService _recipeService = RecipeService();
  final List<Recipe> _displayedRecipes = [];
  bool _isLoadingMore = false;
  bool _hasMoreRecipes = true;
  static const int _initialLoadCount = 3;
  static const int _loadMoreCount = 3;

  @override
  void initState() {
    super.initState();
    _loadInitialRecipes();
  }

  Future<void> _loadInitialRecipes() async {
    final recipes =
        await _recipeService.getRecipesByUser(widget.recipe.userId).first;
    final filteredRecipes =
        recipes.where((r) => r.id != widget.recipe.id).toList();

    setState(() {
      _displayedRecipes.clear();
      if (filteredRecipes.length > _initialLoadCount) {
        _displayedRecipes.addAll(filteredRecipes.take(_initialLoadCount));
        _hasMoreRecipes = true;
      } else {
        _displayedRecipes.addAll(filteredRecipes);
        _hasMoreRecipes = false;
      }
    });
  }

  Future<void> _loadMoreRecipes() async {
    if (_isLoadingMore || !_hasMoreRecipes) return;

    setState(() {
      _isLoadingMore = true;
    });

    final recipes =
        await _recipeService.getRecipesByUser(widget.recipe.userId).first;
    final filteredRecipes =
        recipes.where((r) => r.id != widget.recipe.id).toList();

    setState(() {
      final currentLength = _displayedRecipes.length;
      final remainingRecipes =
          filteredRecipes.skip(currentLength).take(_loadMoreCount).toList();

      _displayedRecipes.addAll(remainingRecipes);
      _hasMoreRecipes = _displayedRecipes.length < filteredRecipes.length;
      _isLoadingMore = false;
    });
  }

  Future<void> _deleteRecipe(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Recipe'),
            content: const Text(
              'Are you sure you want to delete this recipe? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await _recipeService.deleteRecipe(widget.recipe.id);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recipe deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting recipe: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthService>(context).currentUser;
    final isCreator = currentUser?.uid == widget.recipe.userId;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.black.withOpacity(0.7),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.recipe.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'recipe-image-${widget.recipe.id}',
                    child: CachedNetworkImage(
                      imageUrl: widget.recipe.imageUrl,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: AppTheme.cardColor,
                            child: const Icon(
                              Icons.restaurant,
                              size: 50,
                              color: Colors.white54,
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: AppTheme.cardColor,
                            child: const Icon(
                              Icons.restaurant,
                              size: 50,
                              color: Colors.white54,
                            ),
                          ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions:
                isCreator
                    ? [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () => _deleteRecipe(context),
                      ),
                    ]
                    : null,
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<UserProfile?>(
                    stream: UserService().getUserProfile(widget.recipe.userId),
                    builder: (context, snapshot) {
                      final displayName =
                          snapshot.data?.displayName ?? 'Anonymous';
                      return Text(
                        'By $displayName',
                        style: TextStyle(
                          color: AppTheme.textColor.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 20,
                        color: AppTheme.textColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.recipe.cookingTime} minutes',
                        style: TextStyle(
                          color: AppTheme.textColor.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Icon(
                        Icons.people,
                        size: 20,
                        color: AppTheme.textColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Serves ${widget.recipe.servings}',
                        style: TextStyle(
                          color: AppTheme.textColor.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.recipe.description,
                    style: const TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ingredients',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.recipe.ingredients.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.fiber_manual_record,
                              size: 8,
                              color: AppTheme.textColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.recipe.ingredients[index],
                                style: const TextStyle(
                                  color: AppTheme.textColor,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.recipe.instructions.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.recipe.instructions[index],
                                style: const TextStyle(
                                  color: AppTheme.textColor,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'More Recipes by This Creator',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_displayedRecipes.isEmpty)
                    Center(
                      child: Text(
                        'No other recipes by this creator',
                        style: TextStyle(
                          color: AppTheme.textColor.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        MasonryGridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          itemCount: _displayedRecipes.length,
                          itemBuilder: (context, index) {
                            final otherRecipe = _displayedRecipes[index];
                            final aspectRatio = index % 2 == 0 ? 1.2 : 1.3;
                            return RecipeCard(
                              recipe: otherRecipe,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => RecipeDetailScreen(
                                          recipe: otherRecipe,
                                        ),
                                  ),
                                );
                              },
                              aspectRatio: aspectRatio,
                            );
                          },
                        ),
                        if (_hasMoreRecipes)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: ElevatedButton(
                              onPressed:
                                  _isLoadingMore ? null : _loadMoreRecipes,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child:
                                  _isLoadingMore
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : const Text('Load More Recipes'),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
