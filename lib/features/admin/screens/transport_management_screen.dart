import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/transport_provider.dart';

class TransportManagementScreen extends ConsumerStatefulWidget {
  const TransportManagementScreen({super.key});

  @override
  ConsumerState<TransportManagementScreen> createState() => _TransportManagementScreenState();
}

class _TransportManagementScreenState extends ConsumerState<TransportManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transportProvider.notifier).loadTransports();
    });
  }

  void _showTransportDialog([TransportItem? transport]) {
    final isEditing = transport != null;
    final nameController = TextEditingController(text: transport?.name ?? '');
    final gstController = TextEditingController(text: transport?.gst ?? '');
    final contactController = TextEditingController(text: transport?.contact ?? '');
    bool isActive = transport?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Transport' : 'Add Transport'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Transport Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: gstController,
                    decoration: const InputDecoration(labelText: 'GST (Optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contactController,
                    decoration: const InputDecoration(labelText: 'Contact Details (Optional)'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (val) {
                      setState(() {
                        isActive = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;

                  final success = isEditing
                      ? await ref.read(transportProvider.notifier).updateTransport(
                          id: transport.id,
                          name: nameController.text.trim(),
                          gst: gstController.text.trim(),
                          contact: contactController.text.trim(),
                          isActive: isActive,
                        )
                      : await ref.read(transportProvider.notifier).createTransport(
                          name: nameController.text.trim(),
                          gst: gstController.text.trim(),
                          contact: contactController.text.trim(),
                          isActive: isActive,
                        );

                  if (success && mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(TransportItem transport) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transport'),
        content: Text('Are you sure you want to delete ${transport.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref.read(transportProvider.notifier).deleteTransport(transport.id);
              if (success && mounted) {
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transports Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : ListView.builder(
                  itemCount: state.transports.length,
                  itemBuilder: (context, index) {
                    final transport = state.transports[index];
                    return ListTile(
                      title: Text(transport.name),
                      subtitle: Text('GST: ${transport.gst ?? 'N/A'} | Contact: ${transport.contact ?? 'N/A'}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            color: transport.isActive ? Colors.green : Colors.red,
                            size: 12,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showTransportDialog(transport),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(transport),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTransportDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
