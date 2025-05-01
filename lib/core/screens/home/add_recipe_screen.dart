import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/recipe_service.dart';
import '../../models/recipe.dart';
import '../../theme/app_theme.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cookingTimeController = TextEditingController();
  final _servingsController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _difficulty = 'Medium';
  List<String> _categories = [];
  bool _isLoading = false;

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
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cookingTimeController.dispose();
    _servingsController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _addRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user == null) throw Exception('User not authenticated');

      final recipe = Recipe(
        id: '', // Firestore will generate this
        title: _titleController.text,
        description: _descriptionController.text,
        ingredients:
            _ingredientsController.text
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .toList(),
        instructions:
            _instructionsController.text
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .toList(),
        imageUrl:
            _imageUrlController.text.isEmpty
                ? 'https://via.placeholder.com/400x300?text=No+Image'
                : _imageUrlController.text,
        userId: user.uid,
        userName: user.displayName ?? 'Anonymous',
        createdAt: DateTime.now(),
        categories: _categories,
        cookingTime: int.parse(_cookingTimeController.text),
        servings: int.parse(_servingsController.text),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Add New Recipe', style: AppTheme.headingStyle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
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
                controller: _descriptionController,
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
                      controller: _cookingTimeController,
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
                      controller: _servingsController,
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
                controller: _imageUrlController,
                decoration: AppTheme.textFieldDecoration(
                  'Image URL (Optional)',
                ),
                validator: null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ingredientsController,
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
                controller: _instructionsController,
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
                        selected: _categories.contains(category),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _categories.add(category);
                            } else {
                              _categories.remove(category);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _addRecipe,
                style: AppTheme.elevatedButtonStyle,
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text(
                          'Add Recipe',
                          style: AppTheme.buttonTextStyle,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
