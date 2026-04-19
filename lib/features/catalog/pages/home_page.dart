import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../dashboard/presentation/providers/cart_provider.dart';
import '../../dashboard/presentation/providers/product_provider.dart';
import '../../../../core/services/notification_service.dart'; // IMPORT INI

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.products;

    // Ambil nama user untuk notifikasi
    final userName = auth.userModel?['name'] ?? auth.firebaseUser?.displayName ?? 'Pengguna';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Katalog Produk', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              'Halo, $userName!',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: switch (productProvider.status) {
        ProductStatus.loading || ProductStatus.initial => const Center(
            child: CircularProgressIndicator(),
          ),
        
        ProductStatus.error => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(productProvider.error ?? 'Gagal terhubung ke server'),
                ElevatedButton(
                  onPressed: () => productProvider.fetchProducts(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),

        ProductStatus.loaded => products.isEmpty
          ? const Center(child: Text('Belum ada produk.'))
          : RefreshIndicator(
              onRefresh: () => productProvider.fetchProducts(),
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, i) {
                  final p = products[i];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            child: Image.network(
                              p.imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Rp ${p.price.toStringAsFixed(0)}', 
                                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // 1. Tambah ke Keranjang lewat API
                                    await context.read<CartProvider>().addToCart(p.id);
                                    
                                    // 2. MUNCULKAN NOTIFIKASI POP-UP (Kaya WA)
                                    NotificationService.showNotification(
                                      title: "Berhasil Tambah Keranjang 🛒",
                                      body: "Yey $userName, ${p.name} sudah masuk keranjang!",
                                    );

                                    // 3. Snackbar Feedback (Opsional)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${p.name} masuk keranjang!'),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                                  child: const Text('Beli', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}