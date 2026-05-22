import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/contact_settings_provider.dart';
import '../../../widgets/common/loading_indicator.dart';

class AdminContactSettingsScreen extends ConsumerStatefulWidget {
  const AdminContactSettingsScreen({super.key});

  @override
  ConsumerState<AdminContactSettingsScreen> createState() => _AdminContactSettingsScreenState();
}

class _AdminContactSettingsScreenState extends ConsumerState<AdminContactSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _whatsappController;
  late TextEditingController _callController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _whatsappController = TextEditingController();
    _callController = TextEditingController();
    
    // Load settings when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contactSettingsProvider.notifier).loadSettings();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _whatsappController.dispose();
    _callController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String number) {
    // Remove any non-digit characters
    final digits = number.replaceAll(RegExp(r'\D'), '');
    
    // If it's 10 digits, add +91
    if (digits.length == 10) {
      return '+91$digits';
    }
    
    // If it already has country code, return as is
    if (digits.length > 10) {
      return '+$digits';
    }
    
    // If less than 10 digits, return with +91
    return digits.isNotEmpty ? '+91$digits' : '';
  }

  String _extractPhoneDigits(String? number) {
    if (number == null || number.isEmpty) return '';
    
    // Remove +91 prefix and return only 10 digits
    final digits = number.replaceAll(RegExp(r'\D'), '');
    
    if (digits.startsWith('91') && digits.length > 10) {
      return digits.substring(2, digits.length > 12 ? 12 : digits.length);
    }
    
    return digits.length > 10 ? digits.substring(0, 10) : digits;
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      try {
        final whatsappNumber = _whatsappController.text.isNotEmpty 
            ? _formatPhoneNumber(_whatsappController.text)
            : null;
        final callNumber = _callController.text.isNotEmpty
            ? _formatPhoneNumber(_callController.text)
            : null;

        await ref.read(contactSettingsProvider.notifier).updateSettings(
              supportEmail: _emailController.text.isNotEmpty ? _emailController.text : null,
              whatsappNumber: whatsappNumber,
              callNumber: callNumber,
              isActive: _isActive,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact settings updated successfully')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsAsync = ref.watch(contactSettingsProvider);

    // Theme Colors
    final surfaceColor = isDark ? const Color(0xFF1C2333) : Colors.white;
    final backgroundColor = isDark ? const Color(0xFF101522) : const Color(0xFFF6F6F8);
    final borderColor = isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Contact Settings', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Save', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: settingsAsync.when(
        data: (settings) {
          // Populate controllers once
          if (_emailController.text.isEmpty) {
            _emailController.text = settings.supportEmail ?? '';
            _whatsappController.text = _extractPhoneDigits(settings.whatsappNumber);
            _callController.text = _extractPhoneDigits(settings.callNumber);
            _isActive = settings.isActive;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Support Email', isDark),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: textColor),
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('support@example.com', isDark, Icons.email),
                    validator: (val) {
                      if (val != null && val.isNotEmpty && !val.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  _buildLabel('WhatsApp Number (10 digits)', isDark),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C2333) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          '+91',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _whatsappController,
                          style: TextStyle(color: textColor),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: _inputDecoration('10 digit number', isDark, Icons.chat),
                          validator: (val) {
                            if (val != null && val.isNotEmpty && val.length != 10) {
                              return 'Must be exactly 10 digits';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildLabel('Call Number (10 digits)', isDark),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C2333) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          '+91',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _callController,
                          style: TextStyle(color: textColor),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: _inputDecoration('10 digit number', isDark, Icons.phone),
                          validator: (val) {
                            if (val != null && val.isNotEmpty && val.length != 10) {
                              return 'Must be exactly 10 digits';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: SwitchListTile(
                      title: Text('Active', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      subtitle: Text('Visible to users', style: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade600)),
                      value: _isActive,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error loading contact settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(contactSettingsProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
      prefixIcon: Icon(icon, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
      filled: true,
      fillColor: isDark ? const Color(0xFF1C2333) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}
