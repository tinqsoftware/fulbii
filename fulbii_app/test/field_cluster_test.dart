import 'package:flutter_test/flutter_test.dart';
import 'package:fulbii_app/src/features/fields/domain/field_cluster.dart';
import 'package:fulbii_app/src/features/fields/domain/field_model.dart';

FieldModel field(int id, double latitude, double longitude) =>
    FieldModel(id: id, nombre: 'Centro $id', x: latitude, y: longitude);

void main() {
  const clusterer = FieldClusterer();

  test('groups nearby centers at a distant zoom', () {
    final clusters = clusterer.cluster([
      field(1, -12.0464, -77.0428),
      field(2, -12.0466, -77.0426),
      field(3, -12.0465, -77.0427),
    ], 11);

    expect(clusters, hasLength(1));
    expect(clusters.single.fields.map((item) => item.id), [1, 2, 3]);
  });

  test('separates centers as the camera gets closer', () {
    final fields = [field(1, -12.0464, -77.0428), field(2, -12.0466, -77.0426)];

    expect(clusterer.cluster(fields, 11), hasLength(1));
    expect(clusterer.cluster(fields, 18), hasLength(2));
  });

  test('keeps distant centers in independent clusters', () {
    final clusters = clusterer.cluster([
      field(1, -12.0464, -77.0428),
      field(2, -12.1400, -77.0200),
    ], 11);

    expect(clusters, hasLength(2));
    expect(clusters.every((cluster) => !cluster.isCluster), isTrue);
  });
}
