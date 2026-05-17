import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../../models/address.dart';
import '../providers/address_provider.dart';

class AddressAddEditScreen extends ConsumerStatefulWidget {
  final String? addressId;

  const AddressAddEditScreen({super.key, this.addressId});

  @override
  ConsumerState<AddressAddEditScreen> createState() => _AddressAddEditScreenState();
}

class _AddressAddEditScreenState extends ConsumerState<AddressAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _labelController = TextEditingController();
  final _zipFocusNode = FocusNode();
  AddressType _selectedType = AddressType.home;
  bool _isSaving = false;
  List<Address> _existingAddresses = [];

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    _landmarkController.dispose();
    _labelController.dispose();
    _zipFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadExistingAddresses();
    if (widget.addressId != null) {
      Future.microtask(() => _loadAddressData());
    }
  }

  void _loadExistingAddresses() {
    final addresses = ref.read(addressProvider).value ?? [];
    setState(() {
      _existingAddresses = addresses;
      // If adding new address (not editing), default to first available type
      if (widget.addressId == null) {
        if (!_isTypeTaken(AddressType.home)) {
          _selectedType = AddressType.home;
        } else if (!_isTypeTaken(AddressType.work)) {
          _selectedType = AddressType.work;
        } else {
          _selectedType = AddressType.other;
        }
      }
    });
  }

  bool _isTypeTaken(AddressType type) {
    if (type == AddressType.other) return false;
    // Check if any *other* address has this type
    return _existingAddresses.any((a) => a.type == type && a.id != widget.addressId);
  }

  void _loadAddressData() {
    final addresses = ref.read(addressProvider).value ?? [];
    final address = addresses.firstWhere(
      (a) => a.id == widget.addressId,
      orElse: () => Address(id: '', userId: '', name: '', street: '', city: '', state: '', zipCode: '', phone: '', type: AddressType.home),
    );
    
    if (address.id.isNotEmpty) {
      _nameController.text = address.name;
      _streetController.text = address.street;
      _cityController.text = address.city;
      _stateController.text = address.state;
      _zipController.text = address.zipCode;
      _phoneController.text = address.phone;
      _landmarkController.text = address.landmark ?? '';
      _labelController.text = address.label ?? '';
      setState(() => _selectedType = address.type);
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final id = widget.addressId ?? '';
      
      // Auto-set label for Home/Work if empty
      String? label = _labelController.text.trim();
      if (_selectedType != AddressType.other) {
        label = null; // Clear label for standard types
      }

      final newAddress = Address(
        id: id,
        userId: 'current_user',
        name: _nameController.text.trim(),
        street: _streetController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        zipCode: _zipController.text.trim(),
        phone: _phoneController.text.trim(),
        landmark: _landmarkController.text.trim(),
        label: label,
        type: _selectedType,
      );

      if (widget.addressId != null) {
        await ref.read(addressProvider.notifier).updateAddress(newAddress);
      } else {
        await ref.read(addressProvider.notifier).addAddress(newAddress);
      }
      
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save address: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF101822) : Colors.white;
    final backgroundColor = isDark ? const Color(0xFF101822) : const Color(0xFFF6F7F8);
    final inputBgColor = isDark ? const Color(0xFF1A2634) : const Color(0xFFF6F7F8);
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : const Color(0xFF111418);
    final labelColor = isDark ? Colors.white : const Color(0xFF111418);
    final hintColor = isDark ? Colors.grey[500] : Colors.grey[400];

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: textColor),
          splashRadius: 24,
        ),
        title: Text(
          widget.addressId != null ? 'Edit Address' : 'Add New Address',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name
                    _buildInputField(
                      label: 'Full Name',
                      controller: _nameController,
                      placeholder: 'e.g. Alex Morgan',
                      labelColor: labelColor,
                      textColor: textColor,
                      inputBgColor: inputBgColor,
                      borderColor: borderColor,
                      hintColor: hintColor!,
                    ),
                    const SizedBox(height: 20),
                    
                    // Phone Number
                    _buildInputField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      placeholder: '10 digit mobile number',
                      keyboardType: TextInputType.phone,
                      labelColor: labelColor,
                      textColor: textColor,
                      inputBgColor: inputBgColor,
                      borderColor: borderColor,
                      hintColor: hintColor,
                      maxLength: 10,
                      customValidator: (value) {
                        if (value == null || value.isEmpty) return 'Phone number is required';
                        if (value.length != 10) return 'Phone must be 10 digits';
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Only digits allowed';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Street Address
                    _buildInputField(
                      label: 'Street Address',
                      controller: _streetController,
                      placeholder: 'Street address',
                      labelColor: labelColor,
                      textColor: textColor,
                      inputBgColor: inputBgColor,
                      borderColor: borderColor,
                      hintColor: hintColor,
                    ),
                    const SizedBox(height: 20),

                    // Landmark (Optional)
                    _buildInputField(
                      label: 'Landmark (Optional)',
                      controller: _landmarkController,
                      placeholder: 'E.g. Near Central Park',
                      labelColor: labelColor,
                      textColor: textColor,
                      inputBgColor: inputBgColor,
                      borderColor: borderColor,
                      hintColor: hintColor,
                      customValidator: (value) => null, // Optional
                    ),
                    const SizedBox(height: 20),
                    
                    // Location (Town/City)
                    _buildInputField(
                      label: 'Town/City',
                      controller: _cityController,
                      placeholder: 'Town/City',
                      labelColor: labelColor,
                      textColor: textColor,
                      inputBgColor: inputBgColor,
                      borderColor: borderColor,
                      hintColor: hintColor,
                    ),
                    const SizedBox(height: 12),
                    
                    // State & Zip Code Row
                    Row(
                      children: [
                        Expanded(
                          flex: 65,
                          child: _buildStateDropdown(
                            labelColor: labelColor,
                            textColor: textColor,
                            inputBgColor: inputBgColor,
                            borderColor: borderColor,
                            hintColor: hintColor,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 35,
                          child: _buildInputField(
                            label: '',
                            controller: _zipController,
                            placeholder: 'Pin Code',
                            keyboardType: TextInputType.number,
                            labelColor: labelColor,
                            textColor: textColor,
                            inputBgColor: inputBgColor,
                            borderColor: borderColor,
                            hintColor: hintColor,
                            maxLength: 6,
                            focusNode: _zipFocusNode,
                            customValidator: (value) {
                              if (value == null || value.isEmpty) return 'Required';
                              if (value.length != 6) return 'Must be 6 digits';
                              if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Only digits';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: AddressType.values.map((type) {
                        final isSelected = _selectedType == type;
                        final isTaken = _isTypeTaken(type);
                        
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: type != AddressType.other ? 12 : 0,
                            ),
                            child: GestureDetector(
                              onTap: isTaken ? null : () {
                                setState(() {
                                  _selectedType = type;
                                  // Clear label if switching away from Other
                                  if (type != AddressType.other) {
                                    _labelController.clear();
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryBlue.withOpacity(0.1)
                                      : (isTaken ? (isDark ? Colors.grey[800] : Colors.grey[200]) : inputBgColor),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected 
                                      ? AppColors.primaryBlue 
                                      : (isTaken ? Colors.transparent : borderColor),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _capitalizeFirst(type.name),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? AppColors.primaryBlue
                                          : (isTaken 
                                              ? (isDark ? Colors.grey[600] : Colors.grey[500]) 
                                              : (isDark ? Colors.grey[400] : Colors.grey[500])),
                                      decoration: isTaken ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Label (For "Other" type) - Moved Below
                    if (_selectedType == AddressType.other) ...[
                      _buildInputField(
                        label: 'Address Label',
                        controller: _labelController,
                        placeholder: 'E.g. Parent\'s House, Vacation Home',
                        labelColor: labelColor,
                        textColor: textColor,
                        inputBgColor: inputBgColor,
                        borderColor: borderColor,
                        hintColor: hintColor,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Sticky Bottom Save Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(top: BorderSide(color: borderColor, width: 1)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primaryBlue.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.primaryBlue.withOpacity(0.3),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required Color labelColor,
    required Color textColor,
    required Color inputBgColor,
    required Color borderColor,
    required Color hintColor,
    TextInputType? keyboardType,
    int? maxLength,
    FocusNode? focusNode,
    String? Function(String?)? customValidator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          focusNode: focusNode,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: TextStyle(color: textColor, fontSize: 16),
          validator: customValidator ?? (value) {
            if (label.contains('(Optional)')) return null;
            if (label.isNotEmpty && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            if (label.isEmpty && (value == null || value.isEmpty)) {
              return 'Required';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: hintColor, fontSize: 16),
            filled: true,
            fillColor: inputBgColor,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStateDropdown({
    required Color labelColor,
    required Color textColor,
    required Color inputBgColor,
    required Color borderColor,
    required Color hintColor,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => _showStatePickerBottomSheet(isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: inputBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _stateController.text.isEmpty ? 'State' : _stateController.text,
                style: TextStyle(
                  color: _stateController.text.isEmpty ? hintColor : textColor,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: hintColor,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _showStatePickerBottomSheet(bool isDark) {
    final surfaceColor = isDark ? const Color(0xFF101822) : Colors.white;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : const Color(0xFF111418);
    final hintColor = isDark ? Colors.grey[500] : Colors.grey[400];
    final inputBgColor = isDark ? const Color(0xFF1A2634) : const Color(0xFFF6F7F8);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String searchQuery = '';
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredStates = _indianStates
                .where((s) => s.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          'Select State',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: textColor),
                        ),
                      ],
                    ),
                  ),
                  
                  // Search box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      onChanged: (value) => setModalState(() => searchQuery = value),
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Search state...',
                        hintStyle: TextStyle(color: hintColor),
                        prefixIcon: Icon(Icons.search, color: hintColor),
                        filled: true,
                        fillColor: inputBgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // States list
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredStates.length,
                      itemBuilder: (context, index) {
                        final state = filteredStates[index];
                        final isSelected = _stateController.text == state;
                        
                        return ListTile(
                          onTap: () {
                            setState(() => _stateController.text = state);
                            Navigator.pop(context);
                            // Focus on Pin Code after selection
                            Future.delayed(const Duration(milliseconds: 100), () {
                              _zipFocusNode.requestFocus();
                            });
                          },
                          title: Text(
                            state,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.primaryBlue)
                              : null,
                          tileColor: isSelected
                              ? AppColors.primaryBlue.withOpacity(0.1)
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // All Indian States and Union Territories (Sorted A-Z)
  static const List<String> _indianStates = [
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];
}
