import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class ReportsRepository {
  ReportsRepository(this._api);

  final ApiClient _api;

  Future<void> create({
    required String targetType,
    required int targetId,
    required String reasonCode,
    String? description,
    String? contentType,
    int? contentId,
  }) async {
    await _api.postMap(
      '/reports',
      data: {
        'target_type': targetType,
        'target_id': targetId,
        'reason_code': reasonCode,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (contentType != null) 'content_type': contentType,
        if (contentId != null) 'content_id': contentId,
      },
    );
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(apiClientProvider));
});
