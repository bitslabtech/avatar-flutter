import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class WhatsAppConfigScreen extends ConsumerStatefulWidget {
  const WhatsAppConfigScreen({super.key});

  @override
  ConsumerState<WhatsAppConfigScreen> createState() => _WhatsAppConfigScreenState();
}

class _WhatsAppConfigScreenState extends ConsumerState<WhatsAppConfigScreen> {
  // Credentials Controllers
  late TextEditingController _numberCtrl;
  late TextEditingController _modeCtrl;
  late TextEditingController _phoneIdCtrl;
  late TextEditingController _tokenCtrl;

  // Template Controllers
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _langControllers = {};
  final Map<String, bool> _templateEnabled = {};
  
  // Track keys to ensure order
  final List<String> _templateKeys = [
    'otp', 'user_reg', 'dealer_reg', 'dealer_approved', 
    'dealer_rejected', 'order_placed', 'order_status', 'abandoned_cart'
  ];
  
  bool _tokenVisible = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    // Safely read current state. 
    // If provider is not initialized, this gets default state which has empty config.
    final state = ref.read(adminSettingsProvider);
    final config = state.whatsAppConfig;

    _numberCtrl = TextEditingController(text: config['number']);
    _modeCtrl = TextEditingController(text: config['mode']);
    _phoneIdCtrl = TextEditingController(text: config['phoneId']);
    _tokenCtrl = TextEditingController(text: config['accessToken']);

    // Initialize Template Controllers & Toggles
    for (var key in _templateKeys) {
      _initTemplate(key, config);
    }
  }

  void _initTemplate(String key, Map<String, String> config) {
    _nameControllers[key] = TextEditingController(text: config['${key}_name']);
    _langControllers[key] = TextEditingController(text: config['${key}_lang']);
    
    // Logic to determine if enabled
    bool enabled = config['${key}_enabled'] == 'true';
    // If not explicitly 'true', check if name is set (legacy config might imply enabled)
    if (!enabled && (config['${key}_name']?.isNotEmpty ?? false)) {
      enabled = true;
    }
    // Default to true if completely missing for better UX on first load
    if (config['${key}_name'] == null && config['${key}_enabled'] == null) {
      enabled = true;
    }
    
    _templateEnabled[key] = enabled;
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _modeCtrl.dispose();
    _phoneIdCtrl.dispose();
    _tokenCtrl.dispose();
    for (var c in _nameControllers.values) c.dispose();
    for (var c in _langControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _performSave() async {
     final Map<String, String> newConfig = {
      'number': _numberCtrl.text.trim(),
      'mode': _modeCtrl.text,
      'phoneId': _phoneIdCtrl.text.trim(),
      'accessToken': _tokenCtrl.text.trim(),
    };

    // Add Templates
    _nameControllers.forEach((key, ctrl) {
      newConfig['${key}_name'] = ctrl.text.trim();
      newConfig['${key}_lang'] = _langControllers[key]?.text.trim() ?? 'en_US';
      newConfig['${key}_enabled'] = _templateEnabled[key].toString();
    });

    await ref.read(adminSettingsProvider.notifier).saveWhatsAppConfig(newConfig);
  }

  Future<void> _saveConfig() async {
    await _performSave();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration Saved Successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  Future<void> _testConnection() async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving and testing connection...'), duration: Duration(seconds: 1)),
      );

      await _performSave();

      // Test Endpoint
      if (!mounted) return;
      final apiClient = ref.read(apiClientProvider);
      
      // We wrap in try-catch specifically for the test call to distinguish save vs test error
      try {
        await apiClient.post('/whatsapp/test');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Connection Verified Successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Connection Failed: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
       // Save fail
    }
  }

  void _showTestDialog(String key) {
     final name = _nameControllers[key]?.text.trim() ?? '';
     if (name.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter template name first')));
        return;
     }

     final phoneCtrl = TextEditingController(text: _numberCtrl.text); // Pre-fill with business number for convenience
     
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         title: Text('Test Template: $name'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             const Text('Enter target phone number (with country code, e.g. 919876543210) to receive a test message.'),
             const SizedBox(height: 16),
             TextField(
               controller: phoneCtrl,
               decoration: const InputDecoration(
                 labelText: 'Target Phone Number',
                 border: OutlineInputBorder(),
                 hintText: 'e.g. 919988776655'
               ),
               keyboardType: TextInputType.phone,
             ),
           ],
         ),
         actions: [
           TextButton(onPressed: () => ctx.pop(), child: const Text('Cancel')),
           ElevatedButton(
             onPressed: () {
               ctx.pop();
               _runTemplateTest(key, phoneCtrl.text.trim());
             },
             child: const Text('Send Test'),
           )
         ],
       )
     );
  }

  Future<void> _runTemplateTest(String key, String phone) async {
    if (phone.isEmpty) return;
    
    // Auto-save first to ensure backend has latest config
    await _performSave();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sending Test Message...'), duration: Duration(seconds: 1)));

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.post( // Use dio directly to get full response
        '/whatsapp/test-template', 
        data: {
          'phone': phone,
          'templateName': _nameControllers[key]?.text.trim(),
          'languageCode': _langControllers[key]?.text.trim(),
          'type': key,
        }
      );
      
      final data = response.data;
      if (!mounted) return;

      if (data['success'] == true) {
        _showResultDialog('✅ Success', 'Template sent successfully!\n\nResponse: ${data['data']}');
      } else {
        _showResultDialog('❌ Failed', 'Error: ${data['error']?.toString() ?? "Unknown error"}');
      }
    } catch (e) {
      if (mounted) _showResultDialog('❌ Error', 'Request Failed: $e');
    }
  }

  void _showResultDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [TextButton(onPressed: () => ctx.pop(), child: const Text('Close'))],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Custom Colors from Design
    final bgDark = const Color(0xFF101822);
    final surfaceDark = const Color(0xFF1C2027);
    final borderDark = const Color(0xFF3B4554);
    final textSecondary = const Color(0xFF9DA8B9);
    final primary = const Color(0xFF136DEC);
    final bgLight = const Color(0xFFF6F7F8);

    final bgColor = isDark ? bgDark : bgLight;
    final surfaceColor = isDark ? surfaceDark : Colors.white;
    final borderColor = isDark ? borderDark : Colors.grey.shade300;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? textSecondary : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? bgDark : Colors.white,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                   Align(
                     alignment: Alignment.centerLeft,
                     child: InkWell(
                       onTap: () => context.pop(),
                       borderRadius: BorderRadius.circular(20),
                       child: Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(
                           color: isDark ? Colors.transparent : Colors.grey.shade100,
                           shape: BoxShape.circle,
                         ),
                         child: Icon(Icons.arrow_back, color: textColor),
                       ),
                     ),
                   ),
                   Text(
                     'WhatsApp Config',
                     style: TextStyle(
                       fontSize: 18,
                       fontWeight: FontWeight.bold,
                       color: textColor,
                     ),
                   ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // API Credentials Section
                    Text(
                      'API Credentials',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildLabel('Integration Type', textColor),
                    const SizedBox(height: 8),
                    _buildDropdown(context, isDark, surfaceColor, borderColor, textColor),
                    const SizedBox(height: 16),

                    _buildLabel('Business Phone Number', textColor),
                    const SizedBox(height: 8),
                    _buildInput(
                      controller: _numberCtrl, 
                      hint: '+1 (555) 000-0000', 
                      isDark: isDark,
                      bgColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      hintColor: hintColor
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Phone Number ID', textColor, showHelp: true),
                    const SizedBox(height: 8),
                    _buildInput(
                      controller: _phoneIdCtrl, 
                      hint: '1092384...', 
                      isDark: isDark,
                      bgColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      hintColor: hintColor,
                      isMono: true,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Permanent Access Token', textColor),
                    const SizedBox(height: 8),
                    _buildInput(
                      controller: _tokenCtrl, 
                      hint: 'EAAQ...', 
                      isDark: isDark,
                      bgColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      hintColor: hintColor,
                      isMono: true,
                      isPassword: true,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Token must have 'whatsapp_business_messaging' permission.",
                      style: TextStyle(fontSize: 12, color: hintColor),
                    ),

                    const SizedBox(height: 24),
                    Divider(color: borderColor),
                    const SizedBox(height: 24),

                    // Message Templates Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Message Templates',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_nameControllers.length} configured',
                             style: TextStyle(fontSize: 12, color: hintColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildTemplateCard(
                      key: 'otp',
                      title: 'OTP (Login/Reset)',
                      icon: Icons.lock,
                      iconColor: primary,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                     _buildTemplateCard(
                      key: 'user_reg',
                      title: 'User Registration',
                      icon: Icons.person_add,
                      iconColor: Colors.blue.shade400,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                     _buildTemplateCard(
                      key: 'dealer_reg',
                      title: 'Dealer Registration',
                      icon: Icons.storefront,
                      iconColor: Colors.purple.shade400,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                     _buildTemplateCard(
                      key: 'dealer_approved',
                      title: 'Dealer Approval',
                      icon: Icons.check_circle,
                      iconColor: Colors.green.shade400,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                     _buildTemplateCard(
                      key: 'dealer_rejected',
                      title: 'Dealer Rejection',
                      icon: Icons.cancel,
                      iconColor: Colors.red.shade400,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                     _buildTemplateCard(
                      key: 'order_placed',
                      title: 'Order Placed',
                      icon: Icons.shopping_cart,
                      iconColor: Colors.orange.shade400,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                     _buildTemplateCard(
                      key: 'order_status',
                      title: 'Order Status Update',
                      icon: Icons.local_shipping,
                      iconColor: Colors.teal.shade400,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                     _buildTemplateCard(
                      key: 'abandoned_cart',
                      title: 'Abandoned Cart',
                      icon: Icons.production_quantity_limits,
                      iconColor: Colors.pink.shade400,
                      isDark: isDark,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? bgDark.withOpacity(0.95) : Colors.white.withOpacity(0.95),
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _testConnection,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  foregroundColor: textColor,
                ),
                child: const Text('Test Connection', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
             Expanded(
              child: ElevatedButton(
                onPressed: _saveConfig,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  shadowColor: primary.withOpacity(0.3),
                ),
                child: const Text('Save Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color, {bool showHelp = false}) {
    return Row(
      children: [
        Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
        if (showHelp) ...[
          const SizedBox(width: 8),
          const Icon(Icons.help_outline, size: 16, color: Colors.grey),
        ]
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller, 
    required String hint, 
    required bool isDark,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required Color hintColor,
    bool isMono = false,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_tokenVisible,
        style: TextStyle(
          color: textColor,
          fontFamily: isMono ? 'monospace' : null,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: hintColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(
              _tokenVisible ? Icons.visibility_off : Icons.visibility,
              color: hintColor,
            ),
            onPressed: () => setState(() => _tokenVisible = !_tokenVisible),
          ) : null,
        ),
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, bool isDark, Color bgColor, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: ['cloud_api', 'on_premise', '3rd_party'].contains(_modeCtrl.text) ? _modeCtrl.text : 'cloud_api',
          dropdownColor: bgColor,
          isExpanded: true,
          icon: Icon(Icons.expand_more, color: textColor),
          style: TextStyle(color: textColor, fontSize: 16),
          items: const [
            DropdownMenuItem(value: 'cloud_api', child: Text('Meta Cloud API')),
            DropdownMenuItem(value: 'on_premise', child: Text('On-Premise API')),
            DropdownMenuItem(value: '3rd_party', child: Text('3rd Party Partner')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _modeCtrl.text = val);
          },
        ),
      ),
    );
  }

  Widget _buildTemplateCard({
    required String key,
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color hintColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Switch(
                value: _templateEnabled[key] ?? false,
                onChanged: (val) => setState(() => _templateEnabled[key] = val),
                 activeColor: const Color(0xFF136DEC),
              ),
            ],
          ),
          if (_templateEnabled[key] == true) ...[
             const SizedBox(height: 16),
             Row(
               children: [
                 Expanded(
                   flex: 2,
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text('Template Name', style: TextStyle(fontSize: 12, color: hintColor, fontWeight: FontWeight.w500)),
                       const SizedBox(height: 6),
                       Container(
                         height: 40,
                         decoration: BoxDecoration(
                           color: isDark ? const Color(0xFF101822) : Colors.grey.shade100,
                           borderRadius: BorderRadius.circular(4),
                           border: Border.all(color: borderColor),
                         ),
                         child: TextField(
                           controller: _nameControllers[key],
                           style: TextStyle(color: textColor, fontSize: 13),
                           decoration: InputDecoration(
                             border: InputBorder.none,
                             contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                             hintText: 'e.g. hello_world',
                             hintStyle: TextStyle(color: hintColor.withOpacity(0.5)),
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   flex: 1,
                    child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text('Lang', style: TextStyle(fontSize: 12, color: hintColor, fontWeight: FontWeight.w500)),
                       const SizedBox(height: 6),
                       Container(
                         height: 40,
                         decoration: BoxDecoration(
                           color: isDark ? const Color(0xFF101822) : Colors.grey.shade100,
                           borderRadius: BorderRadius.circular(4),
                           border: Border.all(color: borderColor),
                         ),
                         child: TextField(
                           controller: _langControllers[key],
                           textAlign: TextAlign.center,
                           style: TextStyle(color: textColor, fontSize: 13),
                           decoration: InputDecoration(
                             border: InputBorder.none,
                             contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                             hintText: 'en_US',
                             hintStyle: TextStyle(color: hintColor.withOpacity(0.5)),
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
                 const SizedBox(width: 8), 
                 IconButton(
                   icon: const Icon(Icons.send, color: AppColors.primaryBlue),
                   tooltip: 'Test this template',
                   onPressed: () => _showTestDialog(key),
                 ),
               ],
             )
          ]
        ],
      ),
    );
  }
}
