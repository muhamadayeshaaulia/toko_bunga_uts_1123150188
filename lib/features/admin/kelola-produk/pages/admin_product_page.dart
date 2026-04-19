import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../dashboard/presentation/providers/product_provider.dart';

class AdminProductPage extends StatefulWidget {
  const AdminProductPage({super.key});

  @override
  State<AdminProductPage> createState() => _AdminProductPageState();
}

class _AdminProductPageState extends State<AdminProductPage> {
  @override
  void initState() {
    super.initState();
    // Refresh data produk saat halaman dibuka
    Future.microtask(() => context.read<ProductProvider>().fetchProducts());
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            onPressed: () {
              _showAddProductDialog(context);
            },
          )
        ],
      ),
      body: productProvider.status == ProductStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(child: Text('Belum ada produk untuk dikelola.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            p.imageUrl,
                            width: 60, height: 60, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                          ),
                        ),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rp ${p.price.toStringAsFixed(0)}'),
                            Text('Stok: ${p.stock}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tombol Edit
                            IconButton(
                              icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                              onPressed: () {
                                debugPrint("Edit produk: ${p.id}");
                              },
                            ),
                            // Tombol Hapus
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                              onPressed: () {
                                _confirmDelete(context, p.name);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  // Dialog Konfirmasi Hapus
  void _confirmDelete(BuildContext context, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: Text('Apakah kamu yakin ingin menghapus "$productName" dari 716 Production?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Hapus', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  // Dialog Tambah Produk
  void _showAddProductDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20, left: 20, right: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tambah Produk Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const TextField(decoration: InputDecoration(labelText: 'Nama Produk')),
            const TextField(decoration: InputDecoration(labelText: 'Harga'), keyboardType: TextInputType.number),
            const TextField(decoration: InputDecoration(labelText: 'URL Gambar')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 50)),
              child: const Text('Simpan Produk', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}