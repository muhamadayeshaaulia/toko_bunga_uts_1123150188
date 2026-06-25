import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dashboard/data/model/product_model.dart' hide AuthProvider, AuthStatus;
import '../../dashboard/presentation/providers/cart_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../checkout/pages/chekout_page.dart';

class ProductDetailPage extends StatelessWidget {
  final ProductModel product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userName = auth.userModel?['name'] ?? auth.firebaseUser?.displayName ?? 'Pengguna';
    // Menggunakan data asli dari backend
    final soldCount = product.sold;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    product.imageUrl,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rp ${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Terjual $soldCount',
                                style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          product.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.inventory, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Stok: ${product.stock}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              product.category,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const Divider(height: 32, thickness: 1),
                        const Text(
                          'Deskripsi Produk',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description?.isNotEmpty == true 
                              ? product.description! 
                              : 'Tidak ada deskripsi untuk produk ini.',
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await context.read<CartProvider>().addToCart(product.id);
                      NotificationService.showNotification(
                        title: "E-Commerce",
                        body: "Yey $userName, ${product.name} berhasil masuk keranjang!",
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${product.name} ditambahkan ke keranjang')),
                        );
                      }
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('+ Keranjang'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.blueAccent),
                      foregroundColor: Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Beli langsung: Kosongkan keranjang, tambah produk ini, lalu ke checkout
                      final cart = context.read<CartProvider>();
                      await cart.clearCartInDatabase(); 
                      await cart.addToCart(product.id);
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CheckoutPage()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: const Text('Beli Langsung', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
