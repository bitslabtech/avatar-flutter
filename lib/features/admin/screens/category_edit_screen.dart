import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/category_provider.dart';
import '../../../providers/upload_provider.dart';
import '../../../core/api/api_endpoints.dart';

class CategoryEditScreen extends ConsumerStatefulWidget {
  final CategoryItem? category;

  const CategoryEditScreen({super.key, this.category});

  @override
  ConsumerState<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends ConsumerState<CategoryEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _descController;
  String _status = 'Active';
  
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _titleController = TextEditingController(text: widget.category?.title ?? '');
    _descController = TextEditingController(text: widget.category?.description ?? '');
    _status = (widget.category?.isActive ?? true) ? 'Active' : 'Inactive';
    _currentImageUrl = widget.category?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isUploading = true;
      });
      
      try {
        final uploadService = ref.read(fileUploadServiceProvider);
        final url = await uploadService.uploadImage(File(image.path));
        setState(() {
          _currentImageUrl = url;
          _isUploading = false;
        });
      } catch (e) {
        setState(() => _isUploading = false);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.category == null) {
      return const Scaffold(body: Center(child: Text('Category Not Found')));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundBlack : AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text('Edit Category', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Image Upload
            // Image Upload (Banner Style)
            GestureDetector(
                onTap: _pickImage,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _selectedImage != null 
                             ? Image.file(_selectedImage!, width: double.infinity, height: 200, fit: BoxFit.contain)
                             : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: ApiEndpoints.resolveImageUrl(_currentImageUrl!),
                                    width: double.infinity, height: 200,
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) => Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate, size: 48, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                                        const SizedBox(height: 8),
                                        Text('Tap to upload Banner', style: TextStyle(color: Colors.grey[400])),
                                      ],
                                    ),
                                  ),
                      ),
                      if (_isUploading)
                        Container(
                          width: double.infinity, height: 200,
                          decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(16)),
                          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                        ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, color: Colors.white, size: 20),
                        ),
                      ),
                      if (_selectedImage != null || (_currentImageUrl != null && _currentImageUrl!.isNotEmpty))
                        Positioned(
                          top: -8, right: -8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = null;
                                _currentImageUrl = '';
                              });
                            },
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? AppColors.backgroundBlack : AppColors.backgroundLight, width: 3),
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Center(
                  child: Text(
                    'Recommended: 800x800 px (or 4:5 Portrait), Max 2MB',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            
            // Name
            _buildLabel('Category Name *', isDark),
            TextField(
              controller: _nameController,
              decoration: _inputDecoration('Enter category name', isDark),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 20),

            // Title
            _buildLabel('Display Title (Optional)', isDark),
            TextField(
              controller: _titleController,
              decoration: _inputDecoration('e.g. "Premium Kitchen"', isDark),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 20),

            // Description
            _buildLabel('Description (Optional)', isDark),
            TextField(
              controller: _descController,
              decoration: _inputDecoration('Short description (6-8 words)', isDark),
              maxLines: 3,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 20),

            // Status
            _buildLabel('Status', isDark),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _status,
                  isExpanded: true,
                  icon: Icon(Icons.expand_more, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontFamily: 'Work Sans',
                  ),
                  items: ['Active', 'Inactive'].map((e) => DropdownMenuItem(
                    value: e, 
                    child: Text(e),
                  )).toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Stats (Read Only)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.inventory, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL PRODUCTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                      Text('${widget.category?.productCount ?? 0} Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Buttons
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 16),
             SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon( 
                onPressed: _showDeleteConfirmation,
                icon: const Icon(Icons.delete),
                label: const Text('Delete Category'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, 
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: isDark ? AppColors.surfaceDark : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary))
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700)),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
       return;
    }

    final success = await ref.read(categoryProvider.notifier).updateCategory(
      id: widget.category!.id, 
      name: _nameController.text, 
      isActive: _status == 'Active',
      imageUrl: _currentImageUrl,
      title: _titleController.text,
      description: _descController.text,
    );
    if (success && mounted) {
      context.pop();
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category Updated')));
    }
  }

  void _showDeleteConfirmation() {
    final deleteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.warning_rounded, color: Colors.red, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Delete Category?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This action is irreversible. All products in "${widget.category!.name}" will be moved to \'Unassigned\'.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: deleteController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'DELETE',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                labelStyle: const TextStyle(fontSize: 12),
                helperText: 'Type "DELETE" to confirm',
              ),
            )
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (deleteController.text == 'DELETE') {
                       final success = await ref.read(categoryProvider.notifier).deleteCategory(widget.category!.id);
                       if (success && context.mounted) {
                         context.pop();
                         context.pop();
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category Deleted')));
                       }
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Type DELETE to confirm')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Delete'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
