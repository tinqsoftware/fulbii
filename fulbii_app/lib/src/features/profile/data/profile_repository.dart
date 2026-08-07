import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class ProfileRepository {
  ProfileRepository(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> me() => _api.getMap('/me');

  Future<Map<String, dynamic>> completeOnboarding({
    required String nick,
    required String sexo,
  }) {
    return _api.postMap('/onboarding', data: {'nick': nick, 'sexo': sexo});
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> payload) {
    return _api.putMap('/me', data: payload);
  }

  Future<Map<String, dynamic>> updateProfileWithAvatar({
    required Map<String, dynamic> payload,
    File? avatarFile,
  }) async {
    final data = <String, dynamic>{
      for (final entry in payload.entries)
        if (entry.value != null) entry.key: entry.value.toString(),
    };

    if (avatarFile != null) {
      data['avatar'] = await MultipartFile.fromFile(
        avatarFile.path,
        filename: 'avatar.jpg',
      );
    }

    return _api.postMultipartMap(
      '/me',
      data: FormData.fromMap({
        ...data,
        '_method': 'PUT',
      }),
    );
  }

  Future<List<dynamic>> pichangaHistory() async {
    final response = await _api.getMap('/me/pichangas/history');
    return response['items'] is List ? response['items'] as List<dynamic> : [];
  }

  Future<List<dynamic>> favoriteFields() async {
    final response = await _api.getMap('/me/favorite-fields');
    return response['items'] is List ? response['items'] as List<dynamic> : [];
  }

  Future<void> addFavoriteField(int fieldId) async {
    await _api.postMap('/me/favorite-fields/$fieldId');
  }

  Future<void> removeFavoriteField(int fieldId) async {
    await _api.deleteMap('/me/favorite-fields/$fieldId');
  }

  Future<List<dynamic>> myProfileClips() async {
    final response = await _api.getMap('/me/profile-clips');
    return response['items'] is List ? response['items'] as List<dynamic> : [];
  }

  Future<List<dynamic>> userProfileClips(int userId) async {
    final response = await _api.getMap('/users/$userId/profile-clips');
    return response['items'] is List ? response['items'] as List<dynamic> : [];
  }

  Future<Map<String, dynamic>> uploadProfileClip({
    required File file,
    required int sourceDurationMs,
    required int durationMs,
    required bool hasAudio,
    String? title,
    int? width,
    int? height,
  }) async {
    final formData = FormData.fromMap({
      'title': title?.trim(),
      'source_duration_ms': sourceDurationMs,
      'duration_ms': durationMs,
      'has_audio': hasAudio ? 1 : 0,
      'width': width,
      'height': height,
      'clip': await MultipartFile.fromFile(
        file.path,
        filename: file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'clip.mp4',
      ),
    });
    return _api.postMultipartMap('/me/profile-clips', data: formData);
  }

  Future<void> deleteProfileClip(int clipId) async {
    await _api.deleteMap('/me/profile-clips/$clipId');
  }

  Future<void> reorderProfileClips(List<int> clipIds) async {
    await _api.putMap('/me/profile-clips/reorder', data: {'clip_ids': clipIds});
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return ProfileRepository(api);
});
