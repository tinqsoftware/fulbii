import 'package:flutter_test/flutter_test.dart';

import 'package:fulbii_app/src/features/clubs/presentation/create_club_screen.dart';

void main() {
  test('uses the visible label and exposes join request settings', () {
    expect(createClubVisibilityLabel(true), 'Grupo visible para todos');
    expect(canConfigureClubJoinRequests(true), isTrue);
  });

  test('uses the hidden label and hides join request settings', () {
    expect(createClubVisibilityLabel(false), 'Grupo no visible para todos');
    expect(canConfigureClubJoinRequests(false), isFalse);
  });
}
