import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dashboard/presentation/providers/cart_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/presentation/providers/auth_provider.dart'; // Tambahkan import ini

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CartProvider>().fetchCart());
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data dari provider
    final cartProvider = context.watch<CartProvider>();
    final authProvider = context.watch<AuthProvider>();
    
    final cartItems = cartProvider.cartItems;
    
    // Ambil nama user untuk notifikasi yang lebih personal
    final userName = authProvider.userModel?['name'] ?? authProvider.firebaseUser?.displayName ?? 'Nafisah';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Keranjang Belanja', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: cartProvider.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : cartItems.isEmpty 
          ? const Center(child: Text('Keranjang kamu masih kosong'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final product = item.product;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  product?.imageUrl ?? '',
                                  width: 70, height: 70, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 70, height: 70, color: Colors.grey.shade200,
                                    child: const Icon(Icons.fastfood),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product?.name ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('Rp ${product?.price.toStringAsFixed(0)}', 
                                      style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                    onPressed: () async {
                                      await cartProvider.decreaseQuantity(item.productId);

                                      // Notifikasi dengan nama user
                                      NotificationService.showNotification(
                                        title: "716_Production",
                                        body: "Yahhh $userName, jumlah ${product?.name} dikurangi nih.",
                                      );
                                    },
                                  ),
                                  Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                                    onPressed: () async {
                                      await cartProvider.addToCart(item.productId);
                                      
                                      // Notifikasi dengan nama user
                                      NotificationService.showNotification(
                                        title: "716_Production",
                                        body: "Yeyyy $userName, ${product?.name} berhasil ditambah!",
                                      );
                                    },
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Rp ${cartProvider.totalPrice.toStringAsFixed(0)}', 
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: cartItems.isEmpty ? null : () {
                            NotificationService.showNotification(
                              title: "Checkout Berhasil ✅",
                              body: "Tenang $userName, pesanan kamu sedang diproses 716_Production!",
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Checkout Sekarang', 
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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