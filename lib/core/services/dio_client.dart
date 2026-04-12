import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class DioClient {
  static Dio? _instance;
  static Dio get instance{
    _instance ??= _createDio(); // Singleton pattern
    return _instance!;
  }
  static Dio _createDio(){
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
      headers: {'Content-Type': 'application/json'},
    ));

    
  }
}