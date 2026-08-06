import 'package:flutter_test/flutter_test.dart';

import 'package:fulbii_app/src/features/clubs/presentation/club_detail_screen.dart';

void main() {
  test('only an administrator receives management controls', () {
    expect(isClubAdminDetail(null), isFalse);
    expect(
      isClubAdminDetail({
        'membership': {'is_member': false, 'my_role': null},
      }),
      isFalse,
    );
    expect(
      isClubAdminDetail({
        'membership': {'is_member': true, 'my_role': 'miembro'},
      }),
      isFalse,
    );
    expect(
      isClubAdminDetail({
        'membership': {'is_member': true, 'my_role': 'admin'},
      }),
      isTrue,
    );
  });

  test('a disabled club is readable but does not expose group actions', () {
    expect(isClubActiveDetail(null), isTrue);
    expect(
      isClubActiveDetail({
        'club': {'is_active': true},
      }),
      isTrue,
    );
    expect(
      isClubActiveDetail({
        'club': {'is_active': false},
      }),
      isFalse,
    );
  });
}
