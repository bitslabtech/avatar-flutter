import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/content.dart';
import '../../../../providers/content_provider.dart';
import '../../../../widgets/common/loading_indicator.dart';

class AdminPolicyEditScreen extends ConsumerStatefulWidget {
  final String contentKey;

  const AdminPolicyEditScreen({super.key, required this.contentKey});

  @override
  ConsumerState<AdminPolicyEditScreen> createState() => _AdminPolicyEditScreenState();
}

class _AdminPolicyEditScreenState extends ConsumerState<AdminPolicyEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  bool _isActive = true;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
       ref.read(contentProvider(widget.contentKey).future).then((content) {
         if (mounted) {
           setState(() {
            _titleController.text = content.title;
            _bodyController.text = content.body;
            _isActive = content.isActive;
            _isInit = true;
           });
         }
       });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(contentListProvider.notifier).updateContent(
          widget.contentKey,
          _titleController.text,
          _bodyController.text,
          _isActive,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Policy updated successfully')));
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme Colors
    final surfaceColor = isDark ? const Color(0xFF1C2333) : Colors.white;
    final backgroundColor = isDark ? const Color(0xFF101522) : const Color(0xFFF6F6F8);
    final borderColor = isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Edit Policy', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
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
      body: !_isInit 
        ? const Center(child: LoadingIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Title', isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(color: textColor),
                   decoration: _inputDecoration('Policy Title', isDark),
                  validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 24),
                
                _buildLabel('Content', isDark),
                 const SizedBox(height: 8),
                TextFormField(
                  controller: _bodyController,
                  maxLines: 20,
                  style: TextStyle(color: textColor),
                  decoration: _inputDecoration('Enter policy content here...', isDark),
                  validator: (val) => val == null || val.isEmpty ? 'Body is required' : null,
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

  InputDecoration _inputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
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
