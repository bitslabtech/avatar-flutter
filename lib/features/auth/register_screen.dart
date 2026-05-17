/// Register screen with premium dark UI
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../core/utils/gst_validation.dart';
import '../../core/utils/gst_validation.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _gstVatController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _attempted = false; // Track if user has attempted submission
  String? _initialRole; // Will be set from URL params on first build
  String _selectedRole = 'consumer'; // 'consumer' or 'dealer'

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _gstVatController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() {
      _attempted = true;
    });
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await ref.read(authProvider.notifier).register(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            role: _selectedRole,
            companyName: _selectedRole == 'dealer' && _companyNameController.text.trim().isNotEmpty
                ? _companyNameController.text.trim()
                : null,
            gstVat: _selectedRole == 'dealer' && _gstVatController.text.trim().isNotEmpty
                ? _gstVatController.text.trim()
                : null,
          );

      if (mounted) {
        context.go('/home');
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialRole == null) {
      final uri = GoRouterState.of(context).uri;
      final roleParam = uri.queryParameters['role'];
      if (roleParam != null && (roleParam == 'consumer' || roleParam == 'dealer')) {
        _initialRole = roleParam;
        _selectedRole = roleParam;
      } else {
        _initialRole = 'consumer';
      }
    }
    
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Create Account',
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
                const SizedBox(height: 8),
                
                // Avatar logo
                Center(
                  child: Image.asset(
                    'assets/logo/avatar_logo.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Role selection
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryRed.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I want to register as:',
                        style: TextStyle(
                          color: isDark ? AppColors.textPrimary : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRoleOption(
                              'consumer',
                              'Consumer',
                              Icons.person,
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRoleOption(
                              'dealer',
                              'Dealer',
                              Icons.business,
                              isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Name field
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  icon: Icons.person,
                  isDark: isDark,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                ),
                
                const SizedBox(height: 20),
                
                // Phone number field
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  icon: Icons.phone,
                  isDark: isDark,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your phone number';
                    if (value.length < 10) return 'Please enter a valid phone number';
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Email field
                _buildTextField(
                  controller: _emailController,
                  label: 'Email (Optional)',
                  hint: 'Enter your email',
                  icon: Icons.email,
                  isDark: isDark,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Password field
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  icon: Icons.lock,
                  isDark: isDark,
                  obscureText: _obscurePassword,
                  onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a password';
                    if (value.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Confirm Password - moved here for better UX
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  icon: Icons.lock_outline,
                  isDark: isDark,
                  obscureText: _obscureConfirmPassword,
                  onToggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm your password';
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Dealer fields
                if (_selectedRole == 'dealer') ...[
                  Text(
                    'Dealer Information',
                    style: TextStyle(
                      color: isDark ? AppColors.textPrimary : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _companyNameController,
                    label: 'Company Name',
                    hint: 'Enter your company name',
                    icon: Icons.business,
                    isDark: isDark,
                    validator: (value) => (_selectedRole == 'dealer' && (value == null || value.isEmpty)) 
                        ? 'Company name is required for dealers' : null,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildTextField(
                    controller: _gstVatController,
                    label: 'GST Number',
                    hint: 'Enter GST number',
                    icon: Icons.receipt,
                    isDark: isDark,
                    onChanged: (value) {
                       // Force uppercase for better UX
                       final upper = value.toUpperCase();
                       if (value != upper) {
                         _gstVatController.value = _gstVatController.value.copyWith(
                           text: upper,
                           selection: TextSelection.collapsed(offset: upper.length),
                         );
                       }
                    },
                    validator: (value) {
                      if (_selectedRole != 'dealer') return null;
                      if (value == null || value.isEmpty) return 'GST number is required for dealers';
                      
                      final validation = GSTValidator.isValidGSTIN(value);
                      if (!validation['isValid']) {
                        return validation['error'];
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                
                const SizedBox(height: 32),
                
                // Register button
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primaryRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: authState.isLoading
                      ? const LoadingIndicator(color: Colors.white)
                      : const Text(
                          'Create Account',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
                
                const SizedBox(height: 24),
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: isDark ? AppColors.textSecondary : Colors.grey[700]),
                    ),
                    TextButton(
                      // Using canPop() allows correct back navigation if pushed
                      onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                
                // Guest Option
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/home'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: isDark ? AppColors.textTertiary.withOpacity(0.5) : Colors.grey[400]!),
                      foregroundColor: isDark ? AppColors.textSecondary : Colors.grey[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Continue as Guest', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autovalidateMode: _attempted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
      onChanged: onChanged,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
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
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? AppColors.borderGray : Colors.grey[400]!,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primaryRed),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildRoleOption(String role, String label, IconData icon, bool isDark) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryRed.withOpacity(0.2)
              : (isDark ? AppColors.surfaceDark : Colors.grey[200]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryRed
                : (isDark ? AppColors.borderGray : Colors.grey[400]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primaryRed
                  : (isDark ? AppColors.textSecondary : Colors.grey[600]),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primaryRed
                    : (isDark ? AppColors.textSecondary : Colors.grey[800]),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


