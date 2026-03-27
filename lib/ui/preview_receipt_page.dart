import 'package:flutter/material.dart';
import '../models/receipt_custom_data.dart';
import '../services/printer_service.dart';
import 'receipt_layout.dart';

class PreviewReceiptPage extends StatelessWidget {
  final PrinterService printerService;

  const PreviewReceiptPage({super.key, required this.printerService});

  @override
  Widget build(BuildContext context) {
    // Real Settings from PrinterService
    final settings = printerService.businessSettings;

    // Dummy Data for Preview
    final data = ReceiptCustomData(
      tanggal: "29/12/2025, 17.55.39",
      idTransaksi: "TRANS-SAMPLE-001",
      meja: "Table A1",
      kasir: "Super Admin",
      customer: "John Doe",
      member: "Gold Member",
      noHpMember: "081234567890",
      sisaPoin: "50",
      biayaMeja: BilliardData(
        paket: "Paket 1 Jam",
        mulai: "17.00.00",
        selesai: "18.00.00",
        durasi: "01:00:00",
        biaya: 30000,
      ),
      items: [
        ReceiptItem(name: "Kopi Hitam", qty: 2, total: 20000),
        ReceiptItem(name: "Pisang Goreng", qty: 1, total: 15000),
      ],
      subtotal: 65000,
      diskon: 5000,
      diskonPersen: 10,
      total: 60000,
      metodeBayar: "QRIS",
      barcodeData: "TRANS-SAMPLE-001",
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Preview Layout Struk')),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              const Text(
                "Ini adalah tampilan visual struk yang akan digenerate sebagai gambar.\nInformasi Header diambil dari Settings aplikasi.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              // Simulation of 58mm Paper (approx 380px visual width)
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ReceiptLayout(
                  data: data,
                  settings: settings,
                  width: 380,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
