import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/dio_client.dart';
import '../../data/model/product_model.dart';

enum ProductStatus { initial, loading, loaded, error }

class ProductProvider extends ChangeNotifier {
  ProductStatus _status = ProductStatus.initial;
  List<ProductModel> _products = [];
  String? _error;

  var products;

  Object? get isLoading => null;

  get error => null;
 
  Future<void> fetchProducts() async {
    // 1. Set status loading → UI tampilkan spinner
    _status = ProductStatus.loading;
    notifyListeners();
 
    try {
      // 2. Hit API — token otomatis di-inject interceptor
      final response = await DioClient.instance.get(ApiConstants.products);
      // 3. Parse JSON array menjadi List<ProductModel>
      final List<dynamic> data = response.data['data'];
      _products = data.map((e) => ProductModel.fromJson(e)).toList();
 
      // 4. Set status loaded → UI tampilkan grid produk
      _status = ProductStatus.loaded;
    } on DioException catch (e) {
      // 5. Jika error → set status error → UI tampilkan pesan
      _error = e.response?.data['message'] ?? 'Gagal memuat produk';
      _status = ProductStatus.error;
    }
  }
    notifyListeners(); // Beritahu semua widget yang listen
  }
