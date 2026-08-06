class FieldCourtModel {
  const FieldCourtModel({
    required this.id,
    this.nombre,
    this.urlFoto,
    this.surfaceType,
    this.vsFormat,
    this.widthM,
    this.lengthM,
  });

  final int id;
  final String? nombre;
  final String? urlFoto;
  final String? surfaceType;
  final String? vsFormat;
  final double? widthM;
  final double? lengthM;

  factory FieldCourtModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    String? parseText(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    double? parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(
        value?.toString().trim().replaceAll(',', '.') ?? '',
      );
    }

    return FieldCourtModel(
      id: parseId(json['id']),
      nombre: parseText(json['nombre']),
      urlFoto: parseText(json['url_foto']),
      surfaceType: parseText(json['tipo_superficie']),
      vsFormat: parseText(json['vs_format']),
      widthM: parseDouble(json['anchom2']),
      lengthM: parseDouble(json['largom2']),
    );
  }
}

class FieldModel {
  const FieldModel({
    required this.id,
    required this.nombre,
    required this.x,
    required this.y,
    this.direccion,
    this.descripcion,
    this.precioDesde,
    this.urlFoto,
    this.celular,
    this.wsp = false,
    this.canchasCount = 0,
    this.precioDesdeNum,
    this.surfaceTypes = const [],
    this.vsFormats = const [],
    this.rating,
    this.ratingCount,
    this.availability,
    this.canchas = const [],
    this.distanceM,
  });

  final int id;
  final String nombre;
  final double x;
  final double y;
  final String? direccion;
  final String? descripcion;
  final String? precioDesde;
  final String? urlFoto;
  final String? celular;
  final bool wsp;
  final int canchasCount;
  final double? precioDesdeNum;
  final List<String> surfaceTypes;
  final List<String> vsFormats;
  final double? rating;
  final int? ratingCount;
  final dynamic availability;
  final List<FieldCourtModel> canchas;
  final int? distanceM;

  factory FieldModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    double parseDouble(dynamic value, {double fallback = 0}) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final normalized = value.trim().replaceAll(',', '.');
        return double.tryParse(normalized) ?? fallback;
      }
      return fallback;
    }

    return FieldModel(
      id: parseInt(json['id']),
      nombre: (json['nombre'] ?? '').toString(),
      x: parseDouble(json['x']),
      y: parseDouble(json['y']),
      direccion: json['direccion']?.toString(),
      descripcion: json['descripcion']?.toString(),
      precioDesde: json['precio_desde']?.toString(),
      urlFoto: json['url_foto']?.toString(),
      celular: json['celular']?.toString(),
      wsp: json['wsp'] == true,
      canchasCount: parseInt(json['canchas_count']),
      precioDesdeNum: json['precio_desde_num'] != null
          ? parseDouble(json['precio_desde_num'])
          : null,
      surfaceTypes: (json['surface_types'] is List)
          ? (json['surface_types'] as List)
                .map((entry) => entry.toString().trim())
                .where((entry) => entry.isNotEmpty)
                .toList()
          : const [],
      vsFormats: (json['vs_formats'] is List)
          ? (json['vs_formats'] as List)
                .map((entry) => entry.toString().trim())
                .where((entry) => entry.isNotEmpty)
                .toList()
          : const [],
      rating: json['rating'] == null ? null : parseDouble(json['rating']),
      ratingCount: json['rating_count'] == null
          ? null
          : parseInt(json['rating_count']),
      availability: json['availability'],
      canchas: (json['canchas'] is List)
          ? (json['canchas'] as List)
                .whereType<Map>()
                .map(
                  (entry) =>
                      FieldCourtModel.fromJson(entry.cast<String, dynamic>()),
                )
                .toList()
          : const [],
      distanceM: json['distance_m'] == null
          ? null
          : parseInt(json['distance_m']),
    );
  }
}
