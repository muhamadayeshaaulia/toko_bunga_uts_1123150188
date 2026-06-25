import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../dashboard/data/model/product_model.dart' hide AuthProvider, AuthStatus;
import '../../dashboard/presentation/providers/cart_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/secure_storage.dart';
import '../../dashboard/presentation/pages/transaction_history_page.dart';
import '../../../../main.dart';

class CheckoutPage extends StatefulWidget {
  final ProductModel? directBuyProduct;
  final int directQuantity;

  const CheckoutPage({super.key, this.directBuyProduct, this.directQuantity = 1});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> with WidgetsBindingObserver {
  bool _isConnected = false;
  double _balance = 0.0;
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStatus();
    MyApp.refreshTrigger.addListener(_loadStatus);
  }

  @override
  void dispose() {
    MyApp.refreshTrigger.removeListener(_loadStatus);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadStatus();
    }
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoadingStatus = true);
    final prefs = await SharedPreferences.getInstance();
    final connected = prefs.getBool('is_emoney_connected') ?? false;
    
    double balance = 0;
    if (connected) {
      try {
        final emoneyToken = prefs.getString('emoney_token');
        if (emoneyToken != null) {
          final response = await Dio().get(
            'http://192.168.8.196:8081/v1/account',
            options: Options(
              headers: {'Authorization': 'Bearer $emoneyToken'},
              validateStatus: (status) => status! < 500,
            ),
          );
          if (response.statusCode == 200 && response.data != null) {
            balance = (response.data['data']['balance'] as num).toDouble();
          } else {
             debugPrint('Gagal token emoney tidak valid? ${response.statusCode}');
          }
        } else {
           debugPrint('emoney_token belum tersimpan');
        }
      } catch (e) {
        debugPrint('Gagal ambil saldo: $e');
      }
    }
    
    if (mounted) {
      setState(() {
        _isConnected = connected;
        _balance = balance;
        _isLoadingStatus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan watch agar data sinkron
    final cartProvider = context.watch<CartProvider>();
    final authProvider = context.watch<AuthProvider>();
    final cartItems = widget.directBuyProduct != null ? [] : cartProvider.cartItems;
    final displayTotal = widget.directBuyProduct != null 
        ? (widget.directBuyProduct!.price * widget.directQuantity)
        : cartProvider.totalPrice;
    final userName = authProvider.userModel?['name'] ?? 'Nafisah';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Bagian Daftar Barang
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.directBuyProduct != null ? 1 : cartItems.length,
              itemBuilder: (context, index) {
                if (widget.directBuyProduct != null) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text('${widget.directQuantity}x'),
                    ),
                    title: Text(widget.directBuyProduct!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Rp ${widget.directBuyProduct!.price.toStringAsFixed(0)}'),
                    trailing: Text(
                      'Rp ${displayTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }
                final item = cartItems[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text('${item.quantity}x'),
                  ),
                  title: Text(item.product?.name ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Rp ${item.product?.price.toStringAsFixed(0)}'),
                  trailing: Text(
                    'Rp ${(item.quantity * (item.product?.price ?? 0)).toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          
          // Bagian Total & Tombol Bayar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Bagian E-Money Wallet Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isConnected ? Colors.blue.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isConnected ? Colors.blue.shade100 : Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: _isConnected ? Colors.blueAccent : Colors.redAccent, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _isLoadingStatus
                            ? const Text('Mengecek status wallet...')
                            : _isConnected
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('E-Money Mamah Saya', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                      Text('Saldo: Rp ${_balance.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  )
                                : const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('E-Money Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text('Belum terhubung', style: TextStyle(color: Colors.red, fontSize: 12)),
                                    ],
                                  ),
                      ),
                      if (!_isLoadingStatus && !_isConnected)
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              await launchUrl(Uri.parse('emoneyapp://connect'), mode: LaunchMode.externalApplication);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-Money belum terinstall')));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text('Hubungkan', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Biaya', style: TextStyle(fontSize: 18)),
                    Text('Rp ${displayTotal.toStringAsFixed(0)}', 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: (cartItems.isEmpty && widget.directBuyProduct == null) ? null : () async {
                      final total = displayTotal;

                      if (!_isConnected) {
                        // Kalau belum terhubung, tidak bisa bayar
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Harap hubungkan E-Money Wallet terlebih dahulu!')),
                        );
                        return;
                      }

                      if (_balance < total) {
                        // Kalau saldo tidak cukup, tidak bisa bayar
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saldo E-Money Wallet Anda tidak cukup!')),
                        );
                        return;
                      }

                      // Ini akan memanggil endpoint POST /transactions di Golang
                      final invoiceId = await context.read<CartProvider>().createTransaction(
                        amount: total,
                        directProductId: widget.directBuyProduct?.id,
                        directQuantity: widget.directBuyProduct != null ? widget.directQuantity : null,
                      );

                      if (invoiceId != null) {

                        // Memanggil Deep Link ke Aplikasi E-Money
                        final token = await SecureStorageService.getToken();
                        final url = Uri.parse('emoneyapp://pay?invoice_id=$invoiceId&amount=$total&token=$token');
                        
                        try {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          // Jika gagal / aplikasi e-money belum diinstall, kita beritahu
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Aplikasi E-Money Mamah Saya belum di-install atau tidak bisa dibuka')),
                          );
                        }

                        // Kembali ke dashboard saja untuk background
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gagal membuat tagihan. Coba lagi.')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isConnected ? Colors.green : Colors.grey, // Warna sukses jika terhubung
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'BAYAR SEKARANG',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
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