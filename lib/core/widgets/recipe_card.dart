import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/recipe.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import '../models/user_profile.dart';

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

    return RepaintBoundary(
      child: Container(
        decoration: AppTheme.modernCardDecoration,
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
                        memCacheWidth: (screenWidth * 0.5).round(),
                      ),
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
                              '${recipe.cookingTime} min',
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
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<UserProfile?>(
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
                                    child: Text(
                                      displayName[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 10 : 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: AppTheme.cardSubtitleStyle.copyWith(
                                    fontSize: isSmallScreen ? 10 : 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 4 : 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  recipe.difficulty,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 10 : 12,
                                    color: AppTheme.primaryColor,
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
