import 'product_model.dart';

class CartModel {
  final int id;
  final int userId;
  final int productId;
  final int quantity;
  // Ini hasil Preload("Product") dari Golang
  final ProductModel? product; 

  CartModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    this.product,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['ID'] ?? json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      product: json['product'] != null 
          ? ProductModel.fromJson(json['product']) 
          : null,
    );
  }
}