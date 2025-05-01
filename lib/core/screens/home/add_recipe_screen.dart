import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/recipe_service.dart';
import '../../services/image_service.dart';
import '../../services/user_service.dart';
import '../../models/recipe.dart';
import '../../theme/app_theme.dart';

class AddRecipeScreen extends StatefulWidget {
  final bool isEditing;

  const AddRecipeScreen({super.key, this.isEditing = false});

  @override
  State<AddRecipeScreen> createState() => AddRecipeScreenState();
}

class AddRecipeScreenState extends State<AddRecipeScreen> {
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
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    cookingTimeController = TextEditingController();
    servingsController = TextEditingController();
    ingredientsController = TextEditingController();
    instructionsController = TextEditingController();
    imageUrlController = TextEditingController();
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
    super.dispose();
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
        id: '', // Firestore will generate this
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
        createdAt: DateTime.now(),
        categories: _selectedCategories,
        cookingTime: int.parse(cookingTimeController.text),
        servings: int.parse(servingsController.text),
        difficulty: _difficulty,
      );

      await RecipeService().addRecipe(recipe);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe added successfully!')),
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
    return Stack(
      children: [
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
              image:
                  _imageUrl != null
                      ? DecorationImage(
                        image: NetworkImage(_imageUrl!),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                _imageUrl == null
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 50,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add recipe image',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    )
                    : null,
          ),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _uploadProgress > 0 ? _uploadProgress : null,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                  if (_uploadProgress > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (_errorMessage != null)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageSection(),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleController,
                decoration: AppTheme.textFieldDecoration('Recipe Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: AppTheme.textFieldDecoration('Description'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
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
                      decoration: AppTheme.textFieldDecoration(
                        'Cooking Time (min)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: servingsController,
                      decoration: AppTheme.textFieldDecoration('Servings'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid number';
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
                decoration: AppTheme.textFieldDecoration('Difficulty'),
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
                decoration: AppTheme.textFieldDecoration(
                  'Image URL (Optional)',
                ),
                validator: null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: ingredientsController,
                decoration: AppTheme.textFieldDecoration(
                  'Ingredients (one per line)',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter ingredients';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: instructionsController,
                decoration: AppTheme.textFieldDecoration(
                  'Instructions (one per line)',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter instructions';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children:
                    _availableCategories.map((category) {
                      return FilterChip(
                        label: Text(category),
                        selected: _selectedCategories.contains(category),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRecipe,
                style: AppTheme.elevatedButtonStyle,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Text(submitButtonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
