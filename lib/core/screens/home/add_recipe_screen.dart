import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../../services/auth_service.dart';
import '../../services/recipe_service.dart';
import '../../services/image_service.dart';
import '../../services/user_service.dart';
import '../../models/recipe.dart';
import '../../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AddRecipeScreen extends StatefulWidget {
  final bool isEditing;
  final Recipe? existingRecipe;

  const AddRecipeScreen({
    super.key,
    this.isEditing = false,
    this.existingRecipe,
  });

  @override
  State<AddRecipeScreen> createState() => AddRecipeScreenState();
}

class AddRecipeScreenState extends State<AddRecipeScreen>
    with SingleTickerProviderStateMixin {
  @protected
  final formKey = GlobalKey<FormState>();
  @protected
  late final TextEditingController titleController;
  @protected
  late final TextEditingController descriptionController;
  @protected
  late final TextEditingController cookingTimeController;
  @protected
  late final TextEditingController servingsController;
  @protected
  late final TextEditingController ingredientsController;
  @protected
  late final TextEditingController instructionsController;
  @protected
  late final TextEditingController imageUrlController;
  String _difficulty = 'Medium';
  List<String> _selectedCategories = [];
  bool _isLoading = false;
  String? _imageUrl;
  final ImageService _imageService = ImageService();
  double _uploadProgress = 0;
  String? _errorMessage;
  late AnimationController _keyboardAnimationController;
  late Animation<double> _keyboardAnimation;

  final List<String> _availableCategories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Dessert',
    'Snack',
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Quick & Easy',
    'Healthy',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupKeyboardAnimation();

    if (widget.existingRecipe != null) {
      _populateExistingRecipe();
    }
  }

  void _setupKeyboardAnimation() {
    _keyboardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _keyboardAnimation = CurvedAnimation(
      parent: _keyboardAnimationController,
      curve: Curves.easeOutExpo,
      reverseCurve: Curves.easeInExpo,
    );

    KeyboardVisibilityController().onChange.listen((bool visible) {
      if (visible) {
        _keyboardAnimationController.forward();
      } else {
        _keyboardAnimationController.reverse();
      }
    });
  }

  void _initializeControllers() {
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    cookingTimeController = TextEditingController();
    servingsController = TextEditingController();
    ingredientsController = TextEditingController();
    instructionsController = TextEditingController();
    imageUrlController = TextEditingController();
  }

  void _populateExistingRecipe() {
    final recipe = widget.existingRecipe!;
    titleController.text = recipe.title;
    descriptionController.text = recipe.description;
    cookingTimeController.text = recipe.cookingTime.toString();
    servingsController.text = recipe.servings.toString();
    _imageUrl = recipe.imageUrl;
    _difficulty = recipe.difficulty;
    _selectedCategories = List.from(recipe.categories);
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _uploadProgress = 0;
    });

    try {
      final imageUrl = await _imageService.pickAndUploadImage(
        source,
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      if (imageUrl != null) {
        setState(() {
          _imageUrl = imageUrl;
          imageUrlController.text = imageUrl;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _uploadProgress = 0;
      });
    }
  }

  Future<void> _submitRecipe() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user profile to use the correct display name
      final userProfile = await UserService().getUserProfileFuture(user.uid);
      final displayName = userProfile?.displayName ?? 'Anonymous';

      final recipe = Recipe(
        id: widget.isEditing ? widget.existingRecipe!.id : '',
        title: titleController.text,
        description: descriptionController.text,
        ingredients:
            ingredientsController.text
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .toList(),
        instructions:
            instructionsController.text
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .toList(),
        imageUrl:
            imageUrlController.text.isEmpty
                ? 'https://via.placeholder.com/400x300?text=No+Image'
                : imageUrlController.text,
        userId: user.uid,
        userName: displayName,
        createdAt:
            widget.isEditing
                ? widget.existingRecipe!.createdAt
                : DateTime.now(),
        categories: _selectedCategories,
        cookingTime: int.parse(cookingTimeController.text),
        servings: int.parse(servingsController.text),
        difficulty: _difficulty,
      );

      if (widget.isEditing) {
        await RecipeService().updateRecipe(recipe);
      } else {
        await RecipeService().addRecipe(recipe);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String get submitButtonText =>
      widget.isEditing ? 'Update Recipe' : 'Add Recipe';

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
        ),
        child:
            _imageUrl != null
                ? Hero(
                  tag: widget.existingRecipe?.id ?? 'new-recipe-image',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: _imageUrl!,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          errorWidget:
                              (context, url, error) => const Icon(
                                Icons.error_outline,
                                size: 50,
                                color: AppTheme.errorColor,
                              ),
                        ),
                        if (_uploadProgress > 0 && _uploadProgress < 1)
                          Container(
                            color: Colors.black54,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: _uploadProgress,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 50,
                      color: AppTheme.textColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add Recipe Photo',
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Recipe' : 'Add New Recipe',
          style: AppTheme.headingStyle,
        ),
        backgroundColor: Color(0xFFADC66A),
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _keyboardAnimation,
        builder: (context, child) {
          final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutExpo,
            tween: Tween<double>(begin: 0, end: bottomPadding),
            builder:
                (context, value, child) => SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    decelerationRate: ScrollDecelerationRate.fast,
                  ),
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16 + (value * _keyboardAnimation.value),
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutExpo,
                          tween: Tween<double>(
                            begin: 0,
                            end: _keyboardAnimation.value,
                          ),
                          builder:
                              (context, value, child) => Transform.translate(
                                offset: Offset(0, -50 * value),
                                child: Opacity(
                                  opacity: 1 - (value * 0.2),
                                  child: _buildImageSection(),
                                ),
                              ),
                        ),
                        const SizedBox(height: 16),
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutExpo,
                          tween: Tween<double>(
                            begin: 0,
                            end: _keyboardAnimation.value,
                          ),
                          builder:
                              (context, value, child) => Transform.translate(
                                offset: Offset(0, -30 * value),
                                child: Opacity(
                                  opacity: 1 - (value * 0.1),
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: titleController,
                                        decoration:
                                            AppTheme.textFieldDecoration(
                                              'Recipe Title',
                                            ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a title';
                                          }
                                          if (value.contains(
                                            RegExp(
                                              r'[^a-zA-Z0-9\s,\-/\u2013\u2014]',
                                            ),
                                          )) {
                                            return 'Title can only contain letters, numbers, spaces, commas, hyphens, dashes, and forward slashes';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: descriptionController,
                                        decoration:
                                            AppTheme.textFieldDecoration(
                                              'Description',
                                            ),
                                        maxLines: 3,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a description';
                                          }
                                          if (value.contains(
                                            RegExp(
                                              r'[^a-zA-Z0-9\s,\-/\u2013\u2014]',
                                            ),
                                          )) {
                                            return 'Description can only contain letters, numbers, spaces, commas, hyphens, dashes, and forward slashes';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: cookingTimeController,
                                              decoration:
                                                  AppTheme.textFieldDecoration(
                                                    'Cooking Time (min)',
                                                  ),
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Required';
                                                }
                                                if (int.tryParse(value) ==
                                                    null) {
                                                  return 'Invalid number';
                                                }
                                                final number = int.parse(value);
                                                if (number <= 0) {
                                                  return 'Cooking time must be positive';
                                                }
                                                if (number > 1440) {
                                                  // 24 hours in minutes
                                                  return 'Cooking time cannot exceed 24 hours';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: TextFormField(
                                              controller: servingsController,
                                              decoration:
                                                  AppTheme.textFieldDecoration(
                                                    'Servings',
                                                  ),
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Required';
                                                }
                                                if (int.tryParse(value) ==
                                                    null) {
                                                  return 'Invalid number';
                                                }
                                                final number = int.parse(value);
                                                if (number <= 0) {
                                                  return 'Servings must be positive';
                                                }
                                                if (number > 100) {
                                                  return 'Servings cannot exceed 100';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      DropdownButtonFormField<String>(
                                        value: _difficulty,
                                        decoration:
                                            AppTheme.textFieldDecoration(
                                              'Difficulty',
                                            ),
                                        items:
                                            ['Easy', 'Medium', 'Hard']
                                                .map(
                                                  (value) => DropdownMenuItem(
                                                    value: value,
                                                    child: Text(value),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() => _difficulty = value);
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: imageUrlController,
                                        decoration:
                                            AppTheme.textFieldDecoration(
                                              'Image URL (Optional)',
                                            ),
                                        validator: null,
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: ingredientsController,
                                        decoration:
                                            AppTheme.textFieldDecoration(
                                              'Ingredients (one per line)',
                                            ),
                                        maxLines: 5,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter ingredients';
                                          }
                                          if (value.contains(
                                            RegExp(
                                              r'[^a-zA-Z0-9\s,\-/\u2013\u2014]',
                                            ),
                                          )) {
                                            return 'Ingredients can only contain letters, numbers, spaces, commas, hyphens, dashes, and forward slashes';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: instructionsController,
                                        decoration:
                                            AppTheme.textFieldDecoration(
                                              'Instructions (one per line)',
                                            ),
                                        maxLines: 5,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter instructions';
                                          }
                                          if (value.contains(
                                            RegExp(
                                              r'[^a-zA-Z0-9\s,\-/\u2013\u2014]',
                                            ),
                                          )) {
                                            return 'Instructions can only contain letters, numbers, spaces, commas, hyphens, dashes, and forward slashes';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Categories',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children:
                                            _availableCategories.map((
                                              category,
                                            ) {
                                              return FilterChip(
                                                label: Text(category),
                                                selected: _selectedCategories
                                                    .contains(category),
                                                onSelected: (selected) {
                                                  setState(() {
                                                    if (selected) {
                                                      _selectedCategories.add(
                                                        category,
                                                      );
                                                    } else {
                                                      _selectedCategories
                                                          .remove(category);
                                                    }
                                                  });
                                                },
                                              );
                                            }).toList(),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton(
                                        onPressed:
                                            _isLoading ? null : _submitRecipe,
                                        style: AppTheme.elevatedButtonStyle
                                            .copyWith(
                                              padding:
                                                  MaterialStateProperty.all(
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 48.0,
                                                      vertical: 16.0,
                                                    ),
                                                  ),
                                              shape: MaterialStateProperty.all(
                                                RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                ),
                                              ),
                                            ),
                                        child:
                                            _isLoading
                                                ? const CircularProgressIndicator()
                                                : Text(
                                                  submitButtonText,
                                                  style:
                                                      AppTheme.buttonTextStyle,
                                                ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    cookingTimeController.dispose();
    servingsController.dispose();
    ingredientsController.dispose();
    instructionsController.dispose();
    imageUrlController.dispose();
    _keyboardAnimationController.dispose();
    super.dispose();
  }
}
