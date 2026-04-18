import 'package:flutter/material.dart';
import '../../../../core/services/dio_client.dart';

class CartProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Fungsi untuk nambah barang ke database MySQL lewat Backend API
  Future<void> addToCart(int productId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await DioClient.instance.post(
        '/v1/cart/add',
        data: {'product_id': productId},
      );

      if (response.statusCode == 200) {
        debugPrint("Berhasil tambah ke keranjang!");
      }
    } catch (e) {
      debugPrint("Gagal tambah ke keranjang: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}