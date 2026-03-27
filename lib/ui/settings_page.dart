import 'package:flutter/material.dart';
import '../services/printer_service.dart';

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

  @override
  void initState() {
    super.initState();
    final settings = widget.printerService.businessSettings;
    _businessNameController = TextEditingController(
      text: settings.businessName,
    );
    _addressController = TextEditingController(text: settings.address);
    _phoneController = TextEditingController(text: settings.phoneNumber);
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    final settings = widget.printerService.businessSettings;
    settings.businessName = _businessNameController.text;
    settings.address = _addressController.text;
    settings.phoneNumber = _phoneController.text;

    await widget.printerService.saveBusinessSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF00FFA3)),
              SizedBox(width: 12),
              Text('Settings saved successfully'),
            ],
          ),
          backgroundColor: const Color(0xFF1A1F2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.printerService.businessSettings;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Business Info Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.business_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Business Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(
                      labelText: 'Business Name',
                      prefixIcon: Icon(Icons.store_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on_rounded),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Receipt Display Options
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FFA3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Color(0xFF00FFA3),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Receipt Display',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SettingSwitch(
                    title: 'Show Business Name',
                    subtitle: 'Display business name on receipt',
                    value: settings.showBusinessName,
                    onChanged: (value) {
                      setState(() {
                        settings.showBusinessName = value;
                      });
                    },
                  ),
                  _SettingSwitch(
                    title: 'Show Address',
                    subtitle: 'Display address on receipt',
                    value: settings.showAddress,
                    onChanged: (value) {
                      setState(() {
                        settings.showAddress = value;
                      });
                    },
                  ),
                  _SettingSwitch(
                    title: 'Show Phone Number',
                    subtitle: 'Display phone number on receipt',
                    value: settings.showPhoneNumber,
                    onChanged: (value) {
                      setState(() {
                        settings.showPhoneNumber = value;
                      });
                    },
                  ),
                  _SettingSwitch(
                    title: 'Show Date & Time',
                    subtitle: 'Display transaction date and time',
                    value: settings.showDateTime,
                    onChanged: (value) {
                      setState(() {
                        settings.showDateTime = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Developer Options
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.bug_report_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Developer Options',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      title: const Text('Debug Mode'),
                      subtitle: const Text(
                        'Test printing without physical printer',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      value: widget.printerService.debugMode,
                      onChanged: (value) {
                        setState(() {
                          widget.printerService.debugMode = value;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  value ? Icons.bug_report : Icons.check_circle,
                                  color:
                                      value
                                          ? Colors.orange
                                          : const Color(0xFF00FFA3),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  value
                                      ? 'Debug mode enabled'
                                      : 'Debug mode disabled',
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF1A1F2E),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      activeColor: Colors.orange,
                      secondary: Icon(
                        Icons.bug_report_rounded,
                        color:
                            widget.printerService.debugMode
                                ? Colors.orange
                                : Colors.grey,
                      ),
                    ),
                  ),
                  if (widget.printerService.debugMode) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Prints will be simulated. Check Dashboard logs for output.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[300],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // App Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.print_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'OrbitPrint',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bluetooth Thermal Printer Gateway',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF00FFA3),
      ),
    );
  }
}
