# 🧪 Panduan Testing OrbitPrint (Tanpa Printer Fisik)

## 🎯 Overview

Anda **TIDAK perlu printer fisik** untuk testing! OrbitPrint punya **Debug Mode** yang bisa simulate printing.

---

## 📱 Step 1: Setup Debug Mode di App

### 1. Install & Run App
```bash
# Install dependencies
flutter pub get

# Run di Android device/emulator
flutter run
```

### 2. Aktifkan Debug Mode
1. Buka aplikasi **OrbitPrint**
2. Klik tab **Settings** (icon ⚙️ paling kanan)
3. Scroll ke bawah
4. Toggle **"Debug Mode"** menjadi **ON** (hijau)

✅ **Debug Mode Aktif!** Sekarang Anda bisa testing tanpa printer fisik.

---

## 📡 Step 2: Assign Mock Printer

1. Klik tab **Printers** (icon 🖨️ di tengah)
2. Pilih kategori printer (misal: "Kasir")
3. Klik tombol **"Scan Devices"**
4. Pilih salah satu **Mock Printer** (Mock Printer 1/2/3)
5. Klik **"Assign"**

✅ Mock printer berhasil di-assign!

Ulangi untuk kategori lain (misal: "Dapur") jika perlu.

---

## 🌐 Step 3: Test dari Browser/Web

### **Option A: Test Page Lengkap (Recommended)**

1. **Copy file `test_complete.html` ke Android device**
   - Via USB: Copy dari folder project ke Downloads/Internal Storage
   - Via Email/Drive: Send file ke diri sendiri, download di Android

2. **Buka dengan Browser**
   - Buka file manager di Android
   - Klik file `test_complete.html`
   - Pilih Chrome/Firefox untuk membuka

3. **Test Print!**
   - Isi form dengan content yang mau dicetak
   - Atau klik **"Quick Fill"** untuk sample data
   - Klik **"Preview"** untuk lihat format
   - Klik **"Print"** untuk test!

4. **Cek Hasil**
   - Buka OrbitPrint app
   - Tab **Dashboard**
   - Scroll ke **"Debug Print Logs"**
   - Lihat content yang berhasil di-print ✅

---

### **Option B: Test Page Simple (Lebih Cepat)**

Jika tidak mau copy file, buka langsung dari server:

1. **Di browser Android, buka:**
   ```
   http://127.0.0.1:18181/test
   ```
   
2. Klik link **"Simple Test Page"** atau **"Multi-Printer Test"**

3. Test print langsung dari halaman tersebut

---

### **Option C: Test dengan cURL (Advanced)**

Jika familiar dengan terminal/command line di Android (pakai Termux):

```bash
curl -X POST http://127.0.0.1:18181/print-category \
  -H "Content-Type: application/json" \
  -d '{
    "categoryId": "kasir",
    "serverName": "Rifki Test",
    "text": "Hello World!\nBaris 2\nBaris 3"
  }'
```

**Response Success:**
```json
{
  "status": "ok",
  "message": "Printed to kasir"
}
```

---

## 📊 Step 4: Monitor & Verify

### Di OrbitPrint App:

**Tab Dashboard:**
- **Server Status**: Harus "Server Running" (hijau)
- **Debug Print Logs**: Semua print request & content-nya
- **Statistics**: Total print, success rate

**Tab Printers:**
- Check status printer yang sudah di-assign
- MAC address mock printer akan berformat: `AA:BB:CC:DD:EE:0X`

---

## 🎨 Sample Test Data

### 1. **Receipt Sample** (Kasir)
```
Category: kasir
Server Name: Rifki
Content:
Customer: John Doe
---------------------------------------
Meja: 5
ID Transaksi: 12345

Kopi Aren (x1)             Rp 19.000
Nasi Goreng (x2)           Rp 50.000

Subtotal:                 Rp 69.000
TOTAL:                    Rp 69.000
Metode Bayar:             CASH
```

### 2. **Kitchen Order Sample** (Dapur)
```
Category: dapur
Server Name: Kitchen
Content:
=== ORDER DAPUR ===
Meja: 12
Waktu: 14:30

2x Nasi Goreng Special
   Catatan: Pedas sedang
1x Mie Goreng
```

### 3. **Simple Test**
```
Category: kasir
Server Name: Test
Content:
Test Print
Line 2
Line 3
```

---

## ✅ Checklist Testing

- [ ] Debug Mode aktif di Settings
- [ ] Mock printer sudah di-assign untuk kategori "Kasir"
- [ ] Mock printer sudah di-assign untuk kategori "Dapur"
- [ ] Server running (check di Dashboard)
- [ ] Test print ke kategori "Kasir" → Success
- [ ] Test print ke kategori "Dapur" → Success
- [ ] Preview struk terlihat rapi (32 chars untuk 58mm)
- [ ] Debug logs menampilkan content yang benar
- [ ] Test dengan serverName → muncul di struk
- [ ] Test tanpa serverName → pakai default "Server Rudi"

---

## 🐛 Troubleshooting

### "Server tidak dapat dijangkau"
- ✅ Pastikan OrbitPrint app sedang running
- ✅ Check tab Dashboard, status harus "Server Running"
- ✅ Test page dibuka di **device yang sama** dengan app (bukan di laptop/PC lain)
- ✅ Gunakan `127.0.0.1` bukan `localhost` atau IP lain

### "No printer assigned"
- ✅ Aktifkan Debug Mode dulu
- ✅ Scan devices & assign mock printer
- ✅ Refresh page dan coba lagi

### "Print gagal"
- ✅ Check kategori ID (kasir/dapur) sudah benar
- ✅ Content tidak boleh kosong
- ✅ Restart app jika perlu

### Debug logs tidak muncul
- ✅ Debug Mode harus ON
- ✅ Scroll ke bawah di Dashboard page
- ✅ Section "Debug Print Logs" hanya muncul saat debug mode aktif

---

## 🚀 Ready untuk Production?

Setelah testing selesai dengan debug mode:

1. **Matikan Debug Mode** di Settings
2. **Assign printer fisik** di tab Printers:
   - Pastikan printer sudah paired di Bluetooth system
   - Scan devices → pilih printer thermal Anda
   - Assign ke kategori yang sesuai
3. **Test print** dengan printer asli
4. **Deploy APK** untuk production use

---

## 📝 API Reference

### POST /print-category (Recommended)
```json
{
  "categoryId": "kasir",        // Required: kasir, dapur, dll
  "serverName": "Rifki",        // Optional: nama kasir/server
  "text": "Content here..."     // Required: isi struk
}
```

### POST /print (Legacy)
```json
{
  "text": "Content here..."     // Default ke kategori "kasir"
}
```

### GET /
Health check & server info

### GET /test
Informasi test suite & instruksi

---

## 🎉 Selamat Testing!

Jika ada pertanyaan atau issue, check:
- [FRONTEND_INTEGRATION_GUIDE.md](FRONTEND_INTEGRATION_GUIDE.md) - Panduan integrasi
- [TROUBLESHOOTING_BLUEPRINT.md](TROUBLESHOOTING_BLUEPRINT.md) - Troubleshooting
- [UPDATE_LOG.md](UPDATE_LOG.md) - Change log

Happy testing! 🖨️✨
