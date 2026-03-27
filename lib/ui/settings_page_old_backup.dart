import 'package:flutter/material.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as esc_pos;
import '../services/printer_service.dart';
import '../models/printer_category.dart';

class SettingsPage extends StatefulWidget {
  final PrinterService printerService;

  const SettingsPage({super.key, required this.printerService});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _businessNameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _serverIdController;

  @override
  void initState() {
    super.initState();
    final settings = widget.printerService.businessSettings;
    _businessNameController = TextEditingController(
      text: settings.businessName,
    );
    _addressController = TextEditingController(text: settings.address);
    _phoneController = TextEditingController(text: settings.phoneNumber);
    _serverIdController = TextEditingController(text: settings.serverId);
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _serverIdController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    final settings = widget.printerService.businessSettings;
    settings.businessName = _businessNameController.text;
    settings.address = _addressController.text;
    settings.phoneNumber = _phoneController.text;
    settings.serverId = _serverIdController.text;

    await widget.printerService.saveBusinessSettings();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✓ Settings saved')));
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
                  title: const Text('Add Printer Category'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: idController,
                        decoration: const InputDecoration(
                          labelText: 'ID (e.g., bar, kitchen2)',
                          hintText: 'Unique identifier',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          hintText: 'Display name',
                        ),
                      ),
                      const SizedBox(height: 12),
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

  @override
  Widget build(BuildContext context) {
    final settings = widget.printerService.businessSettings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Business Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              labelText: 'Business Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _serverIdController,
            decoration: const InputDecoration(
              labelText: 'Default Server/Cashier Name',
              border: OutlineInputBorder(),
            ),
          ),
          const Divider(height: 32),
          const Text(
            'Receipt Display Options',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          CheckboxListTile(
            title: const Text('Show Business Name'),
            value: settings.showBusinessName,
            onChanged: (value) {
              setState(() {
                settings.showBusinessName = value ?? true;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Show Address'),
            value: settings.showAddress,
            onChanged: (value) {
              setState(() {
                settings.showAddress = value ?? true;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Show Phone Number'),
            value: settings.showPhoneNumber,
            onChanged: (value) {
              setState(() {
                settings.showPhoneNumber = value ?? true;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Show Date & Time'),
            value: settings.showDateTime,
            onChanged: (value) {
              setState(() {
                settings.showDateTime = value ?? true;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Show Server/Cashier Name'),
            value: settings.showServerId,
            onChanged: (value) {
              setState(() {
                settings.showServerId = value ?? true;
              });
            },
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Printer Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: _showAddCategoryDialog,
                tooltip: 'Add Category',
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.printerService.printerCategories.categories.map((category) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(category.name),
                subtitle: Text(
                  'ID: ${category.id} | Paper: ${category.paperSize == esc_pos.PaperSize.mm58 ? "58mm" : "80mm"}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        _showEditCategoryDialog(category);
                      },
                    ),
                    if (!['kasir', 'dapur'].contains(category.id))
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: Text(
                                    'Delete category "${category.name}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
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
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(PrinterCategory category) {
    esc_pos.PaperSize selectedSize = category.paperSize;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text('Edit ${category.name}'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('ID: ${category.id}'),
                      const SizedBox(height: 12),
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
                        await widget.printerService.updateCategoryPaperSize(
                          category.id,
                          selectedSize,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          setState(() {});
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }
}
