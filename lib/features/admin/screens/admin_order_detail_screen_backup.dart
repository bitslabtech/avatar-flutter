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
  late String _selectedStatus;
  DateTime? _estimatedDeliveryDate;
  bool _isDirty = false;
  bool _isEditingItems = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _trackingController = TextEditingController();
    _courierController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _trackingController.dispose();
    _courierController.dispose();
    super.dispose();
  }

  /// Initialize state from order data once loaded
  void _initializeState(Order order) {
    if (!_isDirty) { // Only init if user hasn't started editing (or first load)
        _notesController.text = order.notes ?? '';
        _trackingController.text = order.tracking?['trackingNumber'] ?? '';
        _courierController.text = order.courier?['provider'] ?? '';
        _selectedStatus = order.status.nameStr;
        _estimatedDeliveryDate = order.estimatedDeliveryDate;
    }
  }

  Future<void> _saveChanges() async {
    try {
      // Show loading or disable button
      await ref.read(ordersProvider.notifier).updateOrderStatus(
        widget.orderId,
        _selectedStatus,
        estimatedDeliveryDate: _estimatedDeliveryDate,
        notes: _notesController.text,
        courierProvider: _courierController.text,
      );
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

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderProvider(widget.orderId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), // background-dark : background-light
      body: orderAsync.when(
        data: (order) {
            _initializeState(order);
            return Stack(
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
                      _buildPaymentSection(context, order, isDark),
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
                          // Delete Button
                          _buildFooterIconButton(Icons.delete, Colors.red[400]!, () {
                             // Delete action
                          }),
                          const SizedBox(width: 8),
                          // Download Button
                          _buildFooterIconButton(Icons.download, Colors.grey[400]!, () {
                             // Download action
                          }),
                          const SizedBox(width: 8),
                          // Save Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 20),
                                  SizedBox(width: 8),
                                  Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
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
            );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (err, stack) => AppErrorWidget(message: err.toString(), onRetry: () => ref.refresh(orderProvider(widget.orderId))),
      ),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1), // Dynamic based on status?
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.withOpacity(0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
               value: _selectedStatus,
               isDense: true,
               icon: const Icon(Icons.expand_more, size: 18, color: Colors.orange),
               style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
               dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
               onChanged: (val) {
                 if (val != null) setState(() { _selectedStatus = val; _isDirty = true; });
               },
               items: OrderStatus.values.map((s) => DropdownMenuItem(
                 value: s.nameStr,
                 child: Text(s.nameStr.toUpperCase()),
               )).toList(),
            ),
          ),
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), blurRadius: 40)],
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
                        style: TextStyle(fontSize: 14, fontFamily: 'monospace', color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
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
      iconColor: Theme.of(context).colorScheme.primary,
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
      title: 'Order Items (${order.items.length})',
      icon: Icons.inventory_2,
      iconColor: Theme.of(context).colorScheme.primary,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isEditingItems)
            Icon(Icons.expand_more, color: isDark ? Colors.grey[400] : Colors.grey[600])
          else
            IconButton(
              icon: Icon(Icons.edit, size: 20, color: Theme.of(context).colorScheme.primary),
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
              children: order.items.map((item) => Padding(
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
                          Text('SKU: ${item.sku}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                          const SizedBox(height: 4),
                          Text.rich(TextSpan(
                            text: CurrencyUtils.formatPaise(item.dpPricePaise),
                            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 12),
                            children: [ TextSpan(text: ' x ${item.qty}', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.normal)) ]
                          )),
                        ],
                      ),
                    )
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Totals
          _buildTotalRow('Subtotal', order.subtotalDisplay, isDark),
          _buildTotalRow('Tax (GST)', order.taxDisplay, isDark),
          _buildTotalRow('Shipping', order.courierFeeDisplay, isDark),
        ],
      )
    );
  }

  Widget _buildLogisticsSection(BuildContext context, Order order, bool isDark) {
    return _buildSectionCard(
       context, isDark,
       title: 'Logistics & Delivery',
       icon: Icons.local_shipping,
       iconColor: Theme.of(context).colorScheme.primary,
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            _buildInputLabel('Courier Provider'),
            _buildTextField(isDark, controller: _courierController, hint: 'e.g. FedEx, DHL, BlueDart'),
            const SizedBox(height: 12),
            _buildInputLabel('Tracking Number'),
            _buildTextField(isDark, controller: _trackingController, hint: 'e.g. TRK-990-111'),
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

  Widget _buildPaymentSection(BuildContext context, Order order, bool isDark) {
    return _buildSectionCard(
      context, isDark,
      title: 'Payment Details',
      icon: Icons.payments,
      iconColor: Colors.green,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : Colors.grey[50],
          borderRadius: BorderRadius.circular(16)
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('METHOD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(order.notes?.contains('COD') == true ? 'Cash on Delivery' : 'Online (Stripe)', 
                       style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                 ]),
                 Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.verified, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text('Paid', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[400])), // Logic needed
                      ],
                    )
                 ]),
              ],
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('TRANSACTION ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Text('txn_${order.id.substring(0,8)}_secure', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            )
          ],
        ),
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

  Widget _buildTotalRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
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
}
