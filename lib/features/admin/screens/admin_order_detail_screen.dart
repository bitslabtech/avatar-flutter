// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:avatar_app/core/theme/app_colors.dart';
import 'package:avatar_app/core/utils/currency_utils.dart';
import 'package:avatar_app/models/order.dart';
import 'package:avatar_app/providers/order_provider.dart';
import 'package:avatar_app/widgets/common/loading_indicator.dart';
import 'package:avatar_app/widgets/common/error_widget.dart';
import 'package:avatar_app/features/admin/widgets/product_picker_dialog.dart';
import 'package:avatar_app/features/admin/providers/orders_provider.dart' as admin;
import 'package:avatar_app/models/order_item.dart';
import 'package:avatar_app/models/product.dart';

class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const AdminOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends ConsumerState<AdminOrderDetailScreen> {
  // Editing State
  late TextEditingController _notesController;
  late TextEditingController _trackingController;
  late TextEditingController _courierController;
  late TextEditingController _shippingOverrideController;
  late String _selectedStatus;
  DateTime? _estimatedDeliveryDate;
  bool _isDirty = false;
  bool _isEditingItems = false;
  List<OrderItem> _localItems = [];

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _trackingController = TextEditingController();
    _courierController = TextEditingController();
    _shippingOverrideController = TextEditingController();
    
    // Fetch orders if not already loaded (e.g., coming from notification)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ordersState = ref.read(admin.ordersProvider);
      if (ordersState.orders.isEmpty && !ordersState.isLoading) {
        ref.read(admin.ordersProvider.notifier).loadData();
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _trackingController.dispose();
    _courierController.dispose();
    _shippingOverrideController.dispose();
    super.dispose();
  }

  /// Initialize state from order data once loaded
  void _initializeState(Order order) {
    if (!_isDirty && !_isEditingItems) { // Only init if user hasn't started editing
        _notesController.text = order.notes ?? '';
        _trackingController.text = order.tracking?['trackingNumber'] ?? '';
        _courierController.text = order.courier?['provider'] ?? '';
        _selectedStatus = order.status.nameStr;
        if (order.shippingOverridePaise != null) {
          _shippingOverrideController.text = (order.shippingOverridePaise! ~/ 100).toString();
        } else {
          _shippingOverrideController.clear();
        }
        // Only update date if incoming data has a value (preserve user selection during async refresh)
        if (order.estimatedDeliveryDate != null || _estimatedDeliveryDate == null) {
          _estimatedDeliveryDate = order.estimatedDeliveryDate;
        }
        _localItems = List.from(order.items);
    }
  }

  /// Update quantity of an item in _localItems
  void _updateItemQuantity(String itemId, int newQty) {
    setState(() {
      final index = _localItems.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        final oldItem = _localItems[index];
        _localItems[index] = OrderItem(
          id: oldItem.id,
          productId: oldItem.productId,
          sku: oldItem.sku,
          name: oldItem.name,
          qty: newQty,
          dpPricePaise: oldItem.dpPricePaise,
          lineTotalDpPaise: oldItem.dpPricePaise * newQty,
          taxPercent: oldItem.taxPercent,
          imageUrl: oldItem.imageUrl,
        );
        _isDirty = true;
      }
    });
  }

  Future<void> _saveChanges() async {
    try {
      // Show loading or disable button
      // Validation for Dispatched status
      if (_selectedStatus == OrderStatus.dispatched.nameStr) {
        final missingFields = <String>[];
        if (_courierController.text.trim().isEmpty) missingFields.add('Courier Provider');
        if (_trackingController.text.trim().isEmpty) missingFields.add('Tracking Number');
        if (_estimatedDeliveryDate == null) missingFields.add('Estimated Delivery Date');

        if (missingFields.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please fill mandatory fields for Dispatched status: ${missingFields.join(", ")}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      }

      await ref.read(admin.ordersProvider.notifier).updateOrderStatus(
        widget.orderId,
        _selectedStatus,
        estimatedDeliveryDate: _estimatedDeliveryDate,
        notes: _notesController.text,
        courierProvider: _courierController.text,
        trackingNumber: _trackingController.text,
        shippingOverridePaise: _buildShippingOverride(),
      );
      
      // Clear dirty flag so UI can refresh from provider
      setState(() {
        _isDirty = false;
      });
      // Also update tracking logic if API supports it, currently updateStatus supports basics
      // If separate API needed for tracking/courier details beyond simple strings, handle here.
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order updated successfully', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, Order order) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this order? This action cannot be undone.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text('Type DELETE to confirm:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'DELETE',
                isDense: true,
              ),
              onChanged: (val) {
                 (ctx as Element).markNeedsBuild(); // Force rebuild to update button state
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, 
                  foregroundColor: Colors.white,
                ),
                onPressed: value.text == 'DELETE' 
                  ? () async {
                      Navigator.pop(ctx);
                      try {
                        await ref.read(admin.ordersProvider.notifier).deleteOrder(order.id);
                        if (context.mounted) {
                          Navigator.pop(context); // Close details screen
                          ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Order deleted successfully')),
                          );
                        }
                      } catch (e) {
                         if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                         }
                      }
                    } 
                  : null,
                child: const Text('Delete'),
              );
            }
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(admin.ordersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Find the order from the admin provider list to ensure we get updates
    // (orderProvider(id) is not refreshed after admin updates)
    Order? order;
    try {
      order = ordersState.orders.firstWhere((o) => o.id == widget.orderId);
    } catch (_) {
      // Fallback or handle loading
    }

    if (order == null) {
       return const Scaffold(
         body: Center(child: CircularProgressIndicator()),
       );
    }
    
    // Initialize local state from fresh order data
    _initializeState(order);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), // background-dark : background-light
      body: Stack(
        children: [
                // Main Content
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Safe area for footer
                  child: Column(
                    children: [
                      const SizedBox(height: 20), // Status bar space
                      _buildHeader(context, order, isDark),
                      const SizedBox(height: 16),
                      _buildSummaryCard(context, order),
                      const SizedBox(height: 16),
                      _buildCustomerSection(context, order, isDark),
                      _buildItemsSection(context, order, isDark),
                      _buildLogisticsSection(context, order, isDark),
                      _buildNotesSection(context, order, isDark),
                    ],
                  ),
                ),
                
                // Floating Footer
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width - 32,
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B).withOpacity(0.9) : const Color(0xFF0F172A).withOpacity(0.9), // slate-900/90
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Row(
                        children: [
                          // Status Dropdown (40%)
                          Expanded(
                            flex: 4,
                            child: Container(
                              height: 48, // Match button height
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: _getStatusColor(_selectedStatus).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _getStatusColor(_selectedStatus).withOpacity(0.3)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                   value: _selectedStatus,
                                   isDense: true,
                                   isExpanded: true,
                                   icon: Icon(Icons.expand_more, size: 20, color: _getStatusColor(_selectedStatus)),
                                   style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _getStatusColor(_selectedStatus)),
                                   dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                   onChanged: (val) {
                                     if (val != null) setState(() { _selectedStatus = val; _isDirty = true; });
                                   },
                                   items: OrderStatus.values.where((s) => s != OrderStatus.draft).map((s) => DropdownMenuItem(
                                     value: s.nameStr,
                                     child: Text(
                                       s.nameStr.toUpperCase(),
                                       style: TextStyle(
                                          color: _getStatusColor(s.nameStr),
                                          fontWeight: FontWeight.bold,
                                       ),
                                     ),
                                   )).toList(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Download Button (10%)
                          _buildFooterIconButton(Icons.download, Colors.grey[400]!, () {
                             // Download action
                          }),
                          const SizedBox(width: 8),
                          // Save Button (40%)
                          Expanded(
                            flex: 4,
                            child: ElevatedButton(
                              onPressed: _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 18),
                                  SizedBox(width: 4),
                                  Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            )
    );
  }

  Widget _buildHeader(BuildContext context, Order order, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                ),
                child: Icon(Icons.arrow_back, size: 20, color: isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Detail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey[900])),
                Text('#${order.orderNo}', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[500])),
              ],
            )
          ],
        ),
        // Status badge (read-only display, editing is in footer)
        // Delete Button (Header)
        IconButton(
          onPressed: () => _showDeleteConfirmation(context, order),
          style: IconButton.styleFrom(
            backgroundColor: Colors.red.withOpacity(0.1),
            foregroundColor: Colors.red,
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.delete_outline, size: 20),
        )
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)], // Dark slate gradient
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
        ],
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          // Background decoration
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.2), blurRadius: 40)],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('GRAND TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(order.grandTotalDisplay, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('RECEIPT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
                      Text('#${order.orderNo.substring(order.orderNo.length > 4 ? order.orderNo.length - 4 : 0)}', // Last 4 chars as dummy receipt
                        style: const TextStyle(fontSize: 14, fontFamily: 'monospace', color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 24),
              Container(height: 1, color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildSummaryItem(Icons.shopping_bag, 'ITEMS', '${order.items.length} Products')),
                  Expanded(child: _buildSummaryItem(Icons.person, 'CUSTOMER', order.addressSnapshot?['name'] ?? 'Guest')),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: Colors.grey[300]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[500])),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildCustomerSection(BuildContext context, Order order, bool isDark) {
    return _buildSectionCard(
      context, isDark,
      title: 'Customer Information',
      icon: Icons.person,
      iconColor: AppColors.primaryBlue,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.withOpacity(0.1) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[300],
                  child: Text(order.addressSnapshot?['name']?[0] ?? '?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.addressSnapshot?['name'] ?? 'No Name', 
                         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                      Text(order.user?['email'] ?? 'No Email', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                      Text(order.addressSnapshot?['phone'] ?? 'No Phone', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('SHIPPING ADDRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey))
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _formatAddress(order.addressSnapshot ?? {}),
              style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? Colors.grey[300] : Colors.grey[800]),
            ),
          )
        ],
      )
    );
  }

  Widget _buildItemsSection(BuildContext context, Order order, bool isDark) {
    return _buildSectionCard(
      context, isDark,
      title: 'Order Items (${_localItems.length})',
      icon: Icons.inventory_2,
      iconColor: AppColors.primaryBlue,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isEditingItems)
            Icon(Icons.expand_more, color: isDark ? Colors.grey[400] : Colors.grey[600])
          else
            IconButton(
              icon: Icon(Icons.edit, size: 20, color: AppColors.primaryBlue),
              onPressed: () => setState(() => _isEditingItems = true),
            ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
               color: isDark ? Colors.grey.withOpacity(0.1) : Colors.grey[50], 
               borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _localItems.map((item) => _buildOrderItemRow(item, isDark)).toList(),
            ),
          ),
          if (_isEditingItems) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await showDialog<Product>(
                  context: context,
                  builder: (ctx) => const ProductPickerDialog(),
                );
                if (result != null) {
                  // Check if product already exists
                  final existingIndex = _localItems.indexWhere((item) => item.productId == result.id);
                  
                  if (existingIndex != -1) {
                    // Update existing item quantity
                    final existingItem = _localItems[existingIndex];
                    _updateItemQuantity(existingItem.id!, existingItem.qty + 1);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${result.name} quantity updated'), duration: const Duration(seconds: 1)),
                      );
                    }
                  } else {
                    final pricePaise = ((result.price ?? 0) * 100).round();
                    final newItem = OrderItem(
                      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                      productId: result.id,
                      sku: result.sku,
                      name: result.name,
                      qty: 1,
                      dpPricePaise: pricePaise,
                      lineTotalDpPaise: pricePaise,
                      taxPercent: result.gstPercent ?? 0.0,
                      imageUrl: (result.resolvedImageUrls != null && result.resolvedImageUrls!.isNotEmpty) ? result.resolvedImageUrls!.first : null,
                    );
                    setState(() {
                      _localItems.add(newItem);
                      _isDirty = true;
                    });
                  }
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Product'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: BorderSide(color: AppColors.primaryBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isEditingItems = false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Convert _localItems to API format
                      final itemsData = _localItems.map((item) => {
                        'productId': item.productId,
                        'qty': item.qty,
                      }).toList();
                      
                      // Show loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saving changes...'), duration: Duration(seconds: 1)),
                      );
                      
                      final success = await ref.read(admin.ordersProvider.notifier).updateOrderItems(
                        widget.orderId,
                        itemsData,
                      );
                      
                      if (success) {
                        setState(() {
                          _isEditingItems = false;
                          _isDirty = false;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order items updated successfully!'), backgroundColor: Colors.green),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to update items. Please try again.'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          // Totals - calculate dynamically from _localItems
          Builder(builder: (context) {
            final subtotalPaise = _localItems.fold<int>(0, (sum, item) => sum + item.lineTotalDpPaise);
            final taxPaise = _localItems.fold<int>(0, (sum, item) => sum + ((item.lineTotalDpPaise * item.taxPercent) / 100).round());
            return Column(
              children: [
                _buildTotalRow('Subtotal', CurrencyUtils.formatPaise(subtotalPaise), isDark),
                _buildTotalRow('Tax (GST)', CurrencyUtils.formatPaise(taxPaise), isDark),
                _buildTotalRow('Shipping', order.courierFeeDisplay, isDark),
                const Divider(),
                _buildTotalRow('Total Amount', CurrencyUtils.formatPaise(subtotalPaise + taxPaise + order.courierFeePaise), isDark, isBold: true),
              ],
            );
          }),
        ],
      )
    );
  }

  Widget _buildLogisticsSection(BuildContext context, Order order, bool isDark) {
    return _buildSectionCard(
       context, isDark,
       title: 'Logistics & Delivery',
       icon: Icons.local_shipping,
       iconColor: AppColors.primaryBlue,
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            _buildInputLabel('Courier Provider'),
            _buildTextField(isDark, controller: _courierController, hint: 'e.g. FedEx, DHL, BlueDart'),
            const SizedBox(height: 12),
            _buildInputLabel('Tracking Number'),
            _buildTextField(isDark, controller: _trackingController, hint: 'e.g. TRK-990-111'),
            const SizedBox(height: 12),
            // Shipping Override
            _buildInputLabel('Override Shipping Charge (₹)'),
            TextField(
              controller: _shippingOverrideController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Leave blank to use standard shipping charge',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                prefixText: '₹ ',
                prefixStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                filled: true,
                fillColor: isDark ? Colors.black26 : Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey[200]!),
                ),
              ),
              onChanged: (_) => setState(() => _isDirty = true),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Standard charge will apply if left blank',
                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('Est. Delivery'),
                       InkWell(
                         onTap: () async {
                           final d = await showDatePicker(
                             context: context, 
                             initialDate: _estimatedDeliveryDate ?? DateTime.now(),
                             firstDate: DateTime.now().subtract(const Duration(days: 365)),
                             lastDate: DateTime.now().add(const Duration(days: 365)),
                           );
                           if (d != null) setState(() { _estimatedDeliveryDate = d; _isDirty = true; });
                         },
                         child: Container(
                           width: double.infinity,
                           padding: const EdgeInsets.all(12),
                           decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.grey[50],
                              border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!),
                              borderRadius: BorderRadius.circular(12)
                           ),
                           child: Text(
                             _estimatedDeliveryDate != null ? DateFormat('yyyy-MM-dd').format(_estimatedDeliveryDate!) : 'Select Date',
                             style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                           ),
                         ),
                       )
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Container(),) // Spacer or Action button
              ],
            )
         ],
       )
    );
  }

  Widget _buildNotesSection(BuildContext context, Order order, bool isDark) {
    return _buildSectionCard(
       context, isDark,
       title: 'Internal Notes',
       icon: Icons.sticky_note_2,
       iconColor: Colors.grey,
       child: TextField(
         controller: _notesController,
         maxLines: 4,
         style: TextStyle(color: isDark ? Colors.white : Colors.black87),
         decoration: InputDecoration(
           filled: true,
           fillColor: isDark ? Colors.yellow.withOpacity(0.05) : Colors.yellow[50],
           hintText: 'Add internal notes about this order...',
           hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
           border: OutlineInputBorder(
             borderRadius: BorderRadius.circular(12),
             borderSide: BorderSide(color: isDark ? Colors.yellow.withOpacity(0.1) : Colors.yellow[200]!)
           ),
           enabledBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(12),
             borderSide: BorderSide(color: isDark ? Colors.yellow.withOpacity(0.1) : Colors.yellow[200]!)
           ),
         ),
         onChanged: (_) => setState(() => _isDirty = true),
       )
    );
  }

  // Helpers

  Widget _buildSectionCard(BuildContext context, bool isDark, {required String title, required IconData icon, required Color iconColor, required Widget child, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white, // card-dark/light
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200]!),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: isDark ? Colors.grey.withOpacity(0.1) : Colors.grey[100], shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.grey[900])),
          trailing: trailing,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [child],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
    );
  }

  Widget _buildTextField(bool isDark, {required TextEditingController controller, String hint = ''}) {
    return TextField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: isDark ? Colors.black26 : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      onChanged: (_) => setState(() => _isDirty = true),
    );
  }

  Widget _buildTotalRow(String label, String value, bool isDark, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: isBold ? 14 : 12, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? (isDark ? Colors.white : Colors.black87) : Colors.grey[500],
          )),
          Text(value, style: TextStyle(
            fontSize: isBold ? 16 : 12, 
            fontWeight: FontWeight.bold, 
            color: isBold ? AppColors.primaryBlue : (isDark ? Colors.white : Colors.black87),
          )),
        ],
      ),
    );
  }

  Widget _buildFooterIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Colors.transparent, // or slight hover
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }


  Widget _buildOrderItemRow(dynamic item, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              image: item.imageUrl != null ? DecorationImage(image: NetworkImage(item.imageUrl!), fit: BoxFit.cover) : null,
            ),
            child: item.imageUrl == null ? const Icon(Icons.image_not_supported, size: 20, color: Colors.grey) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark?Colors.white:Colors.black87)),
                const SizedBox(height: 4),
                Text('SKU: ${item.sku ?? "N/A"}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                const SizedBox(height: 4),
                if (_isEditingItems)
                  Row(
                    children: [
                      Text(
                        CurrencyUtils.formatPaise(item.dpPricePaise),
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 28,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Minus button
                            InkWell(
                              onTap: () {
                                if (item.qty > 1) {
                                  _updateItemQuantity(item.id, item.qty - 1);
                                }
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                child: Icon(Icons.remove, size: 16, color: item.qty > 1 ? Colors.grey[700] : Colors.grey[300]),
                              ),
                            ),
                            // Quantity text
                            Container(
                              width: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.symmetric(vertical: BorderSide(color: Colors.grey.shade300)),
                              ),
                              child: Text(item.qty.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            // Plus button
                            InkWell(
                              onTap: () => _updateItemQuantity(item.id, item.qty + 1),
                              child: Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                child: Icon(Icons.add, size: 16, color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Text.rich(TextSpan(
                    text: CurrencyUtils.formatPaise(item.dpPricePaise),
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontSize: 12),
                    children: [ TextSpan(text: ' x ${item.qty}', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.normal)) ]
                  )),
              ],
            ),
          ),
          if (_isEditingItems)
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Colors.red),
              onPressed: () => setState(() {
                _localItems.removeWhere((i) => i.id == item.id);
                _isDirty = true;
              }),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> addr) {
     final parts = [
       addr['street'],
       addr['city'],
       addr['state'],
       addr['zipCode'],
       addr['country']
     ].where((e) => e != null && e.toString().isNotEmpty).join(', ');
     return parts;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing': // Assuming this maps to confirming/confirmed
        return Colors.indigo;
      case 'confirmed':
        return Colors.blue;
      case 'dispatched':
        return Colors.blueAccent;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'returned':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Returns the shipping override to send to the API:
  /// - null  → remove any existing override (revert to standard charge)
  /// - int   → set override to this paise amount
  /// - -1 sentinel → do NOT include field in payload (field wasn't touched)
  int? _buildShippingOverride() {
    final text = _shippingOverrideController.text.trim();
    if (text.isEmpty) {
      // Blank means "use standard charge" → send null to clear override
      return null;
    }
    final rupees = double.tryParse(text);
    if (rupees == null) return null; // Invalid input → clear
    return (rupees * 100).round();
  }
}
