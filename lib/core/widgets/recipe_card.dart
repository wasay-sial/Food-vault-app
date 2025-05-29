import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/recipe.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter/foundation.dart';
import 'package:shimmer/shimmer.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final double aspectRatio;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.aspectRatio = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              spreadRadius: 2,
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: aspectRatio,
                      child: Hero(
                        tag: 'recipe-image-${recipe.id}-${DateTime.now().millisecondsSinceEpoch}',
                        child: CachedNetworkImage(
                          imageUrl: recipe.imageUrl,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                color: AppTheme.cardColor,
                                child: Icon(
                                  Icons.restaurant,
                                  size: isSmallScreen ? 40 : 50,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: AppTheme.cardColor,
                                child: Icon(
                                  Icons.restaurant,
                                  size: isSmallScreen ? 40 : 50,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                        ),
                      ),
                    ),
                    if (user != null)
                      StreamBuilder<UserProfile?> (
                        stream: UserService().getUserProfile(user.uid),
                        builder: (context, snapshot) {
                          final userProfile = snapshot.data;
                          if (userProfile == null) return SizedBox.shrink();
                          return Positioned(
                            top: 8,
                            left: 8,
                            child: IconButton(
                              icon: Icon(
                                userProfile.savedRecipes.contains(recipe.id)
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: AppTheme.accentIconColor,
                                size: 28,
                              ),
                              tooltip: userProfile.savedRecipes.contains(recipe.id)
                                  ? 'Unsave Recipe'
                                  : 'Save Recipe',
                              onPressed: () async {
                                final userService = UserService();
                                if (userProfile.savedRecipes.contains(recipe.id)) {
                                  await userService.unsaveRecipe(user.uid, recipe.id);
                                } else {
                                  await userService.saveRecipe(user.uid, recipe.id);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: isSmallScreen ? 14 : 16,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe.cookingTime}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 12,
                                color: Colors.white.withOpacity(0.7),
                                fontFamily: '', // Default system font
                              ),
                            ),
                            Text(
                              ' min',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: AppTheme.cardTitleStyle.copyWith(
                          fontSize: isSmallScreen ? 16 : 18,
                          color: Color(0xFF004225),
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<UserProfile?> (
                        stream: UserService().getUserProfile(recipe.userId),
                        builder: (context, snapshot) {
                          final displayName =
                              snapshot.data?.displayName ?? recipe.userName;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: isSmallScreen ? 24 : 28,
                                height: isSmallScreen ? 24 : 28,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: CircleAvatar(
                                    radius: (isSmallScreen ? 24 : 28) / 2 - 2,
                                    backgroundColor: Colors.white,
                                    backgroundImage: (snapshot.data?.photoUrl != null && snapshot.data!.photoUrl!.isNotEmpty)
                                        ? NetworkImage(snapshot.data!.photoUrl!)
                                        : null,
                                    child: (snapshot.data?.photoUrl == null || snapshot.data!.photoUrl!.isEmpty)
                                        ? Text(
                                            displayName[0].toUpperCase(),
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 12 : 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.primaryColor,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: AppTheme.cardSubtitleStyle.copyWith(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: Color(0xFF004225),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 4 : 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  recipe.difficulty,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 11 : 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
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
          ),
        ),
      ),
    );
  }
}
