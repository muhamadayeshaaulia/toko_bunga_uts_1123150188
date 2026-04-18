import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../../../../core/services/dio_client.dart';

class CartProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> addToCart(int? productId) async {
    if (productId == null || productId == 0) return;

    _isLoading = true;
    notifyListeners();

    try {

      final String? token = await FirebaseAuth.instance.currentUser?.getIdToken();

      debugPrint("Mencoba kirim product_id: $productId dengan Token: ${token != null ? 'Ada' : 'Kosong'}");

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
        debugPrint("Berhasil masuk keranjang!");
      }
    } on DioException catch (e) {
      // Log ini akan sangat membantu jika token salah atau expired
      debugPrint("ERROR API: ${e.response?.data}");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}