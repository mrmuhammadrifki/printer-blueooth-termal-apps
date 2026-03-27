import 'package:flutter/material.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as esc_pos;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../services/printer_service.dart';
import '../models/printer_category.dart';

class PrintersPage extends StatefulWidget {
  final PrinterService printerService;

  const PrintersPage({super.key, required this.printerService});

  @override
  State<PrintersPage> createState() => _PrintersPageState();
}

class _PrintersPageState extends State<PrintersPage> {
  bool _isScanning = false;
  List<BluetoothDevice> _devices = [];

  Future<void> _scanDevices() async {
    setState(() {
      _isScanning = true;
      _devices = [];
    });

    try {
      final devices = await widget.printerService.scanDevices();
      setState(() {
        _devices = devices;
      });
    } finally {
      setState(() => _isScanning = false);
    }
  }

  void _showAddCategoryDialog() {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    esc_pos.PaperSize selectedSize = esc_pos.PaperSize.mm58;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1F2E),
                  title: const Text('Add Category'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: idController,
                        decoration: const InputDecoration(
                          labelText: 'ID',
                          hintText: 'e.g., bar, kitchen2',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          hintText: 'Display name',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<esc_pos.PaperSize>(
                        value: selectedSize,
                        decoration: const InputDecoration(
                          labelText: 'Paper Size',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: esc_pos.PaperSize.mm58,
                            child: Text('58mm'),
                          ),
                          DropdownMenuItem(
                            value: esc_pos.PaperSize.mm80,
                            child: Text('80mm'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedSize = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (idController.text.isNotEmpty &&
                            nameController.text.isNotEmpty) {
                          await widget.printerService.addCategory(
                            idController.text.trim().toLowerCase(),
                            nameController.text.trim(),
                            paperSize: selectedSize,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            setState(() {});
                          }
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showAssignDialog(PrinterCategory category) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1F2E),
            title: Text('Assign Printer to ${category.name}'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_devices.isEmpty)
                    Column(
                      children: [
                        const Icon(
                          Icons.bluetooth_searching,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No devices found',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _scanDevices();
                            _showAssignDialog(category);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Scan Devices'),
                        ),
                      ],
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return ListTile(
                          leading: const Icon(Icons.print_rounded),
                          title: Text(device.name ?? 'Unknown'),
                          subtitle: Text(device.address ?? ''),
                          onTap: () async {
                            await widget.printerService.assignPrinterToCategory(
                              category.id,
                              device,
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              setState(() {});
                            }
                          },
                        );
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
            ],
          ),
    );
  }

  void _showEditPaperSizeDialog(PrinterCategory category) {
    // Convert enum to int for safer dropdown handling
    int selectedValue = category.paperSize == esc_pos.PaperSize.mm58 ? 58 : 80;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1F2E),
                  title: Text('Edit Paper Size - ${category.name}'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Select the paper width for this printer category:',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<int>(
                        value: selectedValue,
                        dropdownColor: const Color(0xFF1A1F2E),
                        decoration: const InputDecoration(
                          labelText: 'Paper Size',
                          prefixIcon: Icon(Icons.straighten),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 58,
                            child: Text('58mm (Small - Common for receipts)'),
                          ),
                          DropdownMenuItem(
                            value: 80,
                            child: Text('80mm (Large - Full receipts)'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedValue = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          // Convert int back to Enum
                          final newSize =
                              selectedValue == 58
                                  ? esc_pos.PaperSize.mm58
                                  : esc_pos.PaperSize.mm80;

                          await widget.printerService.updateCategoryPaperSize(
                            category.id,
                            newSize,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            // No need to call setState here as the Stream listener in DashboardPage/MainScreen might handle it,
                            // but PrinterPage needs to rebuild too.
                            // However, we are not listening to the stream in PrinterPage yet.
                            // Let's call setState to be sure this specific widget refreshes.
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '✓ Paper size updated to ${selectedValue}mm',
                                ),
                                backgroundColor: const Color(0xFF00FFA3),
                              ),
                            );
                          }
                        } catch (e) {
                          print('Error updating paper size: $e'); // Log error
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.printerService.printerCategories.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Printer Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded),
            onPressed: _showAddCategoryDialog,
            tooltip: 'Add Category',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.printerService.debugMode)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Debug Mode Active. Showing Mock Printers.\nGo to Settings to disable.',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Scan Button
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.bluetooth_searching_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Discover Bluetooth Printers',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan for paired Bluetooth devices',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isScanning ? null : _scanDevices,
                    icon:
                        _isScanning
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.search_rounded),
                    label: Text(_isScanning ? 'Scanning...' : 'Scan Devices'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Categories List
          ...categories.map((category) {
            final canDelete = !['kasir', 'dapur'].contains(category.id);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _showAssignDialog(category),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  category.isAssigned
                                      ? const Color(0xFF00FFA3).withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.print_rounded,
                              color:
                                  category.isAssigned
                                      ? const Color(0xFF00FFA3)
                                      : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  category.isAssigned
                                      ? category.deviceName ?? 'Connected'
                                      : 'Tap to assign printer',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        category.isAssigned
                                            ? const Color(0xFF00FFA3)
                                            : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (canDelete)
                            IconButton(
                              icon: const Icon(Icons.delete_rounded, size: 20),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        backgroundColor: const Color(
                                          0xFF1A1F2E,
                                        ),
                                        title: const Text('Delete Category'),
                                        content: Text(
                                          'Delete "${category.name}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                );

                                if (confirm == true) {
                                  await widget.printerService.removeCategory(
                                    category.id,
                                  );
                                  setState(() {});
                                }
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _InfoChip(
                            label: 'ID: ${category.id}',
                            icon: Icons.tag,
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _showEditPaperSizeDialog(category),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D9FF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(
                                    0xFF00D9FF,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.straighten,
                                    size: 12,
                                    color: Color(0xFF00D9FF),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    category.paperSize == esc_pos.PaperSize.mm58
                                        ? '58mm'
                                        : '80mm',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF00D9FF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.edit,
                                    size: 10,
                                    color: Color(0xFF00D9FF),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (category.isAssigned &&
                              category.macAddress != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: _InfoChip(
                                label: category.macAddress!,
                                icon: Icons.bluetooth,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (category.isAssigned) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              await widget.printerService
                                  .removePrinterFromCategory(category.id);
                              setState(() {});
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✓ Printer unassigned'),
                                    backgroundColor: Color(0xFF00FFA3),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('❌ Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.link_off, size: 16),
                          label: const Text('Unassign Printer'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
