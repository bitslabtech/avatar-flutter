import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/address.dart';
import '../../../../widgets/common/loading_indicator.dart';
import '../providers/address_provider.dart';

class MyAddressScreen extends ConsumerWidget {
  const MyAddressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressState = ref.watch(addressProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundBlack : Colors.white,
      appBar: AppBar(
        title: Text('My Addresses', style: theme.textTheme.titleLarge),
        backgroundColor: isDark ? AppColors.backgroundBlack : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? AppColors.dividerGray : Colors.grey[100],
            height: 1,
          ),
        ),
      ),
      body: addressState.when(
        data: (addresses) => _buildAddressList(context, ref, addresses, isDark),
        loading: () => const Center(child: LoadingIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundBlack : Colors.white,
            border: Border(top: BorderSide(color: isDark ? AppColors.dividerGray : Colors.grey[100]!)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56, // Match design height
            child: ElevatedButton(
              onPressed: () => context.push('/profile/addresses/add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlueFor(isDark),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                shadowColor: AppColors.primaryBlueFor(isDark).withOpacity(0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                   Icon(Icons.add),
                   SizedBox(width: 8),
                   Text('Add New Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressList(BuildContext context, WidgetRef ref, List<Address> addresses, bool isDark) {
    if (addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No addresses found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: addresses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _AddressCard(address: addresses[index], isDark: isDark);
      },
    );
  }
}

class _AddressCard extends ConsumerWidget {
  final Address address;
  final bool isDark;

  const _AddressCard({required this.address, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borderColor = isDark ? AppColors.dividerGray : Colors.grey[200]!;
    final cardBg = isDark ? AppColors.cardDark : Colors.white; // Or backgroundLight if preferred, styling says white/dark bg
    // Using check for default to add primary border highlight if needed, design shows primary/20 for default
    final isDefault = address.isDefault;
    final activeBorderColor = isDefault ? AppColors.primaryBlueFor(isDark).withOpacity(0.2) : borderColor;
    final bg = isDefault && !isDark ? const Color(0xFFF6F7F8) : (isDefault && isDark ? const Color(0xFF1A2634) : cardBg);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: activeBorderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (address.isDefault)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlueFor(isDark).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primaryBlueFor(isDark).withOpacity(0.3)),
                      ),
                      child: Text(
                        'DEFAULT',
                        style: TextStyle(
                          color: AppColors.primaryBlueFor(isDark),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(100),
                    ),
                      child: Text(
                        (address.type == AddressType.other && address.label != null && address.label!.isNotEmpty)
                            ? address.label!.toUpperCase()
                            : address.type.name.toUpperCase(),
                        style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[600],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                  ),
                ],
              ),
              Row(
                children: [
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    onTap: () {
                      context.push('/edit-address/${address.id}');
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(width: 4),
                  _ActionButton(
                    icon: Icons.delete_outline,
                    color: AppColors.errorRed,
                    bgHoverColor: AppColors.errorRed.withOpacity(0.1),
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Address'),
                          content: Text(
                            address.isDefault
                                ? 'This is your default address. To delete it, first set another address as default.'
                                : 'Do you want to delete this address?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            if (!address.isDefault)
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
                                child: const Text('Delete'),
                              ),
                          ],
                        ),
                      );
                      
                      if (confirmed == true) {
                        try {
                          await ref.read(addressProvider.notifier).deleteAddress(address.id);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                ),
                                backgroundColor: AppColors.errorRed,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      }
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            address.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111418),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${address.street}\n${address.landmark != null && address.landmark!.isNotEmpty ? '${address.landmark}, ' : ''}${address.city}, ${address.state} ${address.zipCode}\nUnited States', // Country hardcoded as per design or model?
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondary : Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
           Row(
            children: [
               Icon(Icons.call, size: 16, color: isDark ? AppColors.textSecondary : Colors.grey[600]),
               const SizedBox(width: 8),
               Text(
                address.phone,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSecondary : Colors.grey[600],
                ),
              ),
            ],
          ),
          if (!address.isDefault) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Divider(color: isDark ? AppColors.dividerGray : Colors.grey[100]),
            ),
            InkWell(
              onTap: () {
                 // Set as default logic
                 final updated = address.copyWith(isDefault: true);
                 ref.read(addressProvider.notifier).updateAddress(updated);
                 // Note: Provider needs to handle unsetting other defaults
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Set as Default',
                  style: TextStyle(
                    color: AppColors.primaryBlueFor(isDark),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final Color? color;
  final Color? bgHoverColor;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.color,
    this.bgHoverColor,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? (isDark ? Colors.grey[400] : Colors.grey[500]);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}
