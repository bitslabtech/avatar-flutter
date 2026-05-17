import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/create_order_provider.dart';

class Step2AddressSelection extends ConsumerStatefulWidget {
  const Step2AddressSelection({super.key});

  @override
  ConsumerState<Step2AddressSelection> createState() => _Step2AddressSelectionState();
}

class _Step2AddressSelectionState extends ConsumerState<Step2AddressSelection> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createOrderProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final borderColor = isDark ? Colors.grey[700] : Colors.grey[300];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shipping Address',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a saved address or add a new one',
            style: TextStyle(fontSize: 14, color: subtitleColor),
          ),
          const SizedBox(height: 16),

          // Loading State
          if (state.isLoadingAddresses) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          ]
          // No Addresses Found
          else if (state.userAddresses.isEmpty) ...[
            _buildNoAddressCard(isDark, textColor, cardColor, borderColor),
          ]
          // Addresses List
          else ...[
            ...state.userAddresses.map((address) => _buildAddressCard(
              address: address,
              isSelected: state.selectedAddressId == address['id'],
              isDark: isDark,
              textColor: textColor,
              subtitleColor: subtitleColor!,
              cardColor: cardColor!,
              borderColor: borderColor!,
            )),
          ],

          const SizedBox(height: 16),

          // Add New Address Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddAddressModal(isDark),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add New Address'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.primaryBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAddressCard(bool isDark, Color textColor, Color? cardColor, Color? borderColor) {
    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor!, style: BorderStyle.solid),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Address Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This customer has no saved addresses.\nAdd a new address to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard({
    required Map<String, dynamic> address,
    required bool isSelected,
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
    required Color cardColor,
    required Color borderColor,
  }) {
    final type = address['type'] ?? 'home';
    final iconData = type == 'work' ? Icons.work_outline : (type == 'other' ? Icons.location_on_outlined : Icons.home_outlined);

    return GestureDetector(
      onTap: () {
        ref.read(createOrderProvider.notifier).selectAddress(address['id']);
      },
      child: Card(
        elevation: 0,
        color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppColors.primaryBlue : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Radio indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primaryBlue : subtitleColor,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Address details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(iconData, size: 18, color: isSelected ? AppColors.primaryBlue : subtitleColor),
                        const SizedBox(width: 6),
                        Text(
                          type.toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.primaryBlue : subtitleColor,
                          ),
                        ),
                        if (address['isDefault'] == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      address['recipientName'] ?? '',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${address['street'] ?? ''}, ${address['city'] ?? ''}, ${address['state'] ?? ''} - ${address['zipCode'] ?? ''}',
                      style: TextStyle(fontSize: 13, color: subtitleColor),
                    ),
                    if (address['phone'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        address['phone'],
                        style: TextStyle(fontSize: 13, color: subtitleColor),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddAddressModal(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressFormModal(
        isDark: isDark,
        onSave: (addressData, saveToProfile) {
          // Set the address in the provider
          ref.read(createOrderProvider.notifier).setShippingAddress(addressData);
          ref.read(createOrderProvider.notifier).toggleSaveAddress(saveToProfile);
          Navigator.pop(context);
        },
        userName: ref.read(createOrderProvider).selectedUser?.name ?? '',
        userPhone: ref.read(createOrderProvider).selectedUser?.phone ?? '',
      ),
    );
  }
}

// Address Form Modal Widget
class AddressFormModal extends StatefulWidget {
  final bool isDark;
  final Function(Map<String, dynamic> address, bool saveToProfile) onSave;
  final String userName;
  final String userPhone;

  const AddressFormModal({
    super.key,
    required this.isDark,
    required this.onSave,
    required this.userName,
    required this.userPhone,
  });

  @override
  State<AddressFormModal> createState() => _AddressFormModalState();
}

class _AddressFormModalState extends State<AddressFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _landmarkController;
  late TextEditingController _labelController; // Added missing controller
  final _zipFocusNode = FocusNode();
  bool _saveToProfile = false;
  String _selectedType = 'home'; // Added missing variable

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _phoneController = TextEditingController(text: widget.userPhone);
    _streetController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _zipController = TextEditingController();
    _landmarkController = TextEditingController();
    _labelController = TextEditingController(); // Init
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _landmarkController.dispose();
    _labelController.dispose(); // Dispose
    _zipFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = widget.isDark ? const Color(0xFF101822) : Colors.white;
    final textColor = widget.isDark ? Colors.white : const Color(0xFF111418);
    final labelColor = widget.isDark ? Colors.grey[400]! : Colors.grey[700]!;
    final inputBgColor = widget.isDark ? const Color(0xFF1A2634) : const Color(0xFFF6F7F8);
    final borderColor = widget.isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final hintColor = widget.isDark ? Colors.grey[500]! : Colors.grey[400]!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                  'Add New Address',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textColor),
                ),
              ],
            ),
          ),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField('Full Name', _nameController, labelColor, textColor, inputBgColor, borderColor, hintColor),
                    const SizedBox(height: 16),
                    _buildInputField('Phone Number', _phoneController, labelColor, textColor, inputBgColor, borderColor, hintColor,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Phone is required';
                        if (value.length != 10) return 'Phone must be 10 digits';
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Only digits allowed';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildInputField('Street Address', _streetController, labelColor, textColor, inputBgColor, borderColor, hintColor),
                    const SizedBox(height: 16),
                    _buildInputField('Landmark (Optional)', _landmarkController, labelColor, textColor, inputBgColor, borderColor, hintColor, validator: (val) => null),
                    const SizedBox(height: 16),
                    _buildInputField('Town/City', _cityController, labelColor, textColor, inputBgColor, borderColor, hintColor),
                    const SizedBox(height: 16),
                    
                    // State & Zip Code Row
                    Row(
                      children: [
                        Expanded(
                          flex: 65,
                          child: _buildStateDropdown(labelColor, textColor, inputBgColor, borderColor, hintColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 35,
                          child: _buildInputField('Pin Code', _zipController, labelColor, textColor, inputBgColor, borderColor, hintColor,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            focusNode: _zipFocusNode,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required';
                              if (value.length != 6) return '6 digits';
                              if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Only digits';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Label (For "Other" type)
                    if (_selectedType == 'other') ...[
                       _buildInputField('Address Label', _labelController, labelColor, textColor, inputBgColor, borderColor, hintColor, validator: (val) => null), // Optional or required? User usually wants custom label
                       const SizedBox(height: 16),
                    ],

                    // Address Type Selection
                    Consumer(
                      builder: (context, ref, child) {
                        final existingAddresses = ref.read(createOrderProvider).userAddresses;
                        
                        // Helper to check if type is taken
                        bool isTypeTaken(String type) {
                          if (type == 'other') return false;
                          return existingAddresses.any((a) => (a['type'] ?? 'home') == type);
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Address Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: labelColor)),
                            const SizedBox(height: 12),
                            Row(
                              children: ['home', 'work', 'other'].map((type) {
                                final isSelected = _selectedType == type;
                                final isTaken = isTypeTaken(type);
                                
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(right: type != 'other' ? 12 : 0),
                                    child: GestureDetector(
                                      onTap: isTaken ? null : () {
                                        setState(() {
                                          _selectedType = type;
                                           if (type != 'other') _labelController.clear();
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primaryBlue.withOpacity(0.1)
                                              : (isTaken ? (widget.isDark ? Colors.grey[800] : Colors.grey[200]) : inputBgColor),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected ? AppColors.primaryBlue 
                                              : (isTaken ? Colors.transparent : borderColor),
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            type.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? AppColors.primaryBlue
                                                  : (isTaken 
                                                      ? (widget.isDark ? Colors.grey[600] : Colors.grey[500]) 
                                                      : (widget.isDark ? Colors.grey[400] : Colors.grey[600])),
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
                          ],
                        );
                      }
                    ),
                    const SizedBox(height: 24),

                    // Save to Profile Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _saveToProfile,
                          onChanged: (val) => setState(() => _saveToProfile = val ?? false),
                          activeColor: AppColors.primaryBlue,
                        ),
                        Expanded(
                          child: Text(
                            'Save this address to user\'s profile',
                            style: TextStyle(color: labelColor, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // Save Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Use This Address',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label, 
    TextEditingController controller, 
    Color labelColor, 
    Color textColor, 
    Color inputBgColor, 
    Color borderColor, 
    Color hintColor, {
    TextInputType? keyboardType,
    int? maxLength,
    FocusNode? focusNode,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: labelColor)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          focusNode: focusNode,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: TextStyle(color: textColor, fontSize: 16),
          validator: validator ?? (value) => (value == null || value.isEmpty) ? 'Required' : null,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(color: hintColor),
            filled: true,
            fillColor: inputBgColor,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildStateDropdown(Color labelColor, Color textColor, Color inputBgColor, Color borderColor, Color hintColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('State', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: labelColor)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showStatePickerModal(textColor, inputBgColor, borderColor, hintColor),
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
                Icon(Icons.keyboard_arrow_down_rounded, color: hintColor, size: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showStatePickerModal(Color textColor, Color inputBgColor, Color borderColor, Color hintColor) {
    final surfaceColor = widget.isDark ? const Color(0xFF101822) : Colors.white;
    
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
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text('Select State', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const Spacer(),
                        IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: textColor)),
                      ],
                    ),
                  ),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                            Future.delayed(const Duration(milliseconds: 100), () => _zipFocusNode.requestFocus());
                          },
                          title: Text(state, style: TextStyle(color: textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primaryBlue) : null,
                          tileColor: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : null,
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

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      if (_stateController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a state'), backgroundColor: Colors.red),
        );
        return;
      }
      
      widget.onSave({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'street': _streetController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'zipCode': _zipController.text,
        'landmark': _landmarkController.text,
        'label': _labelController.text, // Save label
        'type': _selectedType,         // Save selected type
        'country': 'India',
      }, _saveToProfile);
    }
  }
}
