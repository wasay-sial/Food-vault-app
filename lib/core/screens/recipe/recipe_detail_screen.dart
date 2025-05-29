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
import 'package:auto_size_text/auto_size_text.dart';

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
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _loadInitialRecipes();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (_scrollController.hasClients) {
      final collapsed = _scrollController.offset > (300 - kToolbarHeight - 20);
      if (collapsed != _isCollapsed) {
        setState(() {
          _isCollapsed = collapsed;
        });
      }
    }
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
          SnackBar(content: Text('Error deleting recipe: \\${e.toString()}')),
        );
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
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Color(0xFFADC66A),
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              title: _isCollapsed
                  ? SizedBox(
                      width: MediaQuery.of(context).size.width - 120,
                      child: AutoSizeText(
                        widget.recipe.title,
                        maxLines: 1,
                        minFontSize: 14,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontFamily: 'PlayfairDisplay',
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    )
                  : null,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              centerTitle: false,
              expandedTitleScale: 1.0,
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'recipe-image-${widget.recipe.id}-${DateTime.now().millisecondsSinceEpoch}',
                    child: CachedNetworkImage(
                      imageUrl: widget.recipe.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.cardColor,
                        child: const Icon(
                          Icons.restaurant,
                          size: 50,
                          color: Colors.white54,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
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
                  if (!_isCollapsed)
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 120,
                        child: Stack(
                          children: [
                            // Black border (stroke)
                            Text(
                              widget.recipe.title,
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                fontFamily: 'PlayfairDisplay',
                                height: 1.2,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 4
                                  ..color = Colors.black,
                              ),
                            ),
                            // White fill
                            Text(
                              widget.recipe.title,
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                fontFamily: 'PlayfairDisplay',
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.black,
                            insetPadding: EdgeInsets.zero,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: InteractiveViewer(
                                child: CachedNetworkImage(
                                  imageUrl: widget.recipe.imageUrl,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => Container(
                                    color: AppTheme.cardColor,
                                    child: const Icon(
                                      Icons.restaurant,
                                      size: 50,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: AppTheme.cardColor,
                                    child: const Icon(
                                      Icons.restaurant,
                                      size: 50,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
            ),
            leading: _isCollapsed ? null : IconButton(
              icon: Stack(
                children: [
                  for (final offset in [
                    Offset(-1, -1), Offset(0, -1), Offset(1, -1),
                    Offset(-1, 0),                Offset(1, 0),
                    Offset(-1, 1),  Offset(0, 1),  Offset(1, 1),
                  ])
                    Positioned(
                      left: offset.dx,
                      top: offset.dy,
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: _isCollapsed
                ? null
                : isCreator
                    ? [
                        IconButton(
                          icon: Stack(
                            children: [
                              for (final offset in [
                                Offset(-1, -1), Offset(0, -1), Offset(1, -1),
                                Offset(-1, 0),                Offset(1, 0),
                                Offset(-1, 1),  Offset(0, 1),  Offset(1, 1),
                              ])
                                Positioned(
                                  left: offset.dx,
                                  top: offset.dy,
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.black,
                                    size: 24,
                                  ),
                                ),
                              Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 24,
                              ),
                            ],
                          ),
                          onPressed: () => _deleteRecipe(context),
                        ),
                      ]
                    : null,
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 20,
                        color: AppTheme.textColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.recipe.cookingTime}',
                        style: TextStyle(
                          color: AppTheme.textColor.withOpacity(0.7),
                          fontSize: 16,
                          fontFamily: '',
                        ),
                      ),
                      Text(
                        ' minutes',
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
                        'Serves ',
                        style: TextStyle(
                          color: AppTheme.textColor.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${widget.recipe.servings}',
                        style: TextStyle(
                          color: AppTheme.textColor.withOpacity(0.7),
                          fontSize: 16,
                          fontFamily: '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.recipe.description,
                    style: const TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 16,
                      height: 1.5,
                      fontFamily: '',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ingredients',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                                  fontFamily: '',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
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
                                    fontFamily: '',
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
                                  fontFamily: '',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'More Recipes by This Creator',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = constraints.maxWidth < 600 ? 2 : 3;
                        return MasonryGridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
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
                                    builder: (context) => RecipeDetailScreen(
                                      recipe: otherRecipe,
                                    ),
                                  ),
                                );
                              },
                              aspectRatio: aspectRatio,
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
