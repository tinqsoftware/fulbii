List<Map<String, dynamic>> filterDiscoverClubs(
  List<Map<String, dynamic>> items, {
  required Set<int> excludedClubIds,
}) {
  return items.where((club) {
    final id = int.tryParse('${club['id']}');
    if (id == null || excludedClubIds.contains(id)) return false;

    if (club.containsKey('is_active') && !_asBool(club['is_active'])) {
      return false;
    }

    if (club.containsKey('is_visible') && !_asBool(club['is_visible'])) {
      return false;
    }

    final hasRole = club['my_role']?.toString().trim().isNotEmpty == true;
    return !_asBool(club['is_member']) && !_asBool(club['is_mine']) && !hasRole;
  }).toList();
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    return value == '1' || value.toLowerCase() == 'true';
  }
  return false;
}
