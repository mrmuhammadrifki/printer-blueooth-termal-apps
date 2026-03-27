# Panduan Integrasi Frontend - OrbitPrint

Dokumen ini menjelaskan cara menggunakan API lokal OrbitPrint untuk mencetak Struk Kasir (Visual/QR) dan Order Dapur (Teks).

## 1. Konfigurasi Server

*   **Base URL:** `http://127.0.0.1:18181` (Localhost)
*   **Port:** `18181`
*   **CORS:** Server mendukung Cross-Origin (`Access-Control-Allow-Origin: *`), dapat dipanggil langsung dari Browser/Web App.

---

## 2. Cetak Struk Kasir (Layout Visual)

Gunakan endpoint ini untuk mencetak struk pembayaran dengan layout lengkap (Logo, Tabel Biliar, QR Code, Footer).

### Endpoint
`POST /print-custom-receipt`

### Header
`Content-Type: application/json`

### Body Parameters
| Field | Tipe | Deskripsi |
| :--- | :--- | :--- |
| `id_transaksi` | String | **(Wajib)** ID Transaksi unik. |
| `tanggal` | String | Tanggal transaksi (String bebas, disarankan format jelas). |
| `meja` | String | Nama meja/area. |
| `kasir` | String | Nama kasir. |
| `customer` | String | Nama pelanggan. |
| `member` | String | Tipe member (e.g. "Gold"). |
| `no_hp` | String | No HP Member. |
| `sisa_poin` | String | Info sisa poin. |
| `subtotal` | Number | Total harga kotor. |
| `diskon` | Number | Nominal diskon (Rupiah). |
| `diskon_persen`| Number | Persentase diskon (e.g. `10` untuk 10%). Label akan menjadi "Diskon(10%)". |
| `total` | Number | Total bayar akhir. |
| `metode_bayar`| String | e.g. "QRIS", "TUNAI". |
| `items` | Array | List produk (lihat contoh). |
| `biaya_meja` | Object | Detail rental biliar (lihat contoh). |
| `barcode` | String | (Opsional) Data string untuk QR Code. Jika kosong, menggunakan `id_transaksi`. |

### Contoh JSON Struk Kasir
```json
{
  "tanggal": "04/02/2026, 12.30",
  "id_transaksi": "TRX-POS-001",
  "meja": "Meja 01",
  "kasir": "Admin",
  "customer": "Budi",
  "items": [
    { "name": "Es Teh Manis", "qty": 2, "total": 10000 },
    { "name": "Nasi Goreng", "qty": 1, "total": 25000 }
  ],
  "biaya_meja": {
    "paket": "Regular 1 Jam",
    "durasi": "01:00:00",
    "biaya": 30000
  },
  "subtotal": 65000,
  "diskon": 6500,
  "diskon_persen": 10,
  "total": 58500,
  "metode_bayar": "QRIS"
}
```

---

## 3. Cetak Order Dapur (Teks Ringkas)

Gunakan endpoint ini untuk mencetak daftar pesanan ke printer dapur/bar. Format lebih sederhana dan fokus pada item & catatan.

### Endpoint
`POST /print-kitchen-order`

### Header
`Content-Type: application/json`

### Body Parameters
| Field | Tipe | Deskripsi |
| :--- | :--- | :--- |
| `orderId` | String | **(Wajib)** Nomor Order/Antrian. |
| `tableName` | String | Nomor/Nama Meja (Bisa juga pakai `tableNumber` atau `tableId`). |
| `customerName` | String | Nama pemesan. |
| `timestamp` | String | Waktu order (ISO format disarankan, e.g. `2026-02-04T12:00:00`). |
| `items` | Array | Daftar item dapur. |

#### Struktur Item Dapur
```json
{
  "name": "Nama Menu",
  "quantity": 1,
  "notes": "Pedas, Jangan pakai bawang"  // Opsional
}
```

### Contoh JSON Order Dapur
```json
{
  "orderId": "ORD-123",
  "tableName": "Meja 12",
  "customerName": "Pak Bambang",
  "timestamp": "2026-02-04T12:00:00",
  "items": [
    {
      "name": "Nasi Goreng Gila",
      "quantity": 2,
      "notes": "Pedas mampus, telur setengah matang"
    },
    {
      "name": "Jus Alpukat",
      "quantity": 1,
      "notes": "Gula sedikit"
    }
  ]
}
```

---

## 4. Setup Printer di Aplikasi
Agar pencetakan berhasil berjalan, pastikan hal berikut di Aplikasi OrbitPrint Android:

1.  Masuk menu **Printer Management**.
2.  Pastikan sudah ada 2 Kategori:
    *   **Kasir** (Untuk endpoint `/print-custom-receipt`)
    *   **Dapur** (Untuk endpoint `/print-kitchen-order`)
3.  Klik pada kategori tersebut dan tetapkan (Assign) Printer Bluetooth yang sesuai.
4.  Pastikan **Server** (di Dashboard) dalam posisi **ON**.
