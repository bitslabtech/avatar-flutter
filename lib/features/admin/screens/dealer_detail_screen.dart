import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user.dart';
import '../../../widgets/common/loading_indicator.dart';
import '../../../providers/auth_provider.dart';

// Provider for dealers
import '../providers/dealer_provider.dart';

class DealerDetailScreen extends ConsumerStatefulWidget {
  final User dealer;

  const DealerDetailScreen({super.key, required this.dealer});

  @override
  ConsumerState<DealerDetailScreen> createState() => _DealerDetailScreenState();
}

class _DealerDetailScreenState extends ConsumerState<DealerDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyController;
  late TextEditingController _gstController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  late TextEditingController _discountController;
  late String _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(text: widget.dealer.companyName ?? '');
    _gstController = TextEditingController(text: widget.dealer.gstVat ?? '');
    _nameController = TextEditingController(text: widget.dealer.name);
    _phoneController = TextEditingController(text: widget.dealer.phone);
    _emailController = TextEditingController(text: widget.dealer.email ?? '');
    // Format discount to remove .0 if it's a whole number
    final discount = widget.dealer.discountPercentage;
    _discountController = TextEditingController(
      text: discount % 1 == 0 ? discount.toInt().toString() : discount.toString(),
    );
    _status = widget.dealer.status;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _gstController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final data = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'companyName': _companyController.text.trim(),
        'gstVat': _gstController.text.trim(),
        'status': _status,
        'discountPercentage': double.tryParse(_discountController.text) ?? 0.0,
      };
      
      if (_emailController.text.trim().isNotEmpty) {
        data['email'] = _emailController.text.trim();
      }

      await ref.read(dealersProvider.notifier).updateProfile(widget.dealer.id, data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dealer profile updated successfully'), backgroundColor: Colors.green),
        );
        context.pop(); // Go back to list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundBlack : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Edit Dealer Profile', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(isDark),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Organization Details', isDark),
                    const SizedBox(height: 16),
                    _buildTextField('Company Name', _companyController, Icons.domain, isDark),
                    const SizedBox(height: 16),
                    _buildTextField('GST Number', _gstController, Icons.receipt_long, isDark),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Primary Contact', isDark),
                    const SizedBox(height: 16),
                    _buildTextField('Full Name', _nameController, Icons.person, isDark),
                    const SizedBox(height: 16),
                    _buildTextField('Phone Number', _phoneController, Icons.phone, isDark),
                    const SizedBox(height: 16),
                     _buildTextField(
                      'Email Address', 
                      _emailController, 
                      Icons.email, 
                      isDark,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                         if (value == null || value.isEmpty) return null; // Email optional
                         if (!value.contains('@')) return 'Invalid email';
                         return null;
                      },
                    ),
                     const SizedBox(height: 32),
                    _buildSectionHeader('Account Status', isDark),
                    const SizedBox(height: 16),
                    _buildStatusSelector(isDark),
                    
                    // Show Discount Field only for Super Admin
                    if (ref.watch(authProvider).user?.isSuperAdmin == true) ...[
                       const SizedBox(height: 32),
                       _buildSectionHeader('Pricing Control (Super Admin)', isDark),
                       const SizedBox(height: 16),
                       _buildTextField(
                         'Discount Percentage (%)', 
                         _discountController, 
                         Icons.percent, 
                         isDark,
                         keyboardType: TextInputType.number,
                         inputFormatters: [
                           FilteringTextInputFormatter.digitsOnly,
                           LengthLimitingTextInputFormatter(2),
                         ],
                         validator: (value) {
                           // Mandatory if Approved
                           if (_status == 'approved' && (value == null || value.isEmpty)) {
                              return 'Required for Approved dealers';
                           }
                           if (value == null || value.isEmpty) return null;
                           
                           final discount = int.tryParse(value);
                           if (discount == null) return 'Invalid number';
                           return null;
                         },
                       ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _buildSaveButton(isDark),
          _buildDeleteButton(isDark),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: isDark ? Colors.orange.shade900.withOpacity(0.5) : Colors.orange.shade100,
            child: Text(
              (widget.dealer.name.isNotEmpty ? widget.dealer.name[0] : '?').toUpperCase(),
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.dealer.companyName ?? widget.dealer.name,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          Text(
            'ID: #${widget.dealer.id.substring(0, 8)}',
            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.grey.shade500 : Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    TextEditingController controller, 
    IconData icon, 
    bool isDark, {
    TextInputType? keyboardType, 
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final bgColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderGray : Colors.grey.shade400;
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
        prefixIcon: Icon(icon, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.borderGray : Colors.grey.shade300)),
        filled: true,
        fillColor: bgColor,
      ),
      validator: validator ?? (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }

   Widget _buildStatusSelector(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildRadioOption(
            'Approved',
            'approved',
            isDark ? AppColors.successGreen : Colors.green,
            Icons.check_circle,
            isDark
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildRadioOption(
            'Rejected',
            'rejected',
            isDark ? AppColors.errorRed : Colors.red,
            Icons.cancel,
            isDark
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOption(String label, String value, Color color, IconData icon, bool isDark) {
    final isSelected = _status == value || 
                       (value == 'approved' && _status == 'active');
    
    final bgColor = isDark 
        ? (isSelected ? color.withOpacity(0.1) : AppColors.surfaceDark)
        : (isSelected ? color.withOpacity(0.1) : Colors.white);
        
    final borderColor = isDark
        ? (isSelected ? color : AppColors.borderGray)
        : (isSelected ? color : Colors.grey.shade300);

    return InkWell(
      onTap: () => setState(() => _status = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppColors.borderGray : Colors.grey.shade200)),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const LoadingIndicator(color: Colors.white)
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save),
                  SizedBox(width: 8),
                  Text('Save Changes'),
                ],
              ),
      ),
    );
  }

  Widget _buildDeleteButton(bool isDark) {
    // Only Super Admin can delete
    if (ref.watch(authProvider).user?.isSuperAdmin != true) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), // Add bottom padding
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _showDeleteConfirmation,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.errorRed,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline),
            SizedBox(width: 8),
            Text('Delete Dealer Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation() async {
    final deleteController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? errorText;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppColors.errorRed),
                ),
                const SizedBox(width: 12),
                Text('Delete Dealer?', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action cannot be undone. All data associated with this dealer will be permanently removed.',
                  style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Text(
                  'Type "DELETE" to confirm:',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black, 
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: deleteController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  onChanged: (_) {
                    if (errorText != null) setState(() => errorText = null);
                  },
                  decoration: InputDecoration(
                    hintText: 'DELETE',
                    hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                    errorText: errorText,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.errorRed),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.backgroundBlack : Colors.grey.shade50,
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.all(20),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2, // Give more space to delete button
                    child: ElevatedButton(
                      onPressed: () {
                        if (deleteController.text == 'DELETE') {
                          Navigator.of(context).pop();
                          _deleteDealer();
                        } else {
                          setState(() => errorText = 'Type "DELETE" to confirm');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Delete Permanently',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteDealer() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(dealersProvider.notifier).deleteDealer(widget.dealer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dealer profile deleted'), backgroundColor: Colors.red),
        );
        context.pop(); // Go back to list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
