import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../storage/token_store.dart';
import 'api_error.dart';
import 'package:dio/io.dart';

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStore = ref.watch(tokenStoreProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 25),
      sendTimeout: const Duration(seconds: 20),
      headers: {
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenStore.token;
        if (token != null && token.isNotEmpty) {
          options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  if (config.env == AppEnv.dev) {
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
  }

  return dio;
});

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getMap(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final data = await _request(
      () => _dio.get(path, queryParameters: queryParameters),
    );
    if (data is Map<String, dynamic>) return data;
    throw ApiError('Respuesta inválida del servidor.');
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final data = await _request(
      () => _dio.get(path, queryParameters: queryParameters),
    );
    if (data is List<dynamic>) return data;
    throw ApiError('Respuesta inválida del servidor.');
  }

  Future<Map<String, dynamic>> postMap(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final responseData = await _request(
      () => _dio.post(path, data: data, queryParameters: queryParameters),
    );
    if (responseData is Map<String, dynamic>) return responseData;
    throw ApiError('Respuesta inválida del servidor.');
  }

  Future<Map<String, dynamic>> postMultipartMap(
    String path, {
    required FormData data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final responseData = await _request(
      () => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {HttpHeaders.contentTypeHeader: 'multipart/form-data'},
        ),
      ),
    );
    if (responseData is Map<String, dynamic>) return responseData;
    throw ApiError('Respuesta inválida del servidor.');
  }

  Future<Map<String, dynamic>> putMap(String path, {Object? data}) async {
    final responseData = await _request(() => _dio.put(path, data: data));
    if (responseData is Map<String, dynamic>) return responseData;
    throw ApiError('Respuesta inválida del servidor.');
  }

  Future<Map<String, dynamic>> deleteMap(String path, {Object? data}) async {
    final responseData = await _request(() => _dio.delete(path, data: data));
    if (responseData is Map<String, dynamic>) return responseData;
    throw ApiError('Respuesta inválida del servidor.');
  }

  Future<dynamic> _request(
    Future<Response<dynamic>> Function() operation,
  ) async {
    try {
      final response = await operation();
      return response.data;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      String message = 'No se pudo conectar con el servidor.';
      if (responseData is Map<String, dynamic>) {
        if (responseData['message'] != null) {
          message = responseData['message'].toString();
        } else if (responseData['errors'] is Map) {
          final errors = responseData['errors'] as Map;
          if (errors.isNotEmpty) {
            final first = errors.values.first;
            if (first is List && first.isNotEmpty) {
              message = first.first.toString();
            }
          }
        }
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }

      throw ApiError(message, statusCode: statusCode);
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});
