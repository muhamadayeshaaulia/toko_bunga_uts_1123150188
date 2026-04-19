import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../../../../core/services/dio_client.dart';
import '../../data/model/cart_model.dart';

class CartProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<CartModel> _cartItems = [];
  List<CartModel> get cartItems => _cartItems;

  // Getter untuk menghitung Total Harga secara otomatis
  double get totalPrice {
    double total = 0;
    for (var item in _cartItems) {
      if (item.product != null) {
        total += (item.product!.price * item.quantity);
      }
    }
    return total;
  }

  // Ambil Data Keranjang (GET)
  Future<void> fetchCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      final String? token = await FirebaseAuth.instance.currentUser?.getIdToken();

      final response = await DioClient.instance.get(
        '/cart',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      debugPrint("RESPON API KERANJANG: ${response.data}");

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'];
        _cartItems = data.map((e) => CartModel.fromJson(e)).toList();
      }
    } on DioException catch (e) {
      debugPrint("GAGAL AMBIL KERANJANG: ${e.response?.data ?? e.message}");
      _cartItems = []; // Kosongkan list jika gagal
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tambah Quantity / Item (POST)
  Future<void> addToCart(int? productId) async {
    if (productId == null || productId == 0) return;

    try {
      final String? token = await FirebaseAuth.instance.currentUser?.getIdToken();

      final response = await DioClient.instance.post(
        '/cart/add',
        data: {
          'product_id': productId, 
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token', 
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint("Berhasil tambah quantity!");
        await fetchCart(); // Refresh data agar UI sinkron dengan DB
      }
    } on DioException catch (e) {
      debugPrint("ERROR ADD TO CART: ${e.response?.data}");
    }
  }

  // Fungsi yang dipanggil tombol minus (-)
  Future<void> decreaseQuantity(int? productId) async {
    if (productId == null || productId == 0) return;

    try {
      final String? token = await FirebaseAuth.instance.currentUser?.getIdToken();

      final response = await DioClient.instance.post(
        '/cart/reduce',
        data: {
          'product_id': productId, 
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token', 
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint("Berhasil kurangi quantity!");
        await fetchCart(); // Jika DB menghapus item karena qty 0, fetch ini akan mengupdate UI
      }
    } on DioException catch (e) {
      debugPrint("ERROR REDUCE QUANTITY: ${e.response?.data}");
    }
  }

  // Hapus Item Sepenuhnya (Opsional)
  Future<void> removeFromCart(int? productId) async {
    if (productId == null || productId == 0) return;

    try {
      final String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
      
      // Jika kamu punya endpoint DELETE /cart/:id di Golang
      final response = await DioClient.instance.delete(
        '/cart/$productId', 
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        await fetchCart();
      }
    } catch (e) {
      debugPrint("ERROR REMOVE FROM CART: $e");
    }
  }
  Future<void> clearCartInDatabase() async {
    try {
      final String? token = await FirebaseAuth.instance.currentUser?.getIdToken();

      // Mengirim request DELETE ke Backend
      final response = await DioClient.instance.delete(
        '/cart', 
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        debugPrint("Database bersih, UI juga kita bersihkan.");
        _cartItems = []; 
        notifyListeners(); 
      }
    } on DioException catch (e) {
      debugPrint("Gagal hapus data di server: ${e.response?.data}");
    }
  }

  // Fungsi tambahan untuk mengosongkan state saat logout
  void clearCart() {
    _cartItems = [];
    notifyListeners();
  }
  void clearCartAfterCheckout() {
    _cartItems = []; 
    notifyListeners(); 
    debugPrint("State keranjang dibersihkan setelah checkout.");
  }
}