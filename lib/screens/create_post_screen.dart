import 'dart:io';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class CreatePostScreen extends StatefulWidget {
  final PostModel? post; // If provided, edit mode

  const CreatePostScreen({super.key, this.post});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  final _authService = AuthService();
  final _postService = PostService();
  final _storageService = StorageService();

  PostType _selectedType = PostType.lost;
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;
  bool get _isEditMode => widget.post != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _titleController.text = widget.post!.title;
      _descriptionController.text = widget.post!.description;
      _locationController.text = widget.post!.location;
      _selectedType = widget.post!.type;
      _existingImageUrl = widget.post!.imageUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () async {
                Navigator.of(context).pop();
                File? image = await _storageService.pickImageFromGallery();
                if (image != null) {
                  setState(() {
                    _selectedImage = image;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () async {
                Navigator.of(context).pop();
                File? image = await _storageService.pickImageFromCamera();
                if (image != null) {
                  setState(() {
                    _selectedImage = image;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _existingImageUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        imageUrl = await _storageService.uploadPostImage(
          _selectedImage!,
          _authService.currentUser!.uid,
        );
      }

      // Get user data
      UserModel? user = await _authService.getUserData(
        _authService.currentUser!.uid,
      );

      PostModel post = PostModel(
        id: _isEditMode ? widget.post!.id : null,
        userId: _authService.currentUser!.uid,
        userName: user?.name ?? 'Usuario',
        type: _selectedType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        imageUrl: imageUrl,
        status: _isEditMode ? widget.post!.status : PostStatus.active,
        viewCount: _isEditMode ? widget.post!.viewCount : 0,
        messageCount: _isEditMode ? widget.post!.messageCount : 0,
        createdAt: _isEditMode ? widget.post!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditMode) {
        await _postService.updatePost(widget.post!.id!, post);
      } else {
        await _postService.createPost(post);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Publicación actualizada'
                : 'Publicación creada exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
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
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Publicación' : 'Nueva Publicación'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Publicar',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Selector
              const Text(
                'Tipo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TypeOption(
                      type: PostType.lost,
                      selected: _selectedType == PostType.lost,
                      onTap: () => setState(() => _selectedType = PostType.lost),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeOption(
                      type: PostType.found,
                      selected: _selectedType == PostType.found,
                      onTap: () =>
                          setState(() => _selectedType = PostType.found),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Image Upload
              const Text(
                'Foto',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.bgTertiary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.borderMedium,
                      width: 3,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _selectedImage != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Cambiar foto',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : (_existingImageUrl != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    _existingImageUrl!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Cambiar foto',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 48,
                                  color: AppTheme.textTertiary,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Agregar foto',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textTertiary,
                                  ),
                                ),
                              ],
                            )),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              CustomTextField(
                controller: _titleController,
                label: 'Título',
                hint: 'Ej: mochila con laptop',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description
              CustomTextField(
                controller: _descriptionController,
                label: 'Descripción',
                hint: 'Describe el objeto con el mayor detalle posible...',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Location
              CustomTextField(
                controller: _locationController,
                label: 'Ubicación',
                hint: 'Ej: Parque Central',
                prefixIcon: Icons.location_on,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una ubicación';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                text: _isEditMode ? 'Guardar cambios' : 'Publicar',
                onPressed: _savePost,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final PostType type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: selected
              ? (type == PostType.lost
                  ? AppTheme.lostGradient
                  : AppTheme.foundGradient)
              : null,
          color: !selected ? AppTheme.bgTertiary : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? (type == PostType.lost
                    ? AppTheme.lostColorDark
                    : AppTheme.foundColorDark)
                : AppTheme.borderLight,
            width: 3,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: (type == PostType.lost
                            ? AppTheme.errorColor
                            : AppTheme.successColor)
                        .withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              type == PostType.lost ? Icons.search : Icons.star,
              size: 32,
              color: selected
                  ? (type == PostType.lost
                      ? AppTheme.lostTextColor
                      : AppTheme.foundTextColor)
                  : AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              type == PostType.lost ? 'Perdido' : 'Encontrado',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected
                    ? (type == PostType.lost
                        ? AppTheme.lostTextColor
                        : AppTheme.foundTextColor)
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

