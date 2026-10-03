import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Dynamic Pricing Controllers
  late final TextEditingController _productCostController;
  late final TextEditingController _boxCostController;
  late final TextEditingController _handlingFeeController;
  late final TextEditingController _marginPercentController;
  late final TextEditingController _dpPercentController;
  bool _roundOffNetSales = true;
  bool _roundOffNetDp = true;
  
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
  final List<MapEntry<TextEditingController, TextEditingController>> _specsControllers = [];
  
  // Loading
  bool _isSaving = false;

  // Pricing Engine Mathematical Getters
  double get _productCost => double.tryParse(_productCostController.text) ?? 0.0;
  double get _boxCost => double.tryParse(_boxCostController.text) ?? 0.0;
  double get _handlingFee => double.tryParse(_handlingFeeController.text) ?? 0.0;
  double get _purchaseCost => _productCost + _boxCost + _handlingFee;

  double get _marginPercent => double.tryParse(_marginPercentController.text) ?? 25.0;
  double get _marginAmount => _purchaseCost * (_marginPercent / 100.0);
  double get _priceAfterMargin => _purchaseCost + _marginAmount;

  double get _effectiveGstPercent => _selectedGstPercent ?? 18.0;
  double get _gstAmount => _priceAfterMargin * (_effectiveGstPercent / 100.0);

  double get _netSalesPrice => _priceAfterMargin + _gstAmount;
  double get _netSalesPriceRounded => _netSalesPrice.roundToDouble();
  double get _effectiveNetSalesPrice => _roundOffNetSales ? _netSalesPriceRounded : _netSalesPrice;

  double get _dpPercent => double.tryParse(_dpPercentController.text) ?? 25.0;
  double get _netDpAmount => _effectiveNetSalesPrice * (_dpPercent / 100.0);
  double get _netDp => _effectiveNetSalesPrice + _netDpAmount;
  double get _netDpRounded => _netDp.roundToDouble();
  double get _effectiveNetDp => _roundOffNetDp ? _netDpRounded : _netDp;

  void _onPriceParamChanged() {
    if (mounted) {
      setState(() {
        if (_purchaseCost > 0) {
          final roundedVal = _roundOffNetDp ? _effectiveNetDp.round() : _effectiveNetDp;
          _priceController.text = _roundOffNetDp ? roundedVal.toString() : _effectiveNetDp.toStringAsFixed(2);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    
    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _priceController = TextEditingController(text: p?.price?.toString() ?? ''); 
    _mrpController = TextEditingController(text: p?.mrp?.toString() ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');

    // Pricing details from specs if previously saved
    final productSpecs = p?.specs;
    Map<String, dynamic>? pricingDetails;
    if (productSpecs != null && productSpecs['pricingDetails'] != null) {
      final raw = productSpecs['pricingDetails'];
      if (raw is Map) {
        pricingDetails = Map<String, dynamic>.from(raw);
      }
    }

    if (pricingDetails != null) {
      _productCostController = TextEditingController(
        text: (pricingDetails['productCost'] != null && pricingDetails['productCost'] != 0)
            ? pricingDetails['productCost'].toString()
            : '',
      );
      _boxCostController = TextEditingController(
        text: (pricingDetails['boxCost'] != null && pricingDetails['boxCost'] != 0)
            ? pricingDetails['boxCost'].toString()
            : '',
      );
      _handlingFeeController = TextEditingController(
        text: (pricingDetails['handlingFee'] != null && pricingDetails['handlingFee'] != 0)
            ? pricingDetails['handlingFee'].toString()
            : '',
      );
      _marginPercentController = TextEditingController(
        text: pricingDetails['marginPercent']?.toString() ?? '25',
      );
      _dpPercentController = TextEditingController(
        text: pricingDetails['dpPercent']?.toString() ?? '25',
      );
      _roundOffNetSales = pricingDetails['roundOffNetSales'] ?? true;
      _roundOffNetDp = pricingDetails['roundOffNetDp'] ?? true;
      if (pricingDetails['gstPercent'] != null) {
        _selectedGstPercent = double.tryParse(pricingDetails['gstPercent'].toString());
      }
    } else {
      _productCostController = TextEditingController();
      _boxCostController = TextEditingController();
      _handlingFeeController = TextEditingController();
      _marginPercentController = TextEditingController(text: '25');
      _dpPercentController = TextEditingController(text: '25');
      _roundOffNetSales = true;
      _roundOffNetDp = true;
    }

    _productCostController.addListener(_onPriceParamChanged);
    _boxCostController.addListener(_onPriceParamChanged);
    _handlingFeeController.addListener(_onPriceParamChanged);
    _marginPercentController.addListener(_onPriceParamChanged);
    _dpPercentController.addListener(_onPriceParamChanged);
    _mrpController.addListener(() => setState(() {}));
    
    // Init Variation Controllers
    _variationGroupController = TextEditingController(text: p?.variationGroupId ?? '');
    _variantController = TextEditingController(text: p?.variant ?? '');
    _sizeController = TextEditingController(text: p?.size ?? '');

    _isActive = p?.isActive ?? true;
    _selectedGstPercent = _selectedGstPercent ?? p?.gstPercent ?? p?.taxPercent ?? 18.0;
    _selectedVariationType = p?.variationType;
    _selectedBadge = p?.badge;

    _imageUrls = List.from(p?.images ?? []);

    _selectedBrandId = p?.brandId;    
    _selectedCategoryId = p?.categoryId;

    // Specs - exclude internal pricing details
    if (productSpecs != null) {
      productSpecs.forEach((key, value) {
        if (key != 'pricingDetails' && key != '_pricingDetails') {
          _specsControllers.add(MapEntry(
            TextEditingController(text: key),
            TextEditingController(text: value.toString()),
          ));
        }
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

    _productCostController.removeListener(_onPriceParamChanged);
    _boxCostController.removeListener(_onPriceParamChanged);
    _handlingFeeController.removeListener(_onPriceParamChanged);
    _marginPercentController.removeListener(_onPriceParamChanged);
    _dpPercentController.removeListener(_onPriceParamChanged);

    _productCostController.dispose();
    _boxCostController.dispose();
    _handlingFeeController.dispose();
    _marginPercentController.dispose();
    _dpPercentController.dispose();
    
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
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 70, maxHeight: 1200, maxWidth: 1200);
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

    // Compute final dealer price (D.P.)
    final computedDp = _effectiveNetDp;
    final priceVal = computedDp > 0
        ? computedDp
        : (double.tryParse(_priceController.text) ?? 0.0);
    final mrpVal = double.tryParse(_mrpController.text);

    if (priceVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter product costs or a valid price')),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Prepare Payload
    final specsMap = <String, dynamic>{};
    for (var element in _specsControllers) {
      if (element.key.text.isNotEmpty &&
          element.key.text != 'pricingDetails' &&
          element.key.text != '_pricingDetails') {
        specsMap[element.key.text] = element.value.text;
      }
    }

    // Save comprehensive pricing breakdown
    specsMap['pricingDetails'] = {
      'productCost': _productCost,
      'boxCost': _boxCost,
      'handlingFee': _handlingFee,
      'purchaseCost': _purchaseCost,
      'marginPercent': _marginPercent,
      'marginAmount': _marginAmount,
      'priceAfterMargin': _priceAfterMargin,
      'gstPercent': _effectiveGstPercent,
      'gstAmount': _gstAmount,
      'netSalesPrice': _netSalesPrice,
      'roundOffNetSales': _roundOffNetSales,
      'netSalesPriceFinal': _effectiveNetSalesPrice,
      'dpPercent': _dpPercent,
      'netDp': _netDp,
      'roundOffNetDp': _roundOffNetDp,
      'dealerPrice': priceVal,
    };

    final payload = {
      'name': _nameController.text,
      'sku': _skuController.text,
      'price': priceVal,
      'mrp': mrpVal,
      'gstPercent': _effectiveGstPercent.toInt(),
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

              // Product Variations Summary Card (Opens Bottom Sheet)
              _buildVariationsSummaryCard(isDark),
              const SizedBox(height: 20),

              // Pricing Summary Card (Opens Bottom Sheet)
              _buildPricingSummaryCard(isDark, gstState),
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
                  Expanded(child: _buildSectionTitle(isDark, 'Images')),
                  const SizedBox(width: 8),
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
                  Expanded(child: _buildSectionTitle(isDark, 'Specifications')),
                  const SizedBox(width: 8),
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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTextField(bool isDark, TextEditingController controller, String label, {bool isNumber = false, IconData? icon, bool isDense = false, int maxLines = 1, String? Function(String?)? validator, ValueChanged<String>? onChanged}) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
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

  // ==================== VARIATIONS SECTION ====================

  Widget _buildVariationsSummaryCard(bool isDark) {
    final cardBorderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final textMutedColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final hasGroup = _variationGroupController.text.trim().isNotEmpty;
    final hasType = _selectedVariationType != null &&
        _selectedVariationType!.isNotEmpty &&
        _selectedVariationType != 'None';
    final hasVariant = _variantController.text.trim().isNotEmpty;
    final hasSize = _sizeController.text.trim().isNotEmpty;
    final isConfigured = hasGroup || hasType || hasVariant || hasSize;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openVariationsBottomSheet(context, isDark),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.style_outlined, color: Colors.purple, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Variations & Grouping',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isConfigured ? 'Variations configured' : 'Colors, sizes, materials & grouping',
                                  style: TextStyle(fontSize: 12, color: textMutedColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isConfigured ? Colors.purple.withOpacity(0.12) : (isDark ? Colors.white10 : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isConfigured ? 'Edit' : 'Configure',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isConfigured ? Colors.purple : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: isConfigured ? Colors.purple : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isConfigured) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (hasGroup)
                        _buildSummaryBadge(isDark, Icons.link, 'Group: ${_variationGroupController.text.trim()}'),
                      if (hasType)
                        _buildSummaryBadge(isDark, Icons.category_outlined, 'Type: $_selectedVariationType'),
                      if (hasVariant)
                        _buildSummaryBadge(isDark, Icons.palette_outlined, 'Variant: ${_variantController.text.trim()}'),
                      if (hasSize)
                        _buildSummaryBadge(isDark, Icons.straighten, 'Size: ${_sizeController.text.trim()}'),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black12 : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cardBorderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, size: 18, color: textMutedColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No variations linked. Tap to open bottom sheet.',
                            style: TextStyle(fontSize: 12, color: textMutedColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openVariationsBottomSheet(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final type = _selectedVariationType?.toLowerCase() ?? '';
            final isMaterial = type.contains('material');
            final showVariant = type.isEmpty ||
                type.contains('color') ||
                type.contains('style') ||
                type.contains('mixture') ||
                type == 'color & size' ||
                isMaterial;
            final showSize = type.isEmpty ||
                type.contains('size') ||
                type.contains('dimension') ||
                type == 'color & size';

            String variantLabel = 'Variant (e.g. Red)';
            if (type.contains('color')) {
              variantLabel = 'Color (e.g. Red, Blue, Black)';
            } else if (isMaterial) {
              variantLabel = 'Material (e.g. Stainless Steel, Wood)';
            } else if (type.contains('style')) {
              variantLabel = 'Style (e.g. Modern, Vintage)';
            }

            final List<String> typeItems = ['None', 'Color', 'Size', 'Color & Size', 'Style', 'Material'];
            if (_selectedVariationType != null &&
                _selectedVariationType!.isNotEmpty &&
                !typeItems.contains(_selectedVariationType)) {
              typeItems.add(_selectedVariationType!);
            }

            return Container(
              height: MediaQuery.of(sheetContext).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Grab Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.style_outlined, color: Colors.purple, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Product Variations',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Link options like Color, Size or Style',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: Icon(Icons.close, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Group Identification',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Products with the same Group ID will be linked together on the product page.',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            isDark,
                            _variationGroupController,
                            'Group ID (e.g. SHIRT-SLIM-2026)',
                            icon: Icons.link,
                            validator: (val) => null,
                            onChanged: (val) => setSheetState(() {}),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Variation Attributes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Specify what makes this item unique compared to other variants.',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                          const SizedBox(height: 12),

                          _buildDropdown(
                            isDark,
                            'What Varies?',
                            (_selectedVariationType == null || _selectedVariationType!.isEmpty)
                                ? 'None'
                                : _selectedVariationType,
                            typeItems
                                .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e, style: TextStyle(color: isDark ? Colors.white : Colors.black))))
                                .toList(),
                            (val) {
                              setSheetState(() => _selectedVariationType = val as String?);
                              setState(() => _selectedVariationType = val as String?);
                            },
                          ),
                          const SizedBox(height: 14),

                          if (showVariant) ...[
                            _buildTextField(
                              isDark,
                              _variantController,
                              variantLabel,
                              icon: isMaterial ? Icons.build : (type.contains('style') ? Icons.style : Icons.palette),
                              onChanged: (val) => setSheetState(() {}),
                            ),
                            const SizedBox(height: 14),
                          ],

                          if (showSize) ...[
                            _buildTextField(
                              isDark,
                              _sizeController,
                              'Size (e.g. S, M, L, XL, 42, 10mm)',
                              icon: Icons.straighten,
                              onChanged: (val) => setSheetState(() {}),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Customer Preview
                          if (_variantController.text.isNotEmpty || _sizeController.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black26 : Colors.purple.shade50.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.purple.withOpacity(0.25)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.remove_red_eye_outlined, size: 18, color: Colors.purple),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Customer Badge Preview:',
                                            style: TextStyle(
                                                fontSize: 11, fontWeight: FontWeight.w600, color: Colors.purple)),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 6,
                                          children: [
                                            if (_variantController.text.isNotEmpty)
                                              Chip(
                                                label: Text(_variantController.text,
                                                    style: const TextStyle(
                                                        fontSize: 11, fontWeight: FontWeight.bold)),
                                                backgroundColor: isDark
                                                    ? Colors.purple.shade900.withOpacity(0.5)
                                                    : Colors.purple.shade100,
                                                padding: EdgeInsets.zero,
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                            if (_sizeController.text.isNotEmpty)
                                              Chip(
                                                label: Text(_sizeController.text,
                                                    style: const TextStyle(
                                                        fontSize: 11, fontWeight: FontWeight.bold)),
                                                backgroundColor: isDark
                                                    ? Colors.purple.shade900.withOpacity(0.5)
                                                    : Colors.purple.shade100,
                                                padding: EdgeInsets.zero,
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      border: Border(top: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(sheetContext).pop();
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Apply Variations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  // ==================== PRICING SECTION ====================

  Widget _buildPricingSummaryCard(bool isDark, GstState gstState) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardBorderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final textMutedColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final hasCosts = _purchaseCost > 0;
    final displayDp = _effectiveNetDp > 0
        ? _effectiveNetDp
        : (double.tryParse(_priceController.text) ?? 0.0);
    final mrpVal = double.tryParse(_mrpController.text) ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPricingBottomSheet(context, isDark, gstState),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.calculate_outlined, color: primaryColor, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pricing & Cost Breakdown',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasCosts ? 'Costs, margin & dealer price calculated' : 'Direct costs, margin, GST & D.P.',
                                  style: TextStyle(fontSize: 12, color: textMutedColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune_rounded, size: 13, color: primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            'Edit Price',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_forward_ios_rounded, size: 10, color: primaryColor),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Top Key Numbers Row (Final D.P. & Consumer MRP)
                Row(
                  children: [
                    // Dealer Price Card (Green Box)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF152A1E) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.green.shade900 : Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Dealer Price (D.P.)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.green.shade300 : Colors.green.shade800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_roundOffNetDp) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Round',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.green.shade300 : Colors.green.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                displayDp > 0 ? '₹${displayDp.toStringAsFixed(2)}' : '₹0.00',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.green.shade300 : Colors.green.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Selling Price',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? Colors.green.shade200.withOpacity(0.6)
                                      : Colors.green.shade700.withOpacity(0.8)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Consumer MRP Card (Avatar Crimson & Retail Theme)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF221719) : const Color(0xFFFFF5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF4D1D22) : const Color(0xFFFFD5D8),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Consumer MRP',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFFFF8A8C) : const Color(0xFFC51D23),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF381B1E) : const Color(0xFFFFE4E6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Retail',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFFFF8A8C) : const Color(0xFFC51D23),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                mrpVal > 0 ? '₹${mrpVal.toStringAsFixed(2)}' : 'Not Set',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: mrpVal > 0
                                      ? (isDark ? const Color(0xFFFF6B6E) : const Color(0xFFD32023))
                                      : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mrpVal > 0 ? 'Catalog Retail' : 'Tap to set MRP',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? const Color(0xFFFF8A8C).withOpacity(0.7)
                                    : const Color(0xFFC51D23).withOpacity(0.75),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Metrics Breakdown Grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorderColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniMetric(isDark, 'Purchase Cost', '₹${_purchaseCost.toStringAsFixed(2)}'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMiniMetric(
                              isDark,
                              'Margin (${_marginPercent.toStringAsFixed(0)}%)',
                              '+₹${_marginAmount.toStringAsFixed(2)}',
                              alignment: CrossAxisAlignment.end,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniMetric(
                              isDark,
                              'GST (${_effectiveGstPercent.toStringAsFixed(0)}%)',
                              '+₹${_gstAmount.toStringAsFixed(2)}',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMiniMetric(
                              isDark,
                              'Net Sales Price',
                              '₹${_effectiveNetSalesPrice.toStringAsFixed(2)}',
                              alignment: CrossAxisAlignment.end,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (mrpVal > 0 && displayDp > 0 && mrpVal >= displayDp) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Dealer saves ₹${(mrpVal - displayDp).toStringAsFixed(2)} (${(((mrpVal - displayDp) / mrpVal) * 100).toStringAsFixed(1)}% margin off MRP)',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPricingBottomSheet(BuildContext context, bool isDark, GstState gstState) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final primaryColor = Theme.of(context).colorScheme.primary;
            final cardBorderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
            final textMutedColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

            final List<double> availableGstRates = [5.0, 12.0, 18.0, 28.0];

            return Container(
              height: MediaQuery.of(sheetContext).size.height * 0.90,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Grab Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.calculate_outlined, color: primaryColor, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pricing & Cost Calculator',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Costs, margins, GST slab & dealer pricing',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textMutedColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: Icon(Icons.close, color: textMutedColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Scrollable Calculation Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Direct Costs
                          Text(
                            '1. Direct Costs',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter basic product cost, box packaging, and handling fee.',
                            style: TextStyle(fontSize: 12, color: textMutedColor),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildNumberField(
                                  isDark: isDark,
                                  controller: _productCostController,
                                  label: 'Product (₹)',
                                  hint: '0.00',
                                  onChanged: (val) {
                                    setSheetState(() {});
                                    _onPriceParamChanged();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildNumberField(
                                  isDark: isDark,
                                  controller: _boxCostController,
                                  label: 'Box (₹)',
                                  hint: '0.00',
                                  onChanged: (val) {
                                    setSheetState(() {});
                                    _onPriceParamChanged();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildNumberField(
                                  isDark: isDark,
                                  controller: _handlingFeeController,
                                  label: 'Handling (₹)',
                                  hint: '0.00',
                                  onChanged: (val) {
                                    setSheetState(() {});
                                    _onPriceParamChanged();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Purchase Cost Banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cardBorderColor),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Purchase Cost = Sum of Direct Costs',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white70 : Colors.grey.shade700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '₹${_productCost.toStringAsFixed(2)} + ₹${_boxCost.toStringAsFixed(2)} + ₹${_handlingFee.toStringAsFixed(2)}',
                                        style: TextStyle(fontSize: 11, color: textMutedColor),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '₹${_purchaseCost.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 2. Margin
                          Text(
                            '2. Margin (% of Purchase Cost)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Set your profit margin applied on top of purchase cost.',
                            style: TextStyle(fontSize: 12, color: textMutedColor),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: _buildNumberField(
                                  isDark: isDark,
                                  controller: _marginPercentController,
                                  label: 'Margin %',
                                  hint: '25',
                                  suffix: '%',
                                  icon: Icons.trending_up_rounded,
                                  onChanged: (val) {
                                    setSheetState(() {});
                                    _onPriceParamChanged();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 7,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.black26 : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: cardBorderColor),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Margin (${_marginPercent.toStringAsFixed(0)}%):',
                                              style: TextStyle(fontSize: 11, color: textMutedColor),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              '+ ₹${_marginAmount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green.shade600),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'After Margin:',
                                              style: TextStyle(fontSize: 11, color: textMutedColor),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              '₹${_priceAfterMargin.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white : Colors.black87),
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
                          const SizedBox(height: 8),
                          // Preset Margin chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: ['15', '20', '25', '30', '35', '40'].map((preset) {
                              final isSelected = _marginPercentController.text == preset;
                              return InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  _marginPercentController.text = preset;
                                  setSheetState(() {});
                                  _onPriceParamChanged();
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isSelected ? primaryColor : (isDark ? Colors.white10 : Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$preset%',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // 3. GST Slab
                          Text(
                            '3. GST Slab',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'GST calculated on Price after Margin (₹${_priceAfterMargin.toStringAsFixed(2)})',
                            style: TextStyle(fontSize: 12, color: textMutedColor),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: availableGstRates.map((slab) {
                              final isSelected = (_selectedGstPercent ?? 18.0) == slab;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setSheetState(() => _selectedGstPercent = slab);
                                      setState(() => _selectedGstPercent = slab);
                                      _onPriceParamChanged();
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? primaryColor : (isDark ? Colors.black26 : Colors.grey.shade50),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? primaryColor : cardBorderColor,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: primaryColor.withOpacity(0.3),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${slab.toInt()}%',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : (isDark ? Colors.white70 : Colors.black87),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: cardBorderColor),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'GST (${_effectiveGstPercent.toStringAsFixed(0)}% on ₹${_priceAfterMargin.toStringAsFixed(2)}):',
                                    style: TextStyle(fontSize: 11.5, color: textMutedColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '+ ₹${_gstAmount.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.blue.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 4. Net Sales Price & Round Off
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF232A38) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: isDark ? Colors.blue.shade900.withOpacity(0.5) : Colors.blue.shade200),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Net Sales Price',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Cost + Margin + GST = ₹${_netSalesPrice.toStringAsFixed(2)}',
                                            style: TextStyle(fontSize: 11, color: textMutedColor),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '₹${_effectiveNetSalesPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? Colors.lightBlueAccent : const Color(0xFF1D4ED8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(Icons.rounded_corner, size: 16, color: textMutedColor),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Round Off Net Sales Price',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Transform.scale(
                                      scale: 0.85,
                                      child: Switch(
                                        value: _roundOffNetSales,
                                        onChanged: (val) {
                                          setSheetState(() => _roundOffNetSales = val);
                                          setState(() => _roundOffNetSales = val);
                                          _onPriceParamChanged();
                                        },
                                        activeColor: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 5. Dealer Price (D.P.) - Green Box
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF192A21) : const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: isDark ? Colors.green.shade900.withOpacity(0.6) : Colors.green.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(Icons.storefront_outlined, size: 20, color: Colors.green.shade700),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Dealer Price (D.P.)',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.green.shade300 : Colors.green.shade900,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade700.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'For B2B',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.green.shade300 : Colors.green.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: _buildNumberField(
                                        isDark: isDark,
                                        controller: _dpPercentController,
                                        label: 'D.P. %',
                                        hint: '25',
                                        suffix: '%',
                                        icon: Icons.percent,
                                        onChanged: (val) {
                                          setSheetState(() {});
                                          _onPriceParamChanged();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 7,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.black26 : Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: cardBorderColor),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Markup (${_dpPercent.toStringAsFixed(0)}%):',
                                                    style: TextStyle(fontSize: 11, color: textMutedColor),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment: Alignment.centerRight,
                                                  child: Text(
                                                    '+ ₹${_netDpAmount.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.green.shade700),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Net D.P.:',
                                                    style: TextStyle(fontSize: 11, color: textMutedColor),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment: Alignment.centerRight,
                                                  child: Text(
                                                    '₹${_netDp.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: isDark ? Colors.white70 : Colors.black87),
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
                                const SizedBox(height: 8),
                                // Preset DP chips
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: ['15', '20', '25', '30'].map((preset) {
                                    final isSelected = _dpPercentController.text == preset;
                                    return InkWell(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        _dpPercentController.text = preset;
                                        setSheetState(() {});
                                        _onPriceParamChanged();
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.green.shade700
                                              : (isDark ? Colors.white10 : Colors.grey.shade200),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '$preset%',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : (isDark ? Colors.white70 : Colors.black87),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(Icons.rounded_corner, size: 16, color: textMutedColor),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Round Off D.P.',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Transform.scale(
                                      scale: 0.85,
                                      child: Switch(
                                        value: _roundOffNetDp,
                                        onChanged: (val) {
                                          setSheetState(() => _roundOffNetDp = val);
                                          setState(() => _roundOffNetDp = val);
                                          _onPriceParamChanged();
                                        },
                                        activeColor: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Final Dealer Price (D.P.):',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Selling Price saved in Catalog',
                                            style: TextStyle(fontSize: 11, color: textMutedColor),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '₹${_effectiveNetDp.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? Colors.green.shade400 : Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 6. Consumer MRP - Retail Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF221719) : const Color(0xFFFFF5F5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? const Color(0xFF4D1D22) : const Color(0xFFFFD5D8),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(Icons.sell_outlined, size: 20, color: primaryColor),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Consumer MRP',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? const Color(0xFFFF8A8C) : const Color(0xFF991B1B),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF381B1E) : const Color(0xFFFFE4E6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'B2C Retail',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? const Color(0xFFFF8A8C) : const Color(0xFFC51D23),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Maximum Retail Price printed on box and shown crossed out to dealers to illustrate their profit margin.',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  isDark,
                                  _mrpController,
                                  'Consumer MRP (₹)',
                                  isNumber: true,
                                  icon: Icons.sell_outlined,
                                  validator: (val) => null,
                                  onChanged: (val) => setSheetState(() {}),
                                ),
                                // MRP vs DP Comparison Hint
                                Builder(builder: (context) {
                                  final mrp = double.tryParse(_mrpController.text) ?? 0.0;
                                  final dp = _effectiveNetDp > 0
                                      ? _effectiveNetDp
                                      : (double.tryParse(_priceController.text) ?? 0.0);
                                  if (mrp <= 0 || dp <= 0) return const SizedBox.shrink();
                                  final diff = mrp - dp;
                                  final isProfit = diff >= 0;
                                  final percent = ((diff / mrp) * 100).clamp(-100.0, 100.0);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isProfit
                                            ? (isDark ? Colors.green.shade900.withOpacity(0.3) : Colors.green.shade50)
                                            : (isDark ? Colors.amber.shade900.withOpacity(0.3) : Colors.amber.shade50),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isProfit
                                              ? (isDark ? Colors.green.shade800 : Colors.green.shade200)
                                              : (isDark ? Colors.amber.shade800 : Colors.amber.shade200),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isProfit ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                                            size: 16,
                                            color: isProfit ? Colors.green : Colors.amber.shade800,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              isProfit
                                                  ? 'Dealer Margin: ₹${diff.toStringAsFixed(2)} (${percent.toStringAsFixed(1)}% off MRP)'
                                                  : 'Note: MRP (₹${mrp.toStringAsFixed(2)}) is lower than D.P. (₹${dp.toStringAsFixed(2)})',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isProfit
                                                    ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
                                                    : (isDark ? Colors.amber.shade300 : Colors.amber.shade900),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      border: Border(top: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _onPriceParamChanged();
                          Navigator.of(sheetContext).pop();
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          _effectiveNetDp > 0
                              ? 'Apply Pricing (₹${_effectiveNetDp.toStringAsFixed(2)})'
                              : 'Apply Pricing',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildSummaryBadge(bool isDark, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(bool isDark, String label, String value, {CrossAxisAlignment alignment = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment == CrossAxisAlignment.start ? Alignment.centerLeft : Alignment.centerRight,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    String? hint,
    String? suffix,
    IconData? icon,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13.5),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        suffixStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          fontWeight: FontWeight.bold,
        ),
        labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12),
        prefixIcon: icon != null
            ? Icon(icon, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)
            : null,
        prefixIconConstraints: icon != null ? const BoxConstraints(minWidth: 28, minHeight: 28) : null,
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
