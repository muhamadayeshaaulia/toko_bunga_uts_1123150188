import 'dart:io';
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

  // FETCH SEMUA PRODUK
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
    } catch (e) {
      _error = "Terjadi kesalahan sistem";
      _status = ProductStatus.error;
    } finally {
      notifyListeners();
    }
  }

  // CREATE PRODUCT (SUPPORT UPLOAD & URL)
  Future<bool> createProduct({
    required String name,
    required double price,
    required String category,
    String? description,
    int? stock,
    File? imageFile,
    String? imageUrl,
  }) async {
    _status = ProductStatus.loading;
    notifyListeners();

    try {
      Map<String, dynamic> body = {
        "name": name,
        "price": price,
        "category": category,
        "description": description ?? "",
        "stock": stock ?? 0,
        "image_url": imageUrl ?? "",
      };

      // Jika ada file, bungkus ke FormData
      FormData formData = FormData.fromMap(body);
      if (imageFile != null) {
        formData.files.add(MapEntry(
          "image",
          await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
        ));
      }

      await DioClient.instance.post(ApiConstants.products, data: formData);
      await fetchProducts(); // Refresh data agar list terbaru muncul
      return true;
    } catch (e) {
      _error = "Gagal membuat produk: $e";
      return false;
    } finally {
      _status = ProductStatus.loaded;
      notifyListeners();
    }
  }

  // UPDATE PRODUCT
  Future<bool> updateProduct(
    int id, {
    required String name,
    required double price,
    required String category,
    String? description,
    int? stock,
    File? imageFile,
    String? imageUrl,
  }) async {
    _status = ProductStatus.loading;
    notifyListeners();

    try {
      Map<String, dynamic> body = {
        "name": name,
        "price": price,
        "category": category,
        "description": description ?? "",
        "stock": stock ?? 0,
      };
      
      if (imageUrl != null) body["image_url"] = imageUrl;

      FormData formData = FormData.fromMap(body);
      if (imageFile != null) {
        formData.files.add(MapEntry(
          "image",
          await MultipartFile.fromFile(imageFile.path, filename: imageFile.path.split('/').last),
        ));
      }

      await DioClient.instance.put("${ApiConstants.products}/$id", data: formData);
      await fetchProducts();
      return true;
    } catch (e) {
      _error = "Gagal memperbarui produk: $e";
      return false;
    } finally {
      _status = ProductStatus.loaded;
      notifyListeners();
    }
  }

  // DELETE PRODUCT
  Future<bool> deleteProduct(int id) async {
    try {
      await DioClient.instance.delete("${ApiConstants.products}/$id");
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = "Gagal menghapus produk";
      return false;
    }
  }
}