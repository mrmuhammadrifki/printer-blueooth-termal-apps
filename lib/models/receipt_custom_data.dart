class ReceiptCustomData {
  final String? tanggal;
  final String idTransaksi;
  final String? meja;
  final String? kasir;
  final String? server;
  final String? customer;
  final String? member;
  final String? noHpMember;
  final String? sisaPoin;
  final BilliardData? biayaMeja;
  final List<ReceiptItem>? items; // Food & Drink
  final int? subtotal;
  final int? total;
  final int? diskon;
  final num? diskonPersen; // e.g. 10 or 10.5
  final String? metodeBayar;
  final String? barcodeData; // Assuming from ID Trx if null

  ReceiptCustomData({
    this.tanggal,
    required this.idTransaksi,
    this.meja,
    this.kasir,
    this.server,
    this.customer,
    this.member,
    this.noHpMember,
    this.sisaPoin,
    this.biayaMeja,
    this.items,
    this.subtotal,
    this.total,
    this.diskon,
    this.diskonPersen,
    this.metodeBayar,
    this.barcodeData,
  });

  factory ReceiptCustomData.fromJson(Map<String, dynamic> json) {
    return ReceiptCustomData(
      tanggal: json['tanggal'],
      idTransaksi: json['id_transaksi'] ?? json['idTransaksi'] ?? '-',
      meja: json['meja'],
      kasir: json['kasir'],
      server: json['server'],
      customer: json['customer'],
      member: json['member'],
      noHpMember: json['no_hp'] ?? json['noHpMember'],
      sisaPoin: json['sisa_poin']?.toString() ?? json['sisaPoin']?.toString(),
      biayaMeja:
          json['biaya_meja'] != null
              ? BilliardData.fromJson(json['biaya_meja'])
              : (json['biayaMeja'] != null
                  ? BilliardData.fromJson(json['biayaMeja'])
                  : null),
      items:
          (json['items'] as List?)
              ?.map((e) => ReceiptItem.fromJson(e))
              .toList(),
      subtotal: json['subtotal'],
      total: json['total'],
      diskon: json['diskon'],
      diskonPersen: json['diskon_persen'] ?? json['diskonPersen'],
      metodeBayar: json['metode_bayar'] ?? json['metodeBayar'],
      barcodeData:
          json['barcode'] ?? json['id_transaksi'] ?? json['idTransaksi'],
    );
  }
}

class BilliardData {
  final String? paket;
  final String? mulai; // HH:mm:ss usually
  final String? selesai;
  final String? durasi;
  final int? biaya;

  BilliardData({this.paket, this.mulai, this.selesai, this.durasi, this.biaya});

  factory BilliardData.fromJson(Map<String, dynamic> json) {
    return BilliardData(
      paket: json['paket'],
      mulai: json['mulai'] ?? json['waktu_mulai'],
      selesai: json['selesai'] ?? json['waktu_selesai'],
      durasi: json['durasi'] ?? json['waktu_main'],
      biaya: json['biaya'] ?? json['biaya_meja'],
    );
  }
}

class ReceiptItem {
  final String name;
  final int qty;
  final int total; // Price * Qty usually calls 'total' in previous structures

  ReceiptItem({required this.name, required this.qty, required this.total});

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'] ?? '',
      qty: json['qty'] ?? 1,
      total: json['total'] ?? json['price'] ?? 0,
    );
  }
}
