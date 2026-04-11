import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

import '../providers/settings_provider.dart';

class EcommerceCartScreen extends ConsumerStatefulWidget {
  const EcommerceCartScreen({super.key});

  @override
  ConsumerState<EcommerceCartScreen> createState() => _EcommerceCartScreenState();
}

class _EcommerceCartScreenState extends ConsumerState<EcommerceCartScreen> {
  final TextEditingController _minOrderController = TextEditingController();
  final TextEditingController _shippingChargeController = TextEditingController();

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  void _syncControllers(AdminSettingsState settings) {
    if (_minOrderController.text.isEmpty ||
        double.tryParse(_minOrderController.text) != settings.minOrderValue) {
      _minOrderController.text = settings.minOrderValue.toStringAsFixed(2);
    }
    if (_shippingChargeController.text.isEmpty ||
        double.tryParse(_shippingChargeController.text) != settings.shippingCharge) {
      _shippingChargeController.text = settings.shippingCharge.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1C2333) : Colors.white;
    final backgroundColor = isDark ? const Color(0xFF101522) : const Color(0xFFF6F6F8);
    final borderColor = isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : Colors.black87;

    // Sync controllers when settings load/update from server
    ref.listen<AdminSettingsState>(adminSettingsProvider, (previous, next) {
      if (!next.isLoading) {
        _syncControllers(next);
      }
    });

    // Sync on first build if not loading
    if (!_initialized) {
      final settings = ref.read(adminSettingsProvider);
      if (!settings.isLoading) {
        _syncControllers(settings);
        _initialized = true;
      }
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: textColor),
        ),
        title: Text(
          'Cart Configuration',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
         bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: borderColor, height: 1),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final minOrder = double.tryParse(_minOrderController.text) ?? 0.0;
              final shipping = double.tryParse(_shippingChargeController.text) ?? 0.0;
              
              await ref.read(adminSettingsProvider.notifier).updateShippingConfig(minOrder, shipping);
              
              if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart Config Saved')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            _buildSectionHeader('Order Values', textColor),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _buildNumberInput('Minimum Order Value (₹)', _minOrderController, textColor, isDark),
                  const SizedBox(height: 16),
                  _buildNumberInput('Standard Shipping Charge (₹)', _shippingChargeController, textColor, isDark, hint: 'Leave 0 for Free Shipping'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInput(String label, TextEditingController controller, Color textColor, bool isDark, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            prefixText: '₹ ',
            hintText: hint,
            hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
            prefixStyle: TextStyle(color: textColor),
            fillColor: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.shade50,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color.withOpacity(0.7),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
