import 'dart:math' as math;

import 'field_model.dart';

/// A visual group of nearby sports centers at a particular map zoom level.
class FieldCluster {
  const FieldCluster(this.fields);

  final List<FieldModel> fields;

  bool get isCluster => fields.length > 1;

  String get id {
    final ids = fields.map((field) => field.id).toList()..sort();
    return ids.join('-');
  }

  double get latitude =>
      fields.map((field) => field.x).reduce((a, b) => a + b) / fields.length;

  double get longitude =>
      fields.map((field) => field.y).reduce((a, b) => a + b) / fields.length;
}

/// Groups centers by their projected Google Maps pixels, keeping cluster sizes
/// visually consistent as the camera zoom changes.
class FieldClusterer {
  const FieldClusterer({this.cellSize = 64});

  final double cellSize;

  List<FieldCluster> cluster(List<FieldModel> fields, double zoom) {
    final buckets = <String, List<FieldModel>>{};
    final scale = 256.0 * math.pow(2, zoom.clamp(0, 22));

    for (final field in fields) {
      final point = _project(field.x, field.y, scale);
      final key =
          '${(point.$1 / cellSize).floor()}:${(point.$2 / cellSize).floor()}';
      (buckets[key] ??= <FieldModel>[]).add(field);
    }

    final clusters = buckets.values.map((bucket) {
      bucket.sort((a, b) => a.id.compareTo(b.id));
      return FieldCluster(List<FieldModel>.unmodifiable(bucket));
    }).toList();
    clusters.sort((a, b) => a.fields.first.id.compareTo(b.fields.first.id));
    return clusters;
  }

  (double, double) _project(double latitude, double longitude, double scale) {
    final clampedLatitude = latitude.clamp(-85.05112878, 85.05112878);
    final x = (longitude + 180) / 360 * scale;
    final latitudeRadians = clampedLatitude * math.pi / 180;
    final y =
        (1 -
            math.log(
                  math.tan(latitudeRadians) + 1 / math.cos(latitudeRadians),
                ) /
                math.pi) /
        2 *
        scale;
    return (x, y);
  }
}
