import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/brand_provider.dart';

class BrandEditScreen extends ConsumerStatefulWidget {
  final String brandId;
  const BrandEditScreen({super.key, required this.brandId});

  @override
  ConsumerState<BrandEditScreen> createState() => _BrandEditScreenState();
}

class _BrandEditScreenState extends ConsumerState<BrandEditScreen> {
  final _nameController = TextEditingController();
  final _deleteConfirmationController = TextEditingController();
  String _status = 'Active';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBrand();
    });
  }

  void _loadBrand() {
    final brand = ref.read(brandProvider).brands.firstWhere((b) => b.id == widget.brandId, orElse: () => BrandItem(id: '', name: '', isActive: true, productCount: 0));
    _nameController.text = brand.name;
    _status = brand.isActive ? 'Active' : 'Inactive';
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deleteConfirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = ref.watch(brandProvider).brands.firstWhere((b) => b.id == widget.brandId, orElse: () => BrandItem(id: '', name: '', isActive: true, productCount: 0));

    if (brand.id.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundBlack : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildLogoSection(context, isDark, brand),
                    const SizedBox(height: 32),
                    _buildForm(context, isDark, brand),
                    const SizedBox(height: 40),
                    _buildActionButtons(context, isDark, brand),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundBlack.withOpacity(0.95) : Colors.white.withOpacity(0.95),
        border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.grey.shade300 : Colors.grey.shade600),
            style: IconButton.styleFrom(backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100, shape: const CircleBorder()),
          ),
          const SizedBox(width: 12),
          Text('Edit Brand', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context, bool isDark, BrandItem brand) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image Upload Feature Coming Soon')));
          },
          child: Stack(
            children: [
              Container(
                width: 112, height: 112,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Center(
                  child: Icon(Icons.verified, size: 48, color: AppColors.primaryBlue),
                ),
              ),
              Positioned(
                bottom: -8, right: -8,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.backgroundBlack : AppColors.backgroundLight, width: 4),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Tap to change logo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
        const SizedBox(height: 4),
        Text(
          'Recommended: 400x400 px (Square)', 
          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600, fontStyle: FontStyle.italic)
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, bool isDark, BrandItem brand) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(isDark, 'Brand Name'),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel(isDark, 'Brand Status'),
         const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _status,
              isExpanded: true,
              icon: Icon(Icons.expand_more, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
              dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500, fontSize: 16),
              items: ['Active', 'Inactive'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() => _status = newValue!);
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildStatsCard(context, isDark, brand),
      ],
    );
  }

  Widget _buildLabel(bool isDark, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700)),
    );
  }

  Widget _buildStatsCard(BuildContext context, bool isDark, BrandItem brand) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.inventory, color: AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL PRODUCTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, letterSpacing: 0.5)),
                  Text('${brand.productCount} Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                ],
              ),
            ],
          ),
          TextButton(
            onPressed: () {}, // Navigate to products filtered by brand
            child: Row(
              children: [
                Text('View All', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16, color: AppColors.primaryBlue),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark, BrandItem brand) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _saveChanges(brand),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: AppColors.primaryBlue.withOpacity(0.25),
            ),
            child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, size: 20),
                      SizedBox(width: 8),
                      Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _showDeleteConfirmation(context, isDark, brand),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
               shadowColor: Colors.red.withOpacity(0.25),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete, size: 20),
                SizedBox(width: 8),
                Text('Delete Brand', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveChanges(BrandItem brand) async {
    setState(() => _isLoading = true);
    final success = await ref.read(brandProvider.notifier).updateBrand(
          id: brand.id,
          name: _nameController.text,
          isActive: _status == 'Active',
        );
    setState(() => _isLoading = false);
    if (success && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Brand updated successfully')));
    }
  }

  void _showDeleteConfirmation(BuildContext context, bool isDark, BrandItem brand) {
    _deleteConfirmationController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(Icons.warning_amber_rounded, size: 32, color: Colors.red.shade600),
            ),
            const SizedBox(height: 16),
            Text('Delete Brand?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
            Text(
              'This action is irreversible. All products associated with "${brand.name}" will be moved to \'Unassigned\'.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900.withOpacity(0.5) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TYPE "DELETE" TO CONFIRM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _deleteConfirmationController,
                    textAlign: TextAlign.center,
                    style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'DELETE',
                      hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                      filled: true,
                      fillColor: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey.shade600 : Colors.grey.shade300)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
             const SizedBox(height: 24),
             Row(
               children: [
                 Expanded(
                   child: TextButton(
                     onPressed: () => context.pop(),
                     style: TextButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 12),
                       backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                     ),
                     child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                   ),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: ElevatedButton(
                     onPressed: () async {
                       if (_deleteConfirmationController.text == 'DELETE') {
                         final success = await ref.read(brandProvider.notifier).deleteBrand(brand.id);
                         if (success && context.mounted) {
                           context.goNamed('admin-brands'); // Go back to list, popping dialog and edit screen might be tricky, better route directly. Or pop until.
                           // Actually context.pop() closes dialog. Then another pop to close screen.
                           // Simpler: 
                           Navigator.of(context).pop(); // Close dialog
                           Navigator.of(context).pop(); // Close screen
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Brand Deleted Permanently')));
                         }
                       } else {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please type DELETE to confirm')));
                       }
                     },
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 12),
                       backgroundColor: Colors.red.shade600,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     ),
                     child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                   ),
                 ),
               ],
             )
          ],
        ),
      ),
    );
  }
}
