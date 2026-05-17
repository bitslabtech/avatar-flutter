import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _alternativePhoneController;
  late TextEditingController _emailController;
  
  // ignore: unused_field
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _alternativePhoneController = TextEditingController(text: user?.alternativePhone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _alternativePhoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    // Slight delay to simulate network/UI feel if needed, or just proceed
    // The provider handles the actual API call
    try {
      final data = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'alternativePhone': _alternativePhoneController.text.trim(),
        // Phone is read-only, not updating it
      };

      await ref.read(authProvider.notifier).updateProfile(data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
        context.pop();
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
    final theme = Theme.of(context);
    
    // Explicit colors from design or theme
    final bgColor = isDark ? const Color(0xFF101822) : const Color(0xFFF6F7F8); 
    final cardColor = isDark ? const Color(0xFF1F2937) : Colors.white; // Used for inputs sometimes or just white
    final textColor = isDark ? Colors.white : const Color(0xFF111418);
    final inputFillColor = isDark ? const Color(0xFF1A2634) : const Color(0xFFF6F7F8); // Match design input bg
    
    // Design uses white bg for light mode container usually? 
    // The HTML has: body bg-background-light, container bg-white max-w-[480px]
    // We are full screen, so scaffold bg should be white/dark-equivalent?
    // Let's use standard scaffold bg but inputs use specific fill.

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101822) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                   IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.arrow_back, color: textColor),
                    style: IconButton.styleFrom(
                      hoverColor: isDark ? const Color(0xFF1A2634) : Colors.grey[100],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Edit Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance back button
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100), // Space for bottom bar
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      
                      // Profile Picture Section
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 128,
                                  height: 128,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[300],
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF1A2634) : const Color(0xFFF6F7F8),
                                      width: 4,
                                    ),
                                    image: DecorationImage(
                                      image: _getProfileImage(ref.read(authProvider).user?.avatar),
                                      fit: BoxFit.cover,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 4,
                                  child: InkWell(
                                    onTap: _pickAndUploadImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF101822) : Colors.white,
                                          width: 2, 
                                        ),
                                      ),
                                      child: _isLoading 
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _pickAndUploadImage,
                              child: const Text('Change Profile Picture', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Fields Container
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel(isDark, 'Full Name'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _nameController,
                              icon: Icons.person_outline,
                              hint: 'Enter your full name',
                              isDark: isDark,
                              inputFillColor: inputFillColor,
                              textColor: textColor,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildFieldLabel(isDark, 'Email Address'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _emailController,
                              icon: Icons.mail_outline,
                              hint: 'name@example.com',
                              isDark: isDark,
                              inputFillColor: inputFillColor,
                              textColor: textColor,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildFieldLabel(isDark, 'Phone Number (Registered)'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _phoneController,
                              icon: Icons.phone_android_outlined,
                              hint: '+1 (000) 000-0000',
                              isDark: isDark,
                              inputFillColor: isDark ? const Color(0xFF151B24) : Colors.grey[200]!, // Darker/Greayer to indicate disabled
                              textColor: Colors.grey, // Grey text
                              keyboardType: TextInputType.phone,
                              enabled: false, // Read-only
                            ),

                            const SizedBox(height: 16),
                            
                            _buildFieldLabel(isDark, 'Alternative Phone Number'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _alternativePhoneController,
                              icon: Icons.phone_outlined,
                              hint: 'Enter alternative phone number',
                              isDark: isDark,
                              inputFillColor: inputFillColor,
                              textColor: textColor,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101822).withOpacity(0.9) : Colors.white.withOpacity(0.9),
          border: Border(top: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 4,
            ),
             child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(bool isDark, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey[300] : const Color(0xFF111418),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required bool isDark,
    required Color inputFillColor,
    required Color textColor,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputFillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey[500]),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Required';
          return null;
        },
      ),
    );
  }
  
  ImageProvider _getProfileImage(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return NetworkImage(avatarUrl);
    }
    return const NetworkImage("https://ui-avatars.com/api/?name=User&background=random");
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() => _isLoading = true);
      try {
        await ref.read(authProvider.notifier).uploadAvatar(image.path);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
