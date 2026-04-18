import 'package:flutter/material.dart';

class ApiConstants {
  static const String baseUrl = 'http://192.168.68.136:8080/v1';
 
  // Auth endpoints
  static const String verifyToken = '/auth/verify-token';
  static const String register    = '/auth/register';
 
  // Product endpoints
  static const String products = '/products';
 
  // Timeout
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

}