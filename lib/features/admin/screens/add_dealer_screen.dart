import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/loading_indicator.dart';
import '../../../providers/auth_provider.dart';
import '../providers/dealer_provider.dart';


class AddDealerScreen extends ConsumerStatefulWidget {
  const AddDealerScreen({super.key});

  @override
  ConsumerState<AddDealerScreen> createState() => _AddDealerScreenState();
}

class _AddDealerScreenState extends ConsumerState<AddDealerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _gstVatController = TextEditingController();
  final _discountController = TextEditingController(text: '0.0');
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _gstVatController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(dealersProvider.notifier).addDealer({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'gstVat': _gstVatController.text.trim(),
        'discountPercentage': double.tryParse(_discountController.text) ?? 0.0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dealer added and approved successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.errorRed,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundBlack : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Add New Dealer',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader('Personal Information', isDark),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter dealer full name',
                  icon: Icons.person,
                  isDark: isDark,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter name' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  icon: Icons.phone,
                  isDark: isDark,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter phone number';
                    if (value.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(value)) return 'Phone must be exactly 10 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email (Optional)',
                  hint: 'Enter email address',
                  icon: Icons.email,
                  isDark: isDark,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && !value.contains('@')) {
                      return 'Please enter valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),
                _buildSectionHeader('Business Details', isDark),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _companyNameController,
                  label: 'Company Name',
                  hint: 'Enter company name',
                  icon: Icons.business,
                  isDark: isDark,
                  validator: (value) => value == null || value.isEmpty ? 'Company name is required' : null,
                ),
                const SizedBox(height: 16),
                  _buildTextField(
                  controller: _gstVatController,
                  label: 'GST/VAT Number',
                  hint: 'Enter GST/VAT number',
                  icon: Icons.receipt,
                  isDark: isDark,
                  validator: (value) => value == null || value.isEmpty ? 'GST/VAT number is required' : null,
                ),

                // Show Discount Field only for Super Admin
                if (ref.watch(authProvider).user?.isSuperAdmin == true) ...[
                   const SizedBox(height: 32),
                   _buildSectionHeader('Pricing Control (Super Admin)', isDark),
                   const SizedBox(height: 16),
                   _buildTextField(
                     controller: _discountController,
                     label: 'Discount Percentage (%)', 
                     hint: 'Enter dealer discount',
                     icon: Icons.percent, 
                     isDark: isDark,
                     keyboardType: const TextInputType.numberWithOptions(decimal: true),
                     validator: (value) {
                       if (value == null || value.isEmpty) return null; // Optional
                       final discount = double.tryParse(value);
                       if (discount == null) return 'Invalid number';
                       if (discount > 99) return 'Max value is 99';
                       if (discount < 0) return 'Cannot be negative';
                       return null;
                     },
                   ),
                ],

                const SizedBox(height: 32),
                _buildSectionHeader('Security', isDark),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Create password',
                  icon: Icons.lock,
                  isDark: isDark,
                  obscureText: _obscurePassword,
                  onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter password';
                    if (value.length < 8) return 'Min 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Confirm password',
                  icon: Icons.lock_outline,
                  isDark: isDark,
                  obscureText: _obscureConfirmPassword,
                  onToggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm password';
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),

                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const LoadingIndicator(color: Colors.white)
                      : const Text(
                          'Add Dealer',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        // Add visual indicator for mandatory fields if not optional
        labelText: (validator != null && !label.contains('(Optional)')) ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        labelStyle: TextStyle(
          color: isDark ? AppColors.textSecondary : Colors.grey[700],
        ),
        hintStyle: TextStyle(
          color: isDark ? AppColors.textTertiary : Colors.grey[500],
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? AppColors.borderGray : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.errorRed),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
    );
  }
}
