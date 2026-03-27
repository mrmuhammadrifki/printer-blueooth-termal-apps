import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/business_settings.dart';
import '../models/receipt_custom_data.dart';

class ReceiptLayout extends StatelessWidget {
  final ReceiptCustomData data;
  final BusinessSettings settings;
  final double width;

  const ReceiptLayout({
    Key? key,
    required this.data,
    required this.settings,
    this.width = 380, // Default for 58mm printer approx
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      width: width,
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Wrap content height
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- HEADER SECTION ---
          if (settings.showBusinessName)
            Text(
              settings.businessName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
          const SizedBox(height: 8),
          if (settings.showAddress)
            Text(
              settings.address,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          if (settings.showPhoneNumber)
            Text(
              settings.phoneNumber,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          const SizedBox(height: 12),

          // --- TRANSACTION INFO ---
          if (data.tanggal != null)
            Text(
              'Tanggal: ${data.tanggal}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          Text(
            'ID Transaksi: ${data.idTransaksi}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black),
          ),
          const SizedBox(height: 12),

          // --- MEJA ---
          if (data.meja != null)
            Text(
              'Meja: ${data.meja}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          const SizedBox(height: 8),

          // --- DETAILS (Kasir, Customer, etc) ---
          if (data.kasir != null) _buildKeyValue('Kasir:', data.kasir!),
          if (data.server != null) _buildKeyValue('Server:', data.server!),
          if (data.customer != null)
            _buildKeyValue('Customer:', data.customer!),
          if (data.member != null) _buildKeyValue('Member:', data.member!),
          if (data.noHpMember != null)
            _buildKeyValue('No. HP Member:', data.noHpMember!),
          if (data.sisaPoin != null)
            _buildKeyValue('Sisa Poin:', data.sisaPoin!),

          const SizedBox(height: 12),
          _buildDivider(),
          const SizedBox(height: 12),

          // --- BILLIARD SECTION ---
          if (data.biayaMeja != null) ...[
            const Text(
              'Biaya Meja Biliar:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            if (data.biayaMeja!.paket != null)
              _buildKeyValue('Paket:', data.biayaMeja!.paket!),
            if (data.biayaMeja!.mulai != null)
              _buildKeyValue(
                'Waktu Mulai:',
                data.biayaMeja!.mulai!,
                alignRight: true,
              ),
            if (data.biayaMeja!.selesai != null)
              _buildKeyValue(
                'Waktu Selesai:',
                data.biayaMeja!.selesai!,
                alignRight: true,
              ),
            if (data.biayaMeja!.durasi != null)
              _buildKeyValue(
                'Waktu Main:',
                data.biayaMeja!.durasi!,
                alignRight: true,
              ),
            if (data.biayaMeja!.biaya != null)
              _buildKeyValue(
                'Biaya Meja:',
                currencyFormat.format(data.biayaMeja!.biaya),
                alignRight: true,
              ),
            const SizedBox(height: 12),
            _buildDivider(),
            const SizedBox(height: 12),
          ],

          // --- FOOD & DRINK SECTION ---
          if (data.items != null && data.items!.isNotEmpty) ...[
            const Text(
              'Makanan & Minuman:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            ...data.items!.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        '${item.name} (x${item.qty})',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        currencyFormat.format(item.total),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 12),
            _buildDivider(),
            const SizedBox(height: 12),
          ],

          // --- TOTALS ---
          if (data.subtotal != null)
            _buildSummaryRow(
              'Subtotal:',
              currencyFormat.format(data.subtotal),
              isBold: false,
            ),

          if (data.diskon != null && data.diskon! > 0)
            _buildSummaryRow(
              data.diskonPersen != null
                  ? 'Diskon(${data.diskonPersen}%):'
                  : 'Diskon:',
              '- ${currencyFormat.format(data.diskon)}',
              isBold: false,
            ),

          if (data.total != null) ...[
            const SizedBox(height: 4),
            _buildSummaryRow(
              'TOTAL:',
              currencyFormat.format(data.total),
              isBold: true,
              fontSize: 18,
            ),
          ],

          if (data.metodeBayar != null) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Metode Bayar:', data.metodeBayar!, isBold: false),
          ],

          const SizedBox(height: 12),
          _buildDivider(),

          // --- QR CODE ---
          if (data.barcodeData != null && data.barcodeData!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Scan untuk detail atau pembayaran digital:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Center(
              child: QrImageView(
                data: data.barcodeData!,
                version: QrVersions.auto,
                size: 150.0,
                backgroundColor: Colors.white,
              ),
            ),
          ],

          const SizedBox(height: 16),
          _buildDivider(),
          const SizedBox(height: 8),
          const Text(
            'Terima kasih Atas Kunjungan Anda! Sampai Jumpa Kembali',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValue(String key, String value, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              key,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: alignRight ? TextAlign.right : TextAlign.left,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String key,
    String value, {
    bool isBold = false,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey[700]),
              ),
            );
          }),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
        );
      },
    );
  }
}
