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
  ProductStatus get status => _status;
  List<ProductModel> get products => _products;
  String? get error => _error;
  bool get isLoading => _status == ProductStatus.loading;

  Future<void> fetchProducts() async {
    _status = ProductStatus.loading;
    _error = null; 
    notifyListeners();
 
    try {
      final response = await DioClient.instance.get(ApiConstants.products);
      final List<dynamic> data = response.data['data'] ?? [];
      _products = data.map((e) => ProductModel.fromJson(e)).toList();
      _status = ProductStatus.loaded;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Gagal memuat produk dari server';
      _status = ProductStatus.error;
      debugPrint("Dio Error: ${e.message}");
    } catch (e) {
      _error = "Terjadi kesalahan sistem";
      _status = ProductStatus.error;
      debugPrint("General Error: $e");
    } finally {
      notifyListeners();
    }
  }
}