import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product.dart';
import '../providers/product_management_provider.dart';
import '../providers/brand_provider.dart';
import '../providers/category_provider.dart';
import '../providers/gst_provider.dart';
import '../../../providers/upload_provider.dart';

class ProductAddEditScreen extends ConsumerStatefulWidget {
  final Product? product;

  const ProductAddEditScreen({super.key, this.product});

  @override
  ConsumerState<ProductAddEditScreen> createState() => _ProductAddEditScreenState();
}

class _ProductAddEditScreenState extends ConsumerState<ProductAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _priceController;
  late final TextEditingController _mrpController;
  late final TextEditingController _descriptionController;
  
  // Variation Controllers (New)
  late final TextEditingController _variationGroupController;
  late final TextEditingController _variantController;
  late final TextEditingController _sizeController;
  
  // State
  bool _isActive = true;
  String? _selectedBrandId;
  String? _selectedCategoryId;
  double? _selectedGstPercent;
  String? _selectedVariationType; // e.g. Color, Size
  String? _selectedBadge;

  // Images
  List<String> _imageUrls = [];
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  // Specs (List of MapEntries for easier editing)
  List<MapEntry<TextEditingController, TextEditingController>> _specsControllers = [];
  
  // Loading
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    
    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _priceController = TextEditingController(text: p?.price?.toString() ?? ''); 
    _mrpController = TextEditingController(text: p?.mrp?.toString() ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    
    // Init Variation Controllers
    _variationGroupController = TextEditingController(text: p?.variationGroupId ?? '');
    _variantController = TextEditingController(text: p?.variant ?? '');
    _sizeController = TextEditingController(text: p?.size ?? '');

    _isActive = p?.isActive ?? true;
    _selectedGstPercent = p?.gstPercent ?? p?.taxPercent; // Handle legacy taxPercent if needed
    _selectedVariationType = p?.variationType;
    _selectedBadge = p?.badge;

    _imageUrls = List.from(p?.images ?? []);

    _selectedBrandId = p?.brandId;    
    _selectedCategoryId = p?.categoryId;

    // Specs
    if (p?.specs != null) {
      p!.specs!.forEach((key, value) {
        _specsControllers.add(MapEntry(
          TextEditingController(text: key),
          TextEditingController(text: value.toString()),
        ));
      });
    }

    // Load Data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(brandProvider.notifier).loadBrands();
      ref.read(categoryProvider.notifier).loadCategories();
      ref.read(gstProvider.notifier).loadGstRates();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _mrpController.dispose();
    _descriptionController.dispose();
    
    _variationGroupController.dispose();
    _variantController.dispose();
    _sizeController.dispose();

    for (var element in _specsControllers) {
      element.key.dispose();
      element.value.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUploadImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isEmpty) return;

      setState(() => _isUploading = true);
      
      final uploadService = ref.read(fileUploadServiceProvider);
      
      for (var image in images) {
        try {
          final url = await uploadService.uploadImage(File(image.path));
          setState(() {
            _imageUrls.add(url);
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload ${image.name}')));
          }
        }
      }

      setState(() {
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  void _addSpecRow() {
    setState(() {
      _specsControllers.add(MapEntry(TextEditingController(), TextEditingController()));
    });
  }

  void _removeSpecRow(int index) {
    final entry = _specsControllers[index];
    entry.key.dispose();
    entry.value.dispose();
    setState(() {
      _specsControllers.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_imageUrls.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one image')));
       return;
    }
    
    if (_selectedBrandId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a brand')));
        return;
    }
    
    if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
        return;
    }

    if (_selectedGstPercent == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select GST %')));
        return;
    }

    setState(() => _isSaving = true);

    // Prepare Payload
    final specsMap = <String, dynamic>{};
    for (var element in _specsControllers) {
      if (element.key.text.isNotEmpty) {
        specsMap[element.key.text] = element.value.text;
      }
    }

    // Convert string inputs "123.45" to numbers
    final priceVal = double.tryParse(_priceController.text) ?? 0;
    final mrpVal = double.tryParse(_mrpController.text);

    final payload = {
      'name': _nameController.text,
      'sku': _skuController.text,
      'price': priceVal,
      'mrp': mrpVal,
      'gstPercent': _selectedGstPercent,
      'description': _descriptionController.text,
      'isActive': _isActive,
      // 'installationRequired': false, // Removed as per request
      'brandId': _selectedBrandId,
      'categoryId': _selectedCategoryId,
      'images': _imageUrls,
      'specifications': specsMap,
      
      // Variation Fields
      'variationGroupId': _variationGroupController.text.isEmpty ? null : _variationGroupController.text,
      'variationType': _selectedVariationType,
      'variant': _variantController.text.isEmpty ? null : _variantController.text,
      'size': _sizeController.text.isEmpty ? null : _sizeController.text,
      'badge': _selectedBadge,
    };

    final notifier = ref.read(productManagementProvider.notifier);
    dynamic result;
    
    if (widget.product != null) {
      result = await notifier.updateProduct(widget.product!.id, payload);
    } else {
      result = await notifier.createProduct(payload);
    }

    setState(() => _isSaving = false);
    
    if (mounted) {
      if (result == true) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.product != null ? 'Product updated' : 'Product created'),
          backgroundColor: AppColors.successGreen,
        ));
      } else {
         final errorMsg = result is String ? result : 'Failed to save product';
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: Text(errorMsg), 
           backgroundColor: Colors.red
         ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandState = ref.watch(brandProvider);
    final categoryState = ref.watch(categoryProvider);
    final gstState = ref.watch(gstProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundBlack : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.product != null ? 'Edit Product' : 'Add Product'),
        backgroundColor: isDark ? AppColors.backgroundBlack : Colors.white,
        elevation: 0,
         leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProduct,
            child: _isSaving 
               ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
               : const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info
              _buildSectionTitle(isDark, 'Basic Information'),
              const SizedBox(height: 16),
              _buildTextField(isDark, _nameController, 'Product Name', icon: Icons.shopping_bag),
              const SizedBox(height: 12),
              _buildTextField(isDark, _skuController, 'SKU', icon: Icons.qr_code),
              const SizedBox(height: 12),
              _buildTextField(isDark, _descriptionController, 'Description', icon: Icons.description, maxLines: 3),
              const SizedBox(height: 12),
              
              // Associations
              Row(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final items = brandState.brands.map((b) => DropdownMenuItem(
                          value: b.id, 
                          child: Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark?Colors.white:Colors.black))
                        )).toList();
                        
                        // Robust Handle: Add missing Brand ID if needed
                        if (_selectedBrandId != null && !brandState.brands.any((b) => b.id == _selectedBrandId)) {
                           items.add(DropdownMenuItem(
                             value: _selectedBrandId,
                             child: Text('Unknown Brand', style: TextStyle(color: Colors.red.shade300, fontStyle: FontStyle.italic)),
                           ));
                        }

                        return _buildDropdown(
                          isDark, 
                          'Brand', 
                          _selectedBrandId,
                          items,
                          (val) => setState(() => _selectedBrandId = val as String?),
                        );
                      }
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final items = categoryState.categories.map((c) => DropdownMenuItem(
                          value: c.id, 
                          child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark?Colors.white:Colors.black))
                        )).toList();

                        // Robust Handle: Add missing Category ID if needed
                        if (_selectedCategoryId != null && !categoryState.categories.any((c) => c.id == _selectedCategoryId)) {
                           items.add(DropdownMenuItem(
                             value: _selectedCategoryId,
                             child: Text('Unknown Category', style: TextStyle(color: Colors.red.shade300, fontStyle: FontStyle.italic)),
                           ));
                        }
                        
                        return _buildDropdown(
                          isDark, 
                          'Category', 
                          _selectedCategoryId,
                          items,
                          (val) => setState(() => _selectedCategoryId = val as String?),
                        );
                      }
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Product Variations
              _buildSectionTitle(isDark, 'Variations & Grouping'),
              const SizedBox(height: 8),
              Text(
                'Link this product to others (e.g. Red Shirt L linked to Red Shirt M)',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                isDark, 
                _variationGroupController, 
                'Group ID (Optional)', 
                icon: Icons.link,
                validator: (val) => null // Optional
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                   final List<String> typeItems = ['None', 'Color', 'Size', 'Color & Size', 'Style', 'Material'];
                   if (_selectedVariationType != null && _selectedVariationType!.isNotEmpty && !typeItems.contains(_selectedVariationType)) {
                     typeItems.add(_selectedVariationType!);
                   }
                   
                   return Row(
                    children: [
                       Expanded(
                         child: _buildDropdown(
                           isDark,
                           'What Varies?',
                           // Ensure value is not empty string, default to null or 'None'
                           (_selectedVariationType == null || _selectedVariationType!.isEmpty) ? 'None' : _selectedVariationType,
                           typeItems.map((e) => 
                             DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: isDark?Colors.white:Colors.black)))
                           ).toList(),
                           (val) => setState(() => _selectedVariationType = val as String?),
                         ),
                       ),
                    ],
                  );
                }
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final type = _selectedVariationType?.toLowerCase() ?? '';
                  final isMaterial = type.contains('material');
                  final showVariant = type.isEmpty || type.contains('color') || type.contains('style') || type.contains('mixture') || type == 'color & size' || isMaterial;
                  final showSize = type.isEmpty || type.contains('size') || type.contains('dimension') || type == 'color & size';
                  
                  String variantLabel = 'Variant (e.g. Red)';
                  if (type.contains('color')) variantLabel = 'Color (e.g. Red)';
                  else if (isMaterial) variantLabel = 'Material (e.g. Steel)';
                  else if (type.contains('style')) variantLabel = 'Style (e.g. Modern)';

                  return Row(
                    children: [
                      if (showVariant)
                        Expanded(child: _buildTextField(isDark, _variantController, variantLabel, icon: isMaterial ? Icons.build : (type.contains('style') ? Icons.style : Icons.palette))),
                      if (showVariant && showSize)
                        const SizedBox(width: 12),
                      if (showSize)
                        Expanded(child: _buildTextField(isDark, _sizeController, 'Size (e.g. XL)', icon: Icons.straighten)),
                    ],
                  );
                }
              ),
              const SizedBox(height: 24),
              
              // Pricing
              _buildSectionTitle(isDark, 'Pricing & Tax'),
              const SizedBox(height: 16),
              Row(
                children: [
                   // Renamed "Dealer Price" to "Display Price"
                  Expanded(child: _buildTextField(isDark, _priceController, 'Display Price (₹)', isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(isDark, _mrpController, 'MRP (₹)', isNumber: true)),
                ],
              ),
              const SizedBox(height: 12),
              // GST Dropdown
              Builder(
                builder: (context) {
                  final items = gstState.rates.map((g) => 
                    DropdownMenuItem(
                      value: g.percentage.toDouble(), 
                      child: Text('${g.percentage}%', style: TextStyle(color: isDark?Colors.white:Colors.black))
                    )
                  ).toList();

                  // Robust Handle: Add missing GST Rate if needed
                  if (_selectedGstPercent != null && !gstState.rates.any((g) => g.percentage.toDouble() == _selectedGstPercent)) {
                     items.add(DropdownMenuItem(
                       value: _selectedGstPercent,
                       child: Text('${_selectedGstPercent}% (Legacy)', style: TextStyle(color: Colors.amber, fontStyle: FontStyle.italic)),
                     ));
                  }

                  return _buildDropdown(
                    isDark,
                    'GST %',
                    _selectedGstPercent,
                    items,
                    (val) => setState(() => _selectedGstPercent = val as double?),
                  );
                }
              ),

              
              const SizedBox(height: 24),

              // Status
              _buildSectionTitle(isDark, 'Settings'),
               SwitchListTile(
                 title: Text('Active Status', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                 subtitle: Text('Visible to customers', style: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade600, fontSize: 12)),
                 value: _isActive,
                 onChanged: (v) => setState(() => _isActive = v),
                 activeColor: Theme.of(context).colorScheme.primary,
                 contentPadding: EdgeInsets.zero,
               ),
               // Removed Installation Required Switch
               const SizedBox(height: 12),
               
               // Badge Dropdown
               _buildDropdown(
                 isDark,
                 'Product Badge (Optional)',
                 _selectedBadge,
                 [
                   const DropdownMenuItem(value: null, child: Text('None')),
                   const DropdownMenuItem(value: 'New', child: Text('New')),
                   const DropdownMenuItem(value: 'Popular', child: Text('Popular')),
                   const DropdownMenuItem(value: 'Bestseller', child: Text('Bestseller')),
                   const DropdownMenuItem(value: 'Trending', child: Text('Trending')),
                   const DropdownMenuItem(value: 'Limited', child: Text('Limited')),
                 ],
                 (val) => setState(() => _selectedBadge = val as String?),
                 isRequired: false,
               ),

              const SizedBox(height: 24),

              // Images
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle(isDark, 'Images'),
                   TextButton.icon(
                     onPressed: _isUploading ? null : _pickAndUploadImages, 
                     icon: const Icon(Icons.add_photo_alternate),
                     label: const Text('Add Images'),
                     style: TextButton.styleFrom(
                       foregroundColor: Theme.of(context).colorScheme.primary,
                       backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                     ),
                   ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text(
                  'Recommended: 800x800 px (Square), Max 2MB. You can select multiple images.',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600], fontStyle: FontStyle.italic),
                ),
              ),
              if (_isUploading) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
                const SizedBox(height: 4),
                Text('Uploading images...', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
              ],
              const SizedBox(height: 12),
              if (_imageUrls.isEmpty)
                 InkWell(
                   onTap: _isUploading ? null : _pickAndUploadImages,
                   borderRadius: BorderRadius.circular(12),
                   child: Container(
                     height: 120, 
                     width: double.infinity,
                     decoration: BoxDecoration(
                       border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, width: 2, style: BorderStyle.solid), 
                       borderRadius: BorderRadius.circular(12),
                       color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
                     ),
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(Icons.cloud_upload_outlined, size: 32, color: Theme.of(context).colorScheme.primary),
                         const SizedBox(height: 8),
                         Text("Tap to browse gallery", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.w500)),
                       ],
                     ),
                   ),
                 )
              else 
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imageUrls.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _imageUrls.length) {
                        // Add more button at the end
                        return GestureDetector(
                          onTap: _isUploading ? null : _pickAndUploadImages,
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), width: 1.5),
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, color: Theme.of(context).colorScheme.primary, size: 28),
                                const SizedBox(height: 8),
                                Text('Add More', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      final resolvedUrl = Product.resolveImageUrl(_imageUrls[index]);
                      return Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 140,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                              color: isDark ? Colors.grey[800] : Colors.grey[100],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: CachedNetworkImage(
                              imageUrl: resolvedUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                              errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                          Positioned(
                            right: 16, top: 4,
                            child: InkWell(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white)
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),

              // Specifications
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle(isDark, 'Specifications'),
                  TextButton.icon(
                    onPressed: _addSpecRow,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Spec'),
                  ),
                ],
              ),
              ..._specsControllers.asMap().entries.map((entry) {
                 final index = entry.key;
                 final pair = entry.value;
                 return Padding(
                   padding: const EdgeInsets.only(bottom: 8),
                   child: Row(
                     children: [
                       Expanded(child: _buildTextField(isDark, pair.key, 'Key (e.g. Color)', isDense: true)),
                       const SizedBox(width: 8),
                       Expanded(child: _buildTextField(isDark, pair.value, 'Value (e.g. Red)', isDense: true)),
                       IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeSpecRow(index)),
                     ],
                   ),
                 );
              }),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(bool isDark, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildTextField(bool isDark, TextEditingController controller, String label, {bool isNumber = false, IconData? icon, bool isDense = false, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      validator: validator ?? (val) => val == null || val.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        prefixIcon: icon != null ? Icon(icon, size: 20, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600) : null,
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        isDense: isDense,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade300)),
      ),
    );
  }

  Widget _buildDropdown(bool isDark, String label, dynamic value, List<DropdownMenuItem<Object>> items, ValueChanged onChanged, {bool isRequired = true}) {
    return DropdownButtonFormField(
      value: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.grey : Colors.grey.shade600),
      validator: isRequired ? (val) => val == null ? 'Required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
      ),
    );
  }
}
