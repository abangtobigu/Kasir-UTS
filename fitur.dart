import 'data.dart';
import 'input.dart';

// ============================================================
// FUNGSI BANTU
// ============================================================

Map<String, dynamic>? cariByKode(String kode) {
  for (final barang in daftarBarang) {
    if (barang['kode'] == kode) return barang;
  }
  return null;
}

int hitungTotal() {
  var total = 0;
  keranjang.forEach((kode, jumlah) {
    final barang = cariByKode(kode)!;
    total += (barang['harga'] as int) * jumlah;
  });
  return total;
}

void cetakIsiKeranjang(Map<String, int> isi) {
  isi.forEach((kode, jumlah) {
    final barang = cariByKode(kode)!;
    final harga = barang['harga'] as int;
    print(
      '$kode | ${barang['nama']} | '
      '$jumlah x Rp$harga = Rp${harga * jumlah}',
    );
  });
}

// ============================================================
// MENU 1: DAFTAR BARANG
// ============================================================

void tampilkanBarang() {
  print('\n=== Daftar Barang ===');

  for (final barang in daftarBarang) {
    print(
      '${barang['kode']} | ${barang['nama']} | '
      'Rp${barang['harga']} | stok ${barang['stok']}',
    );
  }
}

// ============================================================
// MENU 2: TAMBAH KE KERANJANG
// ============================================================

void tambahKeKeranjang() {
  print('\n=== Tambah ke Keranjang ===');

  final kode = bacaTeks('Kode barang').toUpperCase();
  final barang = cariByKode(kode);

  if (barang == null) {
    print('Barang dengan kode $kode tidak ditemukan.');
    return;
  }

  final jumlah = bacaInt('Jumlah', min: 1, max: 1000);
  final sudahDiKeranjang = keranjang[kode] ?? 0;
  final stok = barang['stok'] as int;

  if (sudahDiKeranjang + jumlah > stok) {
    print(
      'Stok tidak cukup. Stok ${barang['nama']}: $stok, '
      'di keranjang: $sudahDiKeranjang.',
    );
    return;
  }

  keranjang[kode] = sudahDiKeranjang + jumlah;
  print('$jumlah ${barang['nama']} masuk ke keranjang.');
}

// ============================================================
// MENU 3: TAMPILKAN KERANJANG
// ============================================================

void tampilkanKeranjang() {
  print('\n=== Keranjang ===');

  if (keranjang.isEmpty) {
    print('Keranjang kosong.');
    return;
  }

  cetakIsiKeranjang(keranjang);

  final total = hitungTotal();
  final diskon = hitungDiskon(total);

  print('Total      : Rp$total');
  print('Diskon     : Rp$diskon');
  print('Total bayar: Rp${total - diskon}');
}

// ============================================================
// MENU 4: TAMBAH BARANG BARU
// ============================================================

void tambahBarangBaru() {
  print('\n=== Tambah Barang Baru ===');

  final kode = bacaTeks('Kode barang').toUpperCase();

  if (cariByKode(kode) != null) {
    print('Kode barang $kode sudah digunakan.');
    return;
  }

  final nama = bacaTeks('Nama barang');
  final harga = bacaInt('Harga barang (Rp)', min: 1);
  final stok = bacaInt('Stok barang', min: 0);

  daftarBarang.add({'kode': kode, 'nama': nama, 'harga': harga, 'stok': stok});

  print('Barang $nama berhasil ditambahkan.');
}

// ============================================================
// MENU 5: HAPUS BARANG DARI KERANJANG
// ============================================================

void hapusDariKeranjang() {
  print('\n=== Hapus dari Keranjang ===');

  if (keranjang.isEmpty) {
    print('Keranjang kosong.');
    return;
  }

  cetakIsiKeranjang(keranjang);

  final kode = bacaTeks('Kode barang yang dihapus').toUpperCase();

  if (!keranjang.containsKey(kode)) {
    print('Barang $kode tidak ada di keranjang.');
    return;
  }

  keranjang.remove(kode);
  print('Barang $kode berhasil dihapus dari keranjang.');
}

// ============================================================
// FUNGSI DISKON
// ============================================================

int hitungDiskon(int total) {
  if (total >= batasDiskonBesar) {
    return total * persenDiskonBesar ~/ 100;
  } else if (total >= batasDiskonKecil) {
    return total * persenDiskonKecil ~/ 100;
  }

  return 0;
}

// ============================================================
// FUNGSI KEMBALIAN
// ============================================================

int hitungKembalian(int totalBayar, int uang) {
  if (uang < totalBayar) {
    throw Exception('Uang kurang Rp${totalBayar - uang}.');
  }

  return uang - totalBayar;
}

// ============================================================
// MENU 6: PEMBAYARAN
// ============================================================

void bayar() {
  if (keranjang.isEmpty) {
    print('\nKeranjang masih kosong.');
    return;
  }

  final total = hitungTotal();
  final diskon = hitungDiskon(total);
  final totalBayar = total - diskon;

  print('\n========== PEMBAYARAN ==========');
  cetakIsiKeranjang(keranjang);
  print('Total       : Rp$total');
  print('Diskon      : Rp$diskon');
  print('Total bayar : Rp$totalBayar');

  final uang = bacaInt('Uang diterima (Rp)', min: 0);

  try {
    final kembalian = hitungKembalian(totalBayar, uang);

    // Simpan riwayat sebelum keranjang dikosongkan.
    simpanRiwayat(total, diskon, uang, kembalian);

    // Kurangi stok berdasarkan barang yang dibeli.
    kurangiStok();

    print('\nPembayaran berhasil!');
    print('Uang diterima : Rp$uang');
    print('Kembalian     : Rp$kembalian');

    keranjang.clear();

    print('Stok berhasil diperbarui.');
    print('Keranjang berhasil dikosongkan.');
  } catch (e) {
    print('\nPembayaran gagal: $e');
    print('Silakan coba pembayaran kembali.');
  }
}

// ============================================================
// FUNGSI KURANGI STOK
// ============================================================

void kurangiStok() {
  keranjang.forEach((kode, jumlah) {
    final barang = cariByKode(kode);

    if (barang != null) {
      barang['stok'] = (barang['stok'] as int) - jumlah;
    }
  });
}

// ============================================================
// FUNGSI SIMPAN RIWAYAT
// ============================================================

void simpanRiwayat(int total, int diskon, int uang, int kembalian) {
  riwayatTransaksi.add({
    'nomor': riwayatTransaksi.length + 1,
    'barang': Map<String, int>.from(keranjang),
    'total': total,
    'diskon': diskon,
    'totalBayar': total - diskon,
    'uang': uang,
    'kembalian': kembalian,
  });
}

/// Menu 7 [Sulit]: menampilkan struk semua transaksi.
void tampilkanRiwayat() {
  // TODO: tampilkan setiap transaksi di riwayatTransaksi seperti struk:
  // isi belanja, total, diskon, total bayar, uang, dan kembalian.
  print('Fitur belum tersedia.');
}
