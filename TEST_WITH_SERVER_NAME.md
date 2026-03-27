# 🧪 Test API dengan Server Name

## Quick Test via Browser

Buka browser dan akses:
```
http://127.0.0.1:18181/test_multi_printer.html
```

Test page sudah include serverName di request body:
- **Test Dapur** → Server: Rudi
- **Test Kasir** → Server: Rifki

---

## Test via CURL

### Test 1: Print ke Kasir dengan Server Name
```bash
curl -X POST http://127.0.0.1:18181/print-category \
  -H "Content-Type: application/json" \
  -d "{\"categoryId\":\"kasir\",\"serverName\":\"Rifki\",\"text\":\"Customer: Budi\\n---------------------------------------\\nMeja: 5\\n\\nNasi Goreng (x1)    Rp 25.000\\nEs Teh (x2)         Rp 10.000\\n\\nTOTAL:              Rp 35.000\"}"
```

Expected Output di Printer:
```
Jogja Billiard Bogor
Jl. Example No. 123, Bogor
0251-1234567
---------------------------------------
Tanggal: 12/12/2025, 14.37.00
Server: Rifki
---------------------------------------
Customer: Budi
---------------------------------------
Meja: 5

Nasi Goreng (x1)    Rp 25.000
Es Teh (x2)         Rp 10.000

TOTAL:              Rp 35.000
---------------------------------------
Terima kasih Atas Kunjungan Anda! Sampai Jumpa
kembali
```

### Test 2: Print ke Dapur dengan Server Name
```bash
curl -X POST http://127.0.0.1:18181/print-category \
  -H "Content-Type: application/json" \
  -d "{\"categoryId\":\"dapur\",\"serverName\":\"Rudi\",\"text\":\"KITCHEN ORDER\\n===============\\nMeja: 5\\n\\nNasi Goreng (x1)\\nEs Teh (x2)\\n\\nCATATAN: Pedas sedang\"}"
```

### Test 3: Print tanpa Server Name (Optional)
```bash
curl -X POST http://127.0.0.1:18181/print-category \
  -H "Content-Type: application/json" \
  -d "{\"categoryId\":\"kasir\",\"text\":\"Test Receipt\\nTotal: Rp 10.000\"}"
```

Output: Business header tetap muncul, tapi "Server:" tidak ditampilkan

---

## Test via JavaScript/Frontend

### Example 1: Simple Print dengan Server Name
```javascript
async function printReceipt(serverName, customerName, items, total) {
  const text = [
    `Customer: ${customerName}`,
    '---------------------------------------',
    'Meja: 5',
    '',
    ...items.map(item => `${item.name} (x${item.qty})    Rp ${item.price.toLocaleString()}`),
    '',
    `TOTAL:              Rp ${total.toLocaleString()}`
  ].join('\\n');

  const response = await fetch('http://127.0.0.1:18181/print-category', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      categoryId: 'kasir',
      serverName: serverName,  // ← Server name dari frontend
      text: text
    })
  });

  return await response.json();
}

// Usage
await printReceipt('Rifki', 'Budi', [
  { name: 'Nasi Goreng', qty: 1, price: 25000 },
  { name: 'Es Teh', qty: 2, price: 5000 }
], 35000);
```

### Example 2: Print Kitchen Order
```javascript
async function printKitchenOrder(serverName, tableNumber, items, notes = '') {
  const text = [
    'KITCHEN ORDER',
    '===============',
    `Meja: ${tableNumber}`,
    '',
    ...items.map(item => `${item.name} (x${item.qty})`),
    '',
    notes ? `CATATAN: ${notes}` : ''
  ].filter(Boolean).join('\\n');

  const response = await fetch('http://127.0.0.1:18181/print-category', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      categoryId: 'dapur',
      serverName: serverName,  // ← Server name dari frontend
      text: text
    })
  });

  return await response.json();
}

// Usage
await printKitchenOrder('Rudi', '5', [
  { name: 'Nasi Goreng', qty: 1 },
  { name: 'Es Teh', qty: 2 }
], 'Pedas sedang');
```

---

## Format Request Body

### Minimal (tanpa server name)
```json
{
  "categoryId": "kasir",
  "text": "Test Receipt\\nTotal: Rp 10.000"
}
```

### Lengkap (dengan server name)
```json
{
  "categoryId": "kasir",
  "serverName": "Rifki",
  "text": "Customer: Budi\\n---------------------------------------\\nMeja: 5\\n\\nNasi Goreng (x1)    Rp 25.000\\n\\nTOTAL:              Rp 25.000"
}
```

---

## Response Format

### Success
```json
{
  "status": "ok",
  "message": "Printed to Kasir"
}
```

### Error: Category Not Found
```json
{
  "status": "error",
  "message": "Category not found: invalid"
}
```

### Error: Printer Not Assigned
```json
{
  "status": "error",
  "message": "No printer assigned to Kasir"
}
```

---

## Integration dengan Frontend Existing

Jika sudah punya sistem kasir, tinggal tambahkan field `serverName` di request:

### Before (tanpa server name)
```javascript
fetch('http://127.0.0.1:18181/print-category', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    categoryId: 'kasir',
    text: receiptText
  })
});
```

### After (dengan server name)
```javascript
const currentUser = getCurrentUser(); // Fungsi dari sistem FE Anda

fetch('http://127.0.0.1:18181/print-category', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    categoryId: 'kasir',
    serverName: currentUser.name,  // ← Ambil dari session/state FE
    text: receiptText
  })
});
```

---

## Tips

1. **Server Name Optional**: Jika tidak perlu nama server, cukup kirim `categoryId` dan `text` saja
2. **Business Header Otomatis**: Nama toko, alamat, phone, tanggal otomatis ditambahkan dari Settings OrbitPrint
3. **Format Text Bebas**: Frontend bebas format `text` sesuai kebutuhan (alignment, spacing, dll)
4. **Multi-Category**: Bisa print ke berbeda kategori untuk satu transaksi (receipt ke kasir, order ke dapur)

---

**Happy Testing! 🎉**
