import 'package:flutter_test/flutter_test.dart';

import 'package:fulbii_app/src/services/deep_links/deep_link_service.dart';

void main() {
  test('extractPichangaId supports custom scheme and https path', () {
    final service = DeepLinkService();

    expect(service.extractPichangaId(Uri.parse('fulbii://pichanga/123')), 123);
    expect(
      service.extractPichangaId(Uri.parse('https://fulbii.com/pichanga/456')),
      456,
    );
    expect(service.extractPichangaId(Uri.parse('fulbii://join/ABC')), isNull);
    expect(
      service.extractPichangaId(Uri.parse('fulbii://pichanga/abc')),
      isNull,
    );
  });

  test('extractClubId supports custom scheme and https path', () {
    final service = DeepLinkService();

    expect(service.extractClubId(Uri.parse('fulbii://club/123')), 123);
    expect(
      service.extractClubId(Uri.parse('https://fulbii.com/club/456')),
      456,
    );
    expect(service.extractClubId(Uri.parse('fulbii://join/ABC')), isNull);
    expect(service.extractClubId(Uri.parse('fulbii://club/abc')), isNull);
  });

  test('extractWidgetAction parses widget confirmed actions', () {
    final service = DeepLinkService();

    final select = service.extractWidgetAction(
      Uri.parse('fulbii://widget/confirmed/select?id=77'),
    );
    expect(select, isNotNull);
    expect(select!.type, WidgetDeepLinkActionType.select);
    expect(select.pichangaId, 77);

    final shareLink = service.extractWidgetAction(
      Uri.parse('fulbii://widget/confirmed/share-link?id=88'),
    );
    expect(shareLink, isNotNull);
    expect(shareLink!.type, WidgetDeepLinkActionType.shareLink);
    expect(shareLink.pichangaId, 88);

    final shareLineup = service.extractWidgetAction(
      Uri.parse('https://fulbii.com/widget/confirmed/share-lineup?id=99'),
    );
    expect(shareLineup, isNotNull);
    expect(shareLineup!.type, WidgetDeepLinkActionType.shareLineup);
    expect(shareLineup.pichangaId, 99);

    expect(
      service.extractWidgetAction(
        Uri.parse('fulbii://widget/confirmed/select'),
      ),
      isNull,
    );
    expect(
      service.extractWidgetAction(
        Uri.parse('fulbii://widget/confirmed/invalid?id=10'),
      ),
      isNull,
    );
  });

  test('extractOpenPichangas supports custom scheme and https path', () {
    final service = DeepLinkService();

    expect(
      service.extractOpenPichangas(Uri.parse('fulbii://pichangas')),
      isTrue,
    );
    expect(
      service.extractOpenPichangas(Uri.parse('https://fulbii.com/pichangas')),
      isTrue,
    );
    expect(
      service.extractOpenPichangas(Uri.parse('fulbii://pichanga/123')),
      isFalse,
    );
    expect(
      service.extractOpenPichangas(Uri.parse('fulbii://join/ABC')),
      isFalse,
    );
  });
}
