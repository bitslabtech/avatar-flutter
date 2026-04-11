import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/user_management_provider.dart';
import '../../providers/create_order_provider.dart';
import '../../../../models/user.dart';

class Step1UserSelection extends ConsumerStatefulWidget {
  const Step1UserSelection({super.key});

  @override
  ConsumerState<Step1UserSelection> createState() => _Step1UserSelectionState();
}

class _Step1UserSelectionState extends ConsumerState<Step1UserSelection> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userManagementProvider.notifier).loadUsers();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userManagementProvider);
    final createOrderState = ref.watch(createOrderProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter consumers and dealers for order creation
    final customers = userState.filteredUsers.where((u) => u.role == 'consumer' || u.role == 'dealer').toList();
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => ref.read(userManagementProvider.notifier).setSearchQuery(v),
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Search Customer...',
              hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        
        Expanded(
          child: userState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : customers.isEmpty
                  ? Center(child: Text('No customers found', style: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade600)))
                  : ListView.builder(
                      itemCount: customers.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final user = customers[index];
                        final isSelected = createOrderState.selectedUser?.id == user.id;

                        return Card(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          elevation: isSelected ? 4 : 1,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isSelected ? const BorderSide(color: AppColors.primaryBlue, width: 2) : BorderSide.none,
                          ),
                          child: ListTile(
                            onTap: () {
                              ref.read(createOrderProvider.notifier).selectUser(user);
                            },
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                              child: Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              user.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  user.phone,
                                  style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: user.isDealer ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: user.isDealer ? Colors.purple.withOpacity(0.3) : Colors.blue.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    user.isDealer ? 'Dealer' : 'Consumer',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: user.isDealer ? Colors.purple : Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: AppColors.primaryBlue)
                                : null,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
