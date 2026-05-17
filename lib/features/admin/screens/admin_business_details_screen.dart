import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Provider — loads all business.* settings from backend
// ---------------------------------------------------------------------------
final businessDetailsProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  // GET /settings requires admin JWT — correct for this SuperAdmin-only screen
  final response = await apiClient.dio.get('/settings');
  final List<dynamic> list = response.data ?? [];
  final map = <String, String>{};
  for (final item in list) {
    final key = item['key'] as String? ?? '';
    final val = item['value'] as String? ?? '';
    if (key.startsWith('business.')) {
      map[key] = val;
    }
  }
  return map;
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class AdminBusinessDetailsScreen extends ConsumerStatefulWidget {
  const AdminBusinessDetailsScreen({super.key});

  @override
  ConsumerState<AdminBusinessDetailsScreen> createState() =>
      _AdminBusinessDetailsScreenState();
}

class _AdminBusinessDetailsScreenState
    extends ConsumerState<AdminBusinessDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl    = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _altPhoneCtrl= TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _gstinCtrl   = TextEditingController();

  bool _populated = false;
  bool _isSaving  = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _altPhoneCtrl.dispose();
    _emailCtrl.dispose();
    _gstinCtrl.dispose();
    super.dispose();
  }

  void _populate(Map<String, String> data) {
    if (_populated) return;
    _populated = true;
    _nameCtrl.text     = data['business.company_name'] ?? '';
    _addressCtrl.text  = data['business.address']      ?? '';
    _phoneCtrl.text    = data['business.phone']        ?? '';
    _altPhoneCtrl.text = data['business.alt_phone']    ?? '';
    _emailCtrl.text    = data['business.email']        ?? '';
    _gstinCtrl.text    = data['business.gstin']        ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final apiClient = ref.read(apiClientProvider);

    final settings = {
      'business.company_name': _nameCtrl.text.trim(),
      'business.address'     : _addressCtrl.text.trim(),
      'business.phone'       : _phoneCtrl.text.trim(),
      'business.alt_phone'   : _altPhoneCtrl.text.trim(),
      'business.email'       : _emailCtrl.text.trim(),
      'business.gstin'       : _gstinCtrl.text.trim(),
    };

    try {
      // Upsert each key via POST /settings
      await Future.wait(settings.entries.map(
        (e) => apiClient.dio.post('/settings', data: {
          'key'  : e.key,
          'value': e.value,
        }),
      ));

      if (mounted) {
        ref.invalidate(businessDetailsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Business details saved'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          ),
        );
        context.pop();
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Error saving';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $msg'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark          = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor    = isDark ? const Color(0xFF1C2333) : Colors.white;
    final bgColor         = isDark ? const Color(0xFF101522) : const Color(0xFFF6F6F8);
    final borderColor     = isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB);
    final textColor       = isDark ? Colors.white : Colors.black87;

    final settingsAsync = ref.watch(businessDetailsProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Business Details',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load settings', style: TextStyle(color: textColor)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(businessDetailsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          _populate(data);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primaryBlue, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'These details appear on Proforma GST Invoices sent to dealers and customers.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.blue[200] : AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildField(
                    label: 'Company Name',
                    hint: 'e.g. Avatar Home Appliances Pvt. Ltd.',
                    controller: _nameCtrl,
                    icon: Icons.business,
                    isDark: isDark,
                    borderColor: borderColor,
                    textColor: textColor,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Company name is required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    label: 'Address',
                    hint: 'Full business address',
                    controller: _addressCtrl,
                    icon: Icons.location_on_outlined,
                    isDark: isDark,
                    borderColor: borderColor,
                    textColor: textColor,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    label: 'Phone Number',
                    hint: 'Primary contact number',
                    controller: _phoneCtrl,
                    icon: Icons.phone_outlined,
                    isDark: isDark,
                    borderColor: borderColor,
                    textColor: textColor,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    label: 'Alternative Phone Number',
                    hint: 'Secondary contact number (optional)',
                    controller: _altPhoneCtrl,
                    icon: Icons.phone_callback_outlined,
                    isDark: isDark,
                    borderColor: borderColor,
                    textColor: textColor,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    label: 'Email Address',
                    hint: 'Business email',
                    controller: _emailCtrl,
                    icon: Icons.email_outlined,
                    isDark: isDark,
                    borderColor: borderColor,
                    textColor: textColor,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v != null && v.isNotEmpty && !v.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    label: 'GST Number (GSTIN)',
                    hint: 'e.g. 29ABCDE1234F1Z5',
                    controller: _gstinCtrl,
                    icon: Icons.receipt_long_outlined,
                    isDark: isDark,
                    borderColor: borderColor,
                    textColor: textColor,
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) {
                      if (v != null && v.isNotEmpty && v.length != 15) {
                        return 'GSTIN must be 15 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Save button at bottom
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_isSaving ? 'Saving...' : 'Save Business Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    required Color borderColor,
    required Color textColor,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          style: TextStyle(color: textColor, fontSize: 15),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            prefixIcon: Icon(icon, size: 20, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
            filled: true,
            fillColor: isDark ? const Color(0xFF1C2333) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
