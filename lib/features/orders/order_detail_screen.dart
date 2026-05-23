/// Order detail screen
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';
import '../../services/order_service.dart';
import '../../providers/cart_provider.dart'; // for orderServiceProvider

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isListView = true; // Default to List View
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    // Force refresh on entry to ensure status is up to date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(orderProvider(widget.orderId));
    });
  }

  Future<void> _downloadInvoice() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final orderService = ref.read(orderServiceProvider);
      final bytes = await orderService.downloadInvoice(widget.orderId);
      final fileName = 'Invoice_${widget.orderId.substring(0, 8).toUpperCase()}.pdf';

      if (kIsWeb) {
        // Web: not fully supported in mobile-first app; show message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Web download not supported. Use mobile app.')),
          );
        }
        return;
      }

      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // Desktop: show save file dialog
        final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Invoice',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          bytes: bytes,
        );
        if (path != null) {
          final file = File(path);
          await file.writeAsBytes(bytes);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Invoice saved to $path')),
                  ],
                ),
                backgroundColor: Colors.green[700],
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'VIEW',
                  textColor: Colors.white,
                  onPressed: () => OpenFilex.open(path),
                ),
              ),
            );
          }
        }
      } else {
        // Mobile (Android / iOS): save to Downloads / Documents
        Directory? dir;
        if (Platform.isAndroid) {
          dir = Directory('/storage/emulated/0/Download');
          if (!await dir.exists()) dir = await getApplicationDocumentsDirectory();
        } else {
          dir = await getApplicationDocumentsDirectory();
        }

        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Invoice saved: ${file.path}')),
                ],
              ),
              backgroundColor: Colors.green[700],
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'VIEW',
                textColor: Colors.white,
                onPressed: () => OpenFilex.open(file.path),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to download invoice: ${e.toString().replaceAll('Exception: ', '')}')),
              ],
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderProvider(widget.orderId));
    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.isAdmin ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'ORDER DETAIL', 
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          )
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: Icon(Icons.edit_note, color: isDark ? Colors.white : Colors.black87),
              onPressed: () => _showEditDialog(context, ref, orderAsync.value!),
            ),
        ],
      ),
      body: orderAsync.when(
        data: (order) => _buildOrderDetail(context, order, isDark),
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.refresh(orderProvider(widget.orderId)),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Order order) {
    final statusList = ['pending', 'confirmed', 'dispatched', 'delivered', 'cancelled', 'returned'];
    String selectedStatus = order.status.nameStr;
    DateTime? selectedDate = order.estimatedDeliveryDate;
    String courierProvider = order.courier?['provider'] ?? '';
    final courierController = TextEditingController(text: courierProvider);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Update Order'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: statusList.contains(selectedStatus.toLowerCase()) ? selectedStatus.toLowerCase() : null,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: statusList.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                    onChanged: (val) => setState(() => selectedStatus = val!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: courierController,
                     decoration: const InputDecoration(labelText: 'Shipping Method / Courier'),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Est. Delivery Date'),
                    subtitle: Text(selectedDate != null 
                      ? DateFormat('MMM dd, yyyy').format(selectedDate!) 
                      : 'Not set'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await ref.read(ordersProvider.notifier).updateOrderStatus(
                      widget.orderId, 
                      selectedStatus, 
                      estimatedDeliveryDate: selectedDate,
                      courierProvider: courierController.text,
                    );
                    ref.invalidate(orderProvider(widget.orderId));
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildOrderDetail(BuildContext context, Order order, bool isDark) {
    // Header Logic
    String headline = 'Order Placed';
    if (order.status == OrderStatus.delivered) {
      headline = 'Delivered';
    } else if (order.estimatedDeliveryDate != null) {
      final now = DateTime.now();
      final diff = order.estimatedDeliveryDate!.difference(now).inDays;
      if (diff == 0) headline = 'Arriving\nToday';
      else if (diff == 1) headline = 'Arriving\nTomorrow';
      else headline = 'Arriving\n${DateFormat('EEE, MMM dd').format(order.estimatedDeliveryDate!)}';
    } else {
       headline = order.status.nameStr.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    }

    // Progress Logic
    int currentStep = 0;
    if (order.status == OrderStatus.confirmed) currentStep = 1; // Ordered
    else if (order.status == OrderStatus.dispatched) currentStep = 2; // Shipped (In Transit)
    else if (order.status == OrderStatus.delivered) currentStep = 3; // Delivered
    // "In Transit" is often same as shipped or distinct step. Design has Ordered, Shipped, In Transit, Delivered.
    // Let's simplified mapping: 
    // Ordered (Pending/Confirmed) -> Shipped (Dispatched) -> Delivered. 
    // Design has 3 gaps, 4 points? No, visual shows bar.
    // Let's use 0.0 to 1.0 progress.
    double progress = 0.05; // Just started
    if (order.status == OrderStatus.confirmed) progress = 0.25;
    if (order.status == OrderStatus.dispatched) progress = 0.65;
    if (order.status == OrderStatus.delivered) progress = 1.0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Head Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            Text(
                               headline,
                               style: TextStyle(
                                  fontSize: 24, 
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  color: isDark ? Colors.white : Colors.black87
                               ),
                            ),
                            Text(
                               'Order ID: #${order.orderNo}',
                               style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                               ),
                            ),
                         ],
                      ),
                      const SizedBox(height: 24),
                      // Progress Bar
                      Stack(
                         children: [
                            Container(
                               height: 8,
                               width: double.infinity,
                               decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                               ),
                            ),
                            Container(
                               height: 8,
                               width: MediaQuery.of(context).size.width * 0.8 * progress, // approximation
                               decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                     BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.6), blurRadius: 8)
                                  ]
                               ),
                            ),
                         ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Expanded(child: _buildProgressLabel('Ordered', currentStep >= 0, isDark, TextAlign.left)),
                             Expanded(child: _buildProgressLabel('Shipped', currentStep >= 1, isDark, TextAlign.center)),
                             Expanded(child: _buildProgressLabel('In Transit', currentStep >= 2, isDark, TextAlign.center)),
                             Expanded(child: _buildProgressLabel('Delivered', currentStep >= 3, isDark, TextAlign.right)),
                          ],
                      )
                    ],
                  ),
                ),
                
                // Ordered Items
                Container(
                   padding: const EdgeInsets.symmetric(vertical: 24),
                   decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: Border.symmetric(horizontal: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[100]!)),
                   ),
                   child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               Row(
                                 children: [
                                   Text('Ordered Items', 
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                   const SizedBox(width: 12),
                                   Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                     decoration: BoxDecoration(
                                       color: isDark ? Colors.grey[700] : Colors.grey[100],
                                       borderRadius: BorderRadius.circular(12),
                                     ),
                                     child: Text('${order.items.length}', 
                                       style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[300] : Colors.grey[600])),
                                   ),
                                 ],
                               ),
                               // View Toggle Buttons
                               Container(
                                 decoration: BoxDecoration(
                                   color: isDark ? Colors.grey[800] : Colors.grey[100],
                                   borderRadius: BorderRadius.circular(8),
                                 ),
                                 padding: const EdgeInsets.all(2),
                                 child: Row(
                                   children: [
                                     _buildViewToggleButton(Icons.view_carousel, !_isListView, isDark, () => setState(() => _isListView = false)),
                                     _buildViewToggleButton(Icons.view_list, _isListView, isDark, () => setState(() => _isListView = true)),
                                   ],
                                 ),
                               ),
                             ],
                           ),
                         ),
                         const SizedBox(height: 16),
                         if (_isListView)
                           // Vertical List View
                           ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: order.items.length,
                              separatorBuilder: (_, __) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Divider(color: isDark ? Colors.grey[800] : Colors.grey[100]),
                              ),
                              itemBuilder: (context, index) {
                                 final item = order.items[index];
                                 return Row(
                                    children: [
                                       // Product Image
                                       Container(
                                          width: 60, height: 60,
                                          decoration: BoxDecoration(
                                             borderRadius: BorderRadius.circular(12),
                                             color: isDark ? Colors.grey[800] : Colors.grey[50],
                                             border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
                                             image: item.resolvedImageUrl != null ? DecorationImage(
                                                image: NetworkImage(item.resolvedImageUrl!),
                                                fit: BoxFit.cover,
                                             ) : null,
                                          ),
                                          child: item.resolvedImageUrl == null ? Icon(Icons.shopping_bag_outlined, color: isDark ? Colors.grey[600] : Colors.grey[400]) : null,
                                       ),
                                       const SizedBox(width: 16),
                                       
                                       // Details
                                       Expanded(
                                         child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                               Text(item.name, 
                                                  maxLines: 2, 
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white: Colors.black87)
                                               ),
                                               const SizedBox(height: 4),
                                               Row(
                                                 children: [
                                                    Text(item.priceDisplay, 
                                                       style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[500])
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text('x${item.qty}', 
                                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                                    ),
                                                 ],
                                               ),
                                            ],
                                         ),
                                       ),
                                       
                                       // Line Total
                                       Text(
                                          item.lineTotalDisplay,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                                       ),
                                    ],
                                 );
                              },
                           )
                         else
                           // Horizontal Card View
                           SizedBox(
                              height: 250, // Increased height to prevent overflow (was 230)
                              child: ListView.separated(
                                 padding: const EdgeInsets.symmetric(horizontal: 24),
                                 scrollDirection: Axis.horizontal,
                                 itemCount: order.items.length,
                                 separatorBuilder: (_, __) => const SizedBox(width: 16),
                                 itemBuilder: (context, index) {
                                    final item = order.items[index];
                                    return Container(
                                       width: 160,
                                       decoration: BoxDecoration(
                                         color: isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.white,
                                         borderRadius: BorderRadius.circular(16),
                                         border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
                                         boxShadow: [
                                            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 8, offset: const Offset(0, 4))
                                         ]
                                       ),
                                       child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                             // Image Section
                                             Expanded(
                                               flex: 4,
                                               child: Stack(
                                                 children: [
                                                   Container(
                                                     decoration: BoxDecoration(
                                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                                        color: isDark ? Colors.grey[800] : Colors.grey[50],
                                                        image: item.resolvedImageUrl != null ? DecorationImage(
                                                           image: NetworkImage(item.resolvedImageUrl!),
                                                           fit: BoxFit.cover,
                                                        ) : null,
                                                     ),
                                                     child: item.resolvedImageUrl == null ? Center(child: Icon(Icons.shopping_bag_outlined, size: 40, color: isDark ? Colors.grey[600] : Colors.grey[300])) : null,
                                                   ),
                                                 ],
                                               ),
                                             ),
                                             
                                             // Details Section
                                             Expanded(
                                               flex: 3,
                                               child: Padding(
                                                 padding: const EdgeInsets.all(12),
                                                 child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                       Text(item.name, 
                                                          maxLines: 2, 
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2, color: isDark ? Colors.white: Colors.black87)
                                                       ),
                                                       
                                                       Column(
                                                         crossAxisAlignment: CrossAxisAlignment.start,
                                                         children: [
                                                           // Row 1: Quantity x Unit Price
                                                           Row(
                                                             children: [
                                                               Container(
                                                                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                 decoration: BoxDecoration(
                                                                   color: isDark ? Colors.grey[700] : Colors.grey[100],
                                                                   borderRadius: BorderRadius.circular(6),
                                                                 ),
                                                                 child: Text('${item.qty}x', 
                                                                   style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[300] : Colors.black87)),
                                                               ),
                                                               const SizedBox(width: 8),
                                                               Text(item.priceDisplay, 
                                                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.w500)
                                                               ),
                                                             ],
                                                           ),
                                                           
                                                           const SizedBox(height: 6),
                                                           
                                                           // Row 2: Total Price (New Line)
                                                           Text(item.lineTotalDisplay, 
                                                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)
                                                           ),
                                                         ],
                                                       )
                                                    ],
                                                 ),
                                               ),
                                             ),
                                          ],
                                       ),
                                    );
                                 },
                              ),
                           ),
                      ],
                   ),
                ),
                
                const SizedBox(height: 24),
                
                // Details Expansion Panels
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                     children: [
                        _buildExpansionTile(
                           context, 
                           icon: Icons.location_on, 
                           color: Colors.blue, 
                           title: 'Shipping Details', 
                           isDark: isDark,
                           children: [
                              Text(order.addressSnapshot?['name'] ?? 'N/A', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark?Colors.white:Colors.black87)),
                              Text(_formatAddress(order.addressSnapshot ?? {}), style: TextStyle(fontSize: 14, color: isDark?Colors.grey[400]:Colors.grey[600], height: 1.5)),
                              const SizedBox(height: 12),
                              if (order.courier != null && order.courier!['provider'] != null)
                              Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 children: [
                                    const Text('METHOD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    Flexible(
                                      child: Text(
                                        order.courier!['provider'], 
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark?Colors.white:Colors.black87),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                 ],
                              )
                           ]
                        ),

                        const SizedBox(height: 12),
                        _buildExpansionTile(
                           context, 
                           icon: Icons.receipt_long, 
                           color: Colors.orange, 
                           title: 'Order Summary', 
                           isDark: isDark,
                           children: [
                              _buildSummaryRow('Subtotal', order.subtotalDisplay, isDark),
                              _buildSummaryRow('Tax (GST)', order.taxDisplay, isDark),
                              _buildSummaryRow('Shipping', order.courierFeePaise > 0 ? order.courierFeeDisplay : 'Free', isDark, isGreen: order.courierFeePaise == 0),
                              const SizedBox(height: 12),
                              Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 children: [
                                    Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: isDark?Colors.white:Colors.black87)),
                                    Text(order.grandTotalDisplay, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark?Colors.white:Colors.black87)),
                                 ],
                              )
                           ]
                        ),
                     ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        
        // Footer Buttons
        Padding(
           padding: const EdgeInsets.all(16),
           child: Row(
              children: [
                 Expanded(
                    flex: 1,
                    child: OutlinedButton(
                       onPressed: () => context.push('/profile/support'), 
                       style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                       ),
                       child: Text('Contact Support', style: TextStyle(color: isDark?Colors.white:Colors.black87, fontWeight: FontWeight.bold)),
                    ),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                       onPressed: _isDownloading ? null : _downloadInvoice,
                       icon: _isDownloading
                           ? const SizedBox(
                               width: 18, height: 18,
                               child: CircularProgressIndicator(
                                 strokeWidth: 2,
                                 color: Colors.white,
                               ),
                             )
                           : const Icon(Icons.download, size: 20),
                       label: Text(_isDownloading ? 'Generating...' : 'Download Invoice'),
                       style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                       ),
                    ),
                 ),
              ],
           ),
        ),
      ],
    );
  }

  Widget _buildViewToggleButton(IconData icon, bool isActive, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: isActive ? BoxDecoration(
          color: isDark ? Colors.grey[700] : Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)
          ]
        ) : null,
        child: Icon(icon, size: 20, color: isActive ? Theme.of(context).colorScheme.primary : (isDark ? Colors.grey[500] : Colors.grey[400])),
      ),
    );
  }

  Widget _buildProgressLabel(String text, bool isActive, bool isDark, TextAlign align) {
     return Text(
        text.toUpperCase(),
        textAlign: align,
        style: TextStyle(
           fontSize: 10,
           fontWeight: FontWeight.bold,
           letterSpacing: 0.5,
           color: isActive ? Theme.of(context).colorScheme.primary : (isDark ? Colors.grey[700] : Colors.grey[400]),
        ),
     );
  }

  Widget _buildExpansionTile(BuildContext context, {required IconData icon, required Color color, required String title, required bool isDark, required List<Widget> children}) {
     return Container(
        decoration: BoxDecoration(
           color: isDark ? const Color(0xFF1E293B) : Colors.white,
           borderRadius: BorderRadius.circular(12),
           boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
           ]
        ),
        child: Theme(
           data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
           child: ExpansionTile(
              initiallyExpanded: true,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                 ),
                 child: Icon(icon, color: color, size: 20),
              ),
              title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark?Colors.white:Colors.black87)),
              childrenPadding: const EdgeInsets.fromLTRB(56, 0, 16, 20),
              children: [
                 Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)
              ],
           ),
        ),
     );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark, {bool isGreen = false}) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 8.0),
       child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(label, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 13)),
             Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: isGreen ? Colors.green : (isDark ? Colors.white : Colors.black87), fontSize: 13)),
          ],
       ),
     );
  }

  String _formatAddress(Map<String, dynamic> address) {
    final parts = <String>[];
    if (address['street'] != null) parts.add(address['street']);
    if (address['city'] != null) parts.add(address['city']);
    if (address['state'] != null) parts.add(address['state']);
    if (address['zipCode'] != null) parts.add(address['zipCode']);
    return parts.join(', ');
  }

  String _formatPaymentMethod(String? method) {
    switch (method?.toUpperCase()) {
      case 'COD':
        return 'Cash on Delivery';
      case 'STRIPE':
        return 'Credit/Debit Card (Stripe)';
      case 'RAZORPAY':
        return 'Razorpay';
      default:
        return 'Cash on Delivery';
    }
  }
}
