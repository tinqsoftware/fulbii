import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/field_model.dart';

class FieldsRepository {
  FieldsRepository(this._api);

  final ApiClient _api;

  Future<List<FieldModel>> list({
    String q = '',
    int limit = 1500,
    double? priceMin,
    double? priceMax,
    List<String> surfaceTypes = const [],
    List<String> vsFormats = const [],
  }) async {
    final queryParameters = <String, dynamic>{'q': q, 'limit': limit};
    if (priceMin != null) {
      queryParameters['price_min'] = priceMin;
    }
    if (priceMax != null) {
      queryParameters['price_max'] = priceMax;
    }
    if (surfaceTypes.isNotEmpty) {
      queryParameters['surface_types'] = surfaceTypes.join(',');
    }
    if (vsFormats.isNotEmpty) {
      queryParameters['vs_formats'] = vsFormats.join(',');
    }

    final response = await _api.getMap(
      '/fields',
      queryParameters: queryParameters,
    );

    final items = response['items'] is List ? response['items'] as List : [];
    return items
        .whereType<Map>()
        .map((raw) => FieldModel.fromJson(raw.cast<String, dynamic>()))
        .toList();
  }

  Future<Map<String, dynamic>> listMeta() async {
    final response = await _api.getMap(
      '/fields',
      queryParameters: const {'limit': 1},
    );
    return (response['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
  }

  Future<FieldModel> detail(int fieldId) async {
    final response = await _api.getMap('/fields/$fieldId');
    final field = (response['field'] as Map?)?.cast<String, dynamic>() ?? {};
    return FieldModel.fromJson(field);
  }

  Future<List<Map<String, dynamic>>> addressSuggestions(
    String query,
    LatLngBias? bias,
  ) async {
    final response = await _api.getMap(
      '/geo/address-suggestions',
      queryParameters: {
        'q': query,
        if (bias != null) 'lat': bias.lat,
        if (bias != null) 'lng': bias.lng,
      },
    );
    return (response['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<Map<String, dynamic>?> reverseGeocode(double lat, double lng) async {
    final response = await _api.getMap(
      '/geo/reverse',
      queryParameters: {'lat': lat, 'lng': lng},
    );
    return (response['item'] as Map?)?.cast<String, dynamic>();
  }

  Future<List<FieldModel>> nearby(double lat, double lng) async {
    final response = await _api.getMap(
      '/fields/nearby',
      queryParameters: {'lat': lat, 'lng': lng, 'radius_m': 250, 'limit': 5},
    );
    return (response['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => FieldModel.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<void> submitField({
    required String nombre,
    required String submissionType,
    required String canchaNombre,
    required String canchaEquiposvs,
    required String canchaTipoSuperficie,
    int? existingPolideportivoId,
    String? direccion,
    double? x,
    double? y,
    String? celular,
    bool wsp = false,
    String? descripcion,
    String sourceType = 'manual_map',
    String? canchaAncho,
    String? canchaLargo,
    List<File> venuePhotoFiles = const [],
    List<File> courtPhotoFiles = const [],
  }) async {
    final data = <String, dynamic>{
      'submission_type': submissionType,
      'nombre': nombre,
      'direccion': direccion,
      'x': x?.toStringAsFixed(6),
      'y': y?.toStringAsFixed(6),
      'celular': celular,
      // Multipart values are strings; Laravel's boolean rule accepts 1/0.
      'wsp': wsp ? '1' : '0',
      'descripcion': descripcion,
      'source_type': sourceType,
      // Multipart form values must be strings. Keeping the ID explicit
      // prevents a selected centre from being serialized as an empty value.
      'existing_polideportivo_id': existingPolideportivoId?.toString(),
      'cancha_nombre': canchaNombre,
      'cancha_equiposvs': canchaEquiposvs,
      'cancha_tipo_superficie': canchaTipoSuperficie,
      'cancha_anchom2': canchaAncho,
      'cancha_largom2': canchaLargo,
    }..removeWhere((_, value) => value == null || value == '');
    if (venuePhotoFiles.isNotEmpty) {
      data['venue_photo_files[]'] = await Future.wait(
        venuePhotoFiles.map((file) => MultipartFile.fromFile(file.path)),
      );
    }
    if (courtPhotoFiles.isNotEmpty) {
      data['court_photo_files[]'] = await Future.wait(
        courtPhotoFiles.map((file) => MultipartFile.fromFile(file.path)),
      );
    }
    final form = FormData.fromMap(data);
    await _api.postMultipartMap('/field-submissions', data: form);
  }
}

class LatLngBias {
  const LatLngBias(this.lat, this.lng);
  final double lat;
  final double lng;
}

final fieldsRepositoryProvider = Provider<FieldsRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return FieldsRepository(api);
});
