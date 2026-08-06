import 'package:flutter_test/flutter_test.dart';

import 'package:fulbii_app/src/features/clubs/presentation/club_scope_filter.dart';

void main() {
  test(
    'excludes active memberships and keeps an owner without membership discoverable',
    () {
      final result = filterDiscoverClubs([
        {'id': 1, 'is_member': true},
        {'id': 2, 'is_owner': true},
        {'id': 3, 'is_mine': true},
        {'id': 4, 'my_role': 'member'},
        {'id': 5, 'is_visible': false},
        {'id': 6, 'is_visible': true},
      ], excludedClubIds: <int>{});

      expect(result.map((club) => club['id']), [2, 6]);
    },
  );

  test(
    'excludes IDs loaded from Mis grupos even when API flags are absent',
    () {
      final result = filterDiscoverClubs(
        [
          {'id': 10},
          {'id': 11},
        ],
        excludedClubIds: <int>{10},
      );

      expect(result.map((club) => club['id']), [11]);
    },
  );

  test(
    'drops inactive clubs even when a malformed API response includes them',
    () {
      final result = filterDiscoverClubs([
        {'id': 20, 'is_active': false, 'is_visible': true},
        {'id': 21, 'is_active': true, 'is_visible': true},
      ], excludedClubIds: <int>{});

      expect(result.map((club) => club['id']), [21]);
    },
  );

  test(
    'drops groups without a valid ID instead of showing them as discovery',
    () {
      final result = filterDiscoverClubs([
        {'nombre': 'sin id'},
        {'id': '12', 'is_mine': false},
      ], excludedClubIds: <int>{});

      expect(result.map((club) => club['id']), ['12']);
    },
  );
}
