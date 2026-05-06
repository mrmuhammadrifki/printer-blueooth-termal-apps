import 'dart:async';
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
  late final Stream<void> _settingsStream;

  @override
  void initState() {
    super.initState();
    _settingsStream = widget.printerService.categoriesChangedStream;
    _settingsStream.listen((_) {
      if (mounted) {
        setState(() {}); // Refresh UI when settings change
      }
    });
  }

  // New method: Scan and immediately show dialog with results
  Future<void> _scanAndShowDialog(PrinterCategory category) async {
    // Show dialog immediately with loading state
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ScanDialogContent(
        category: category,
        printerService: widget.printerService,
        onAssigned: () {
          setState(() {}); // Refresh main page
        },
      ),
    );
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
    // Use new scan and show dialog method
    _scanAndShowDialog(category);
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
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Select paper width:',
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
                              child: Text('58mm (Small)'),
                            ),
                            DropdownMenuItem(
                              value: 80,
                              child: Text('80mm (Large)'),
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

// Scan Dialog Content - Stateful widget for real-time scan updates
class _ScanDialogContent extends StatefulWidget {
  final PrinterCategory category;
  final PrinterService printerService;
  final VoidCallback onAssigned;

  const _ScanDialogContent({
    required this.category,
    required this.printerService,
    required this.onAssigned,
  });

  @override
  State<_ScanDialogContent> createState() => _ScanDialogContentState();
}

class _ScanDialogContentState extends State<_ScanDialogContent> {
  bool _isScanning = true;
  List<BluetoothDevice> _devices = [];
  String? _errorMessage;
  StreamSubscription<void>? _settingsSubscription;

  @override
  void initState() {
    super.initState();
    _performScan();
    
    // Listen to settings changes for real-time updates (e.g., debug mode toggle)
    _settingsSubscription = widget.printerService.categoriesChangedStream.listen((_) {
      if (mounted) {
        setState(() {}); // Refresh UI when settings change
      }
    });
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _performScan() async {
    setState(() {
      _isScanning = true;
      _devices = [];
      _errorMessage = null;
    });

    try {
      final devices = await widget.printerService.scanDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1F2E),
      title: Text('Assign Printer to ${widget.category.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isScanning
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(strokeWidth: 4),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.printerService.debugMode
                        ? 'Loading mock devices...'
                        : 'Scanning for Bluetooth devices...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.printerService.debugMode
                        ? 'Debug mode active'
                        : 'Please wait (max 15 seconds)',
                    style: TextStyle(
                      color: widget.printerService.debugMode
                          ? Colors.orange[300]
                          : Colors.grey[400],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : _errorMessage != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scan Error',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _performScan,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  )
                : _devices.isEmpty
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.printerService.debugMode
                                ? Icons.bug_report
                                : Icons.bluetooth_disabled,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.printerService.debugMode
                                ? 'Debug Mode Active'
                                : 'No Devices Found',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.printerService.debugMode
                                ? 'No mock printers available. This should not happen in debug mode.'
                                : 'No paired Bluetooth devices found.\\nPair your printer in system Bluetooth settings first.',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _performScan,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Scan Again'),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.printerService.debugMode)
                            Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.bug_report,
                                      size: 16, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Debug Mode: Mock Printers',
                                      style: TextStyle(
                                        color: Colors.orange[300],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: _devices.length,
                            itemBuilder: (context, index) {
                              final device = _devices[index];
                              final isMock = widget.printerService.debugMode;
                              return ListTile(
                                leading: Icon(
                                  isMock
                                      ? Icons.bug_report
                                      : Icons.print_rounded,
                                  color: isMock ? Colors.orange : null,
                                ),
                                title: Text(device.name ?? 'Unknown'),
                                subtitle: Text(device.address ?? ''),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                onTap: () async {
                                  try {
                                    await widget.printerService
                                        .assignPrinterToCategory(
                                      widget.category.id,
                                      device,
                                    );
                                    if (mounted) {
                                      widget.onAssigned();
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '\u2713 ${device.name} assigned to ${widget.category.name}',
                                          ),
                                          backgroundColor:
                                              const Color(0xFF00FFA3),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('\u274c Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
      ),
      actions: _isScanning
          ? null
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              if (_devices.isNotEmpty || _errorMessage != null)
                TextButton.icon(
                  onPressed: _performScan,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Rescan'),
                ),
            ],
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
