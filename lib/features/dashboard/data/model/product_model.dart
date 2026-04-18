import 'package:flutter/material.dart';

class ProductModel {
  final int    id;
  final String name;
  final double price;
  final String imageUrl;
  final String category;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id:       (json['id'] ?? 0) as int,
      name:     json['name'] ?? 'Tanpa Nama',
      price:    (json['price'] ?? 0.0).toDouble(),
      imageUrl: json['image_url'] ?? '',
      category: json['category'] ?? 'Umum',
    );
  }

  @override
  List<Object?> get props => [id, name, price];
}