import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../admin/providers/product_management_provider.dart';

class BulkProductOperationsScreen extends ConsumerStatefulWidget {
  const BulkProductOperationsScreen({super.key});

  @override
  ConsumerState<BulkProductOperationsScreen> createState() => _BulkProductOperationsScreenState();
}

class _BulkProductOperationsScreenState extends ConsumerState<BulkProductOperationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _lastExportPath;
  Map<String, dynamic>? _importResult;
  String _importStep = 'upload'; // upload, ready, processing, complete
  int _progressStep = 0;
  String? _selectedFilePath;
  
  // Design Colors
  static const Color primaryColor = Color(0xFF4b2bee);
  static const Color bgColorDark = Color(0xFF131022);
  static const Color surfaceColorDark = Color(0xFF1d1a2e);
  static const Color textColorMuted = Color(0xFFa19db9);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleExport() async {
    setState(() => _isLoading = true);
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating Export Template... Please wait.')),
      );
      
      final path = await ref.read(productManagementProvider.notifier).exportProducts();
      
      if (mounted && path != null) {
        setState(() => _lastExportPath = path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export saved to: $path'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePickFile() async {
     setState(() => _isLoading = true);
     try {
       final path = await ref.read(productManagementProvider.notifier).pickImportFile();
       if (mounted && path != null) {
         setState(() {
           _selectedFilePath = path;
           _importStep = 'ready';
           _progressStep = 0;
           _importResult = null; // Reset previous results
         });
       }
     } finally {
       if (mounted) setState(() => _isLoading = false);
     }
  }

  Future<void> _handleStartImport() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isLoading = true;
      _importStep = 'processing';
      _importResult = null;
    });

    try {
      // Step 1: Upload (Already done visually, moving to Map)
      setState(() => _progressStep = 1);
      await Future.delayed(const Duration(seconds: 1));
      
      // Start API call in parallel but perform visual steps
      final futureResult = ref.read(productManagementProvider.notifier).uploadImportFile(_selectedFilePath!);
      
      // Step 2: Validate
      if (mounted) setState(() => _progressStep = 2);
      await Future.delayed(const Duration(seconds: 1));

      // Step 3: Finish / Saving
      if (mounted) setState(() => _progressStep = 3);
       await Future.delayed(const Duration(seconds: 1));
      
      final result = await futureResult;
      
      if (mounted) {
        setState(() {
          _importResult = result;
          _importStep = 'complete';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _importStep = 'ready'; // Go back to ready state to retry? Or upload?
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  void _resetImport() {
    setState(() {
      _selectedFilePath = null;
      _selectedFilePath = null;
      _importResult = null;
      _importStep = 'upload';
      _progressStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bg = isDark ? bgColorDark : const Color(0xFFF6F6F8);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
             // Header
            _buildHeader(context, isDark),
            
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildTabToggle(isDark),
            ),
            
            const SizedBox(height: 24),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: _buildImportView(isDark),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: _buildExportView(isDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x992b2839) : Colors.white.withOpacity(0.9), // Glass effect
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            color: isDark ? Colors.white : Colors.black,
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            ),
          ),
          Text(
            'Bulk Import/Export',
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 40), // Balance
        ],
      ),
    );
  }

  Widget _buildTabToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? surfaceColorDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          return Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  'Import', 
                  Icons.cloud_upload_outlined, 
                  0, 
                  isDark
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTabButton(
                  'Export', 
                  Icons.cloud_download_outlined, 
                  1, 
                  isDark
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon, int index, bool isDark) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              size: 18, 
              color: isSelected ? Colors.white : (isDark ? textColorMuted : Colors.grey),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? textColorMuted : Colors.grey),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportView(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Upload Area
        GestureDetector(
          onTap: _importStep == 'upload' ? _handlePickFile : null,
          child: Container(
            height: 240,
            decoration: BoxDecoration(
              color: (isDark ? surfaceColorDark : Colors.white).withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedFilePath != null ? Colors.green : primaryColor.withOpacity(0.4),
                style: BorderStyle.solid, 
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: _selectedFilePath != null ? Colors.green.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _selectedFilePath != null ? Icons.check : Icons.upload_file, 
                          size: 32, 
                          color: _selectedFilePath != null ? Colors.green : primaryColor
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedFilePath != null) ...[
                        Text(
                          'File Selected',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                         const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _selectedFilePath!.split(Platform.pathSeparator).last,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? textColorMuted : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Action Buttons
                        if (_importStep == 'ready' || _importStep == 'processing')
                           Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                                OutlinedButton(
                                  onPressed: _resetImport, 
                                  child: const Text('Change File'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _importStep == 'processing' ? null : _handleStartImport,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: _importStep == 'processing' 
                                      ? Container(width: 16, height: 16, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.play_arrow, size: 16),
                                  label: Text(_importStep == 'processing' ? 'Importing...' : 'Start Import'),
                                ),
                             ],
                           ),
                      ] else ...[
                        Text(
                          'Drop & Upload',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Supports CSV or XLSX up to 50MB',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? textColorMuted : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _handlePickFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(_isLoading ? 'Loading...' : 'Select File'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Warning Note
        if (_importStep == 'upload')
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: isDark ? textColorMuted : Colors.grey.shade700, height: 1.4),
                  children: const [
                    TextSpan(text: 'Note: ', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    TextSpan(text: 'Import only exported excel files. Do not modify the structure or headers.'),
                  ],
                ),
              ),
            ),
          ],
        ),
        
         if (_importStep == 'processing' || _importStep == 'complete') ...[
          const SizedBox(height: 24),
          
          // Import Workflow / Status
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? surfaceColorDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.analytics_outlined, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Import Workflow',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    if (_importResult != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Completed', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor)),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                // Stepper or Result View
                if (_importResult == null) ...[
                  _buildWorkflowStep('Upload File', 'Ready to process your local file', isActive: _progressStep >= 0, isCompleted: _progressStep > 0), 
                  _buildWorkflowStep('Map Columns', 'Automatic field mapping', isActive: _progressStep >= 1, isCompleted: _progressStep > 1),
                  _buildWorkflowStep('Validate Data', 'Integrity check and error scanning', isActive: _progressStep >= 2, isCompleted: _progressStep > 2),
                  _buildWorkflowStep('Finish', 'Final import to live database', isActive: _progressStep >= 3, isCompleted: _importStep == 'complete'),
                ] else ...[
                  // Result Summary
                  _buildResultSummary(isDark),
                ],
              ],
            ),
          ),
         ]
      ],
    );
  }

  Widget _buildExportView(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
             color: (isDark ? surfaceColorDark : Colors.white).withOpacity(0.4),
             borderRadius: BorderRadius.circular(16),
             border: Border.all(color: primaryColor.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              const Icon(Icons.table_view_rounded, size: 60, color: primaryColor),
              const SizedBox(height: 20),
              Text(
                'Export Current Products',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Generate an Excel file with all your products, including Brands, Categories, and Variations. Use this for backups or bulk editing.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? textColorMuted : Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
               ElevatedButton.icon(
                onPressed: _handleExport,
                icon: const Icon(Icons.download),
                label: const Text('Export Excel File'), // Updated Label
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        if (_lastExportPath != null) ...[
          const SizedBox(height: 16),
          Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: Colors.green.withOpacity(0.1),
               borderRadius: BorderRadius.circular(8),
             ),
             child: Row(
               children: [
                 const Icon(Icons.check_circle, color: Colors.green, size: 20),
                 const SizedBox(width: 8),
                 Expanded(child: Text('Saved to: $_lastExportPath', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87))),
               ],
             ),
          ),
        ]
      ],
    );
  }

  Widget _buildWorkflowStep(String title, String subtitle, {bool isActive = false, bool isCompleted = false, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? primaryColor : (isActive ? primaryColor.withOpacity(0.2) : Colors.transparent),
                shape: BoxShape.circle,
                border: Border.all(color: isActive || isCompleted ? primaryColor : Colors.grey.shade700, width: 2),
              ),
              child: isCompleted 
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : (isActive ? const Center(child:  SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))) : null),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? primaryColor : Colors.grey.shade800,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive || isCompleted ? (isDarkTheme(context) ? Colors.white : Colors.black) : Colors.grey, 
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: textColorMuted,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ],
    );
  }
  
  bool isDarkTheme(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  Widget _buildResultSummary(bool isDark) {
    bool success = _importResult?['success'] == true;
    String message = _importResult?['message'] ?? 'Unknown status';
    List errors = (_importResult?['data']?['errors'] as List?) ?? [];
    
    int newCount = _importResult?['data']?['newCount'] ?? 0;
    int updatedCount = _importResult?['data']?['updatedCount'] ?? 0;
    int skippedCount = _importResult?['data']?['skippedCount'] ?? 0;
    int totalCount = _importResult?['data']?['importedCount'] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           children: [
             Icon(success ? Icons.check_circle : Icons.error, color: success ? Colors.green : Colors.red, size: 32),
             const SizedBox(width: 12),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(success ? 'Import Complete' : 'Import Failed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                   Text(message, style: TextStyle(color: isDark ? textColorMuted : Colors.grey)),
                 ],
               ),
             ),
           ],
        ),
        if (success) ...[
          const SizedBox(height: 16),
          // Stats Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                 Container(
                   padding: const EdgeInsets.all(12),
                   width: 100,
                   decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                   child: Column(
                     children: [
                       Text(newCount.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                       const Text('New Added', style: TextStyle(fontSize: 10, color: Colors.green)),
                     ],
                   ),
                 ),
                 const SizedBox(width: 8),
                 Container(
                   padding: const EdgeInsets.all(12),
                   width: 100,
                   decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                   child: Column(
                     children: [
                       Text(updatedCount.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                       const Text('Updated', style: TextStyle(fontSize: 10, color: Colors.blue)),
                     ],
                   ),
                 ),
                 const SizedBox(width: 8),
                 Container(
                   padding: const EdgeInsets.all(12),
                   width: 100,
                   decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                   child: Column(
                     children: [
                       Text(skippedCount.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                       const Text('Skipped', style: TextStyle(fontSize: 10, color: Colors.orange)),
                     ],
                   ),
                 ),
                 const SizedBox(width: 8),
                 Container(
                   padding: const EdgeInsets.all(12),
                   width: 100,
                   decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                   child: Column(
                     children: [
                       Text(errors.length.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                       const Text('Failed', style: TextStyle(fontSize: 10, color: Colors.red)),
                     ],
                   ),
                 ),
              ],
            ),
          ),
        ],
        if (errors.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Errors Found:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 8),
                ...errors.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.red)),
                      Expanded(child: Text(e.toString(), style: const TextStyle(color: Colors.red, fontSize: 12))),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _resetImport,
            child: const Text('Start New Import'),
          ),
        )
      ],
    );
  }
}
