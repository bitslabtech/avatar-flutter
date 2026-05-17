import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminLogScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final String userRole;

  const AdminLogScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userRole,
  });

  @override
  ConsumerState<AdminLogScreen> createState() => _AdminLogScreenState();
}

class _AdminLogScreenState extends ConsumerState<AdminLogScreen> {
  bool _isLoading = true;
  List<dynamic> _logs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    try {
      print('AdminLogScreen: Fetching logs for ${widget.userId}');
      final logs = await ref.read(adminServiceProvider).getAuditLogs(widget.userId);
      print('AdminLogScreen: Received logs type: ${logs.runtimeType}');
      print('AdminLogScreen: Received data: $logs');
      print('AdminLogScreen: Received ${logs.length} logs');
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      print('AdminLogScreen: Error fetching logs: $e');
      print(stack);
      if (mounted) {
        setState(() {
          _error = 'Failed to load logs: $e';
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status, bool isDark) {
    switch (status) {
      case 'SUCCESS':
        return Colors.green;
      case 'WARNING':
        return Colors.orange;
      case 'ERROR':
        return Colors.red;
      default:
        return isDark ? Colors.blue.shade300 : Colors.blue;
    }
  }

  Color _getStatusBgColor(String status, bool isDark) {
    switch (status) {
      case 'SUCCESS':
        return isDark ? Colors.green.withOpacity(0.1) : Colors.green.shade50;
      case 'WARNING':
        return isDark ? Colors.orange.withOpacity(0.1) : Colors.orange.shade50;
      case 'ERROR':
        return isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50;
      default:
        return isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.shade50;
    }
  }

  IconData _getActionIcon(String actionType) {
    switch (actionType) {
      case 'ORDER':
        return Icons.shopping_cart;
      case 'USER':
        return Icons.person_outline;
      case 'AUTH':
        return Icons.lock_outline;
      case 'INVENTORY':
        return Icons.inventory_2_outlined;
      case 'DELETE':
        return Icons.delete_outline;
      case 'SETTINGS':
        return Icons.settings_outlined;
      case 'VIEW':
        return Icons.visibility_outlined;
      default:
        return Icons.info_outline;
    }
  }
  
   Color _getActionColor(String actionType) {
    switch (actionType) {
      case 'ORDER':
        return Colors.green;
      case 'USER':
        return Colors.blue;
      case 'AUTH':
        return Colors.amber;
      case 'INVENTORY':
        return Colors.purple;
      case 'DELETE':
        return Colors.pink;
      case 'SETTINGS':
        return Colors.grey;
      case 'VIEW':
        return Colors.teal;
      default:
        return Colors.indigo;
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1C2333) : Colors.white;
    final backgroundColor = isDark ? const Color(0xFF101522) : const Color(0xFFF6F7F8);
    final borderColor = isDark ? const Color(0xFF323F67) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
        ),
        title: Text(
          'Activity Logs',
          style: GoogleFonts.manrope(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // User Profile Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                      ),
                      child: Stack(
                        children: [
                          Center(child: Icon(Icons.person, size: 32, color: Colors.grey[600])),
                           Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: surfaceColor, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName,
                            style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.userRole.toUpperCase(),
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ID: #${widget.userId.substring(0, 8)}',
                                style: GoogleFonts.manrope(fontSize: 12, color: subTextColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.filter_list, color: subTextColor),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Timeline
              if (_isLoading)
                 const Center(child: CircularProgressIndicator())
              else if (_error != null)
                 Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              else if (_logs.isEmpty)
                 Center(child: Text('No logs found', style: TextStyle(color: subTextColor)))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final actionType = log['action_type']?.toString() ?? 'OTHER';
                    final status = log['status']?.toString() ?? 'SUCCESS';
                    final title = log['title']?.toString() ?? 'Unknown Action';
                    final details = log['details']?.toString() ?? '';
                    
                    DateTime date;
                    try {
                      date = DateTime.parse(log['created_at']);
                    } catch (e) {
                      date = DateTime.now();
                    }
                    
                    final formattedDate = DateFormat('MMM dd, hh:mm a').format(date);
                    // IP address removed as per request
                    
                    // Colors based on Action Type
                    Color accentColor;
                     switch (actionType) {
                      case 'ORDER': accentColor = Colors.green; break;
                      case 'USER': accentColor = Colors.blue; break;
                      case 'AUTH': accentColor = Colors.amber; break;
                      case 'INVENTORY': accentColor = Colors.purple; break;
                      case 'DELETE': accentColor = Colors.pink; break;
                      case 'SETTINGS': accentColor = Colors.grey; break;
                      case 'VIEW': accentColor = Colors.teal; break;
                      default: accentColor = Colors.indigo;
                    }


                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline Line and Icon
                          SizedBox(
                            width: 50,
                            child: Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isDark ? accentColor.withOpacity(0.2) : accentColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: surfaceColor, width: 4),
                                  ),
                                  child: Icon(_getActionIcon(actionType), size: 18, color: accentColor),
                                ),
                                if (index != _logs.length - 1)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: borderColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Content Card
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: GoogleFonts.manrope(
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (details.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2.0),
                                                  child: Text(
                                                    details,
                                                    style: GoogleFonts.manrope(
                                                      color: subTextColor,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getStatusBgColor(status, isDark),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            status,
                                            style: GoogleFonts.manrope(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _getStatusColor(status, isDark),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                       padding: const EdgeInsets.only(top: 12),
                                       decoration: BoxDecoration(
                                         border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100)),
                                       ),
                                       child: Row(
                                         children: [
                                           Icon(Icons.access_time, size: 14, color: subTextColor),
                                           const SizedBox(width: 4),
                                           Text(formattedDate, style: TextStyle(fontSize: 11, color: subTextColor)),
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
                    );
                  },
                ),
                
              const SizedBox(height: 24),
              if (!_isLoading && _logs.isNotEmpty)
                  Center(
                    child: TextButton(
                      onPressed: () {}, 
                      child: Text('Load older activities', style: TextStyle(color: subTextColor)),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
