import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class DioClient {
  static Dio? _instance;
  static Dio get instance{
    _instance ??= _createDio();
    return _instance!;
  }
}