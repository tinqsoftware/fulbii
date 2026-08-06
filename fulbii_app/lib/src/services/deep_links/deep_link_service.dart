import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum WidgetDeepLinkActionType { select, shareLink, shareLineup }

class WidgetDeepLinkAction {
  const WidgetDeepLinkAction({required this.type, required this.pichangaId});

  final WidgetDeepLinkActionType type;
  final int pichangaId;
}

class DeepLinkService {
  DeepLinkService();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  bool _initialized = false;

  Future<void> initialize({
    required void Function(String joinCode) onJoinCode,
    void Function(int clubId)? onClubId,
    void Function(int pichangaId)? onPichangaId,
    void Function(WidgetDeepLinkAction action)? onWidgetAction,
    VoidCallback? onOpenPichangas,
  }) async {
    if (_initialized) {
      return;
    }

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handleUri(
          initial,
          onJoinCode,
          onClubId,
          onPichangaId,
          onWidgetAction,
          onOpenPichangas,
        );
      }
    } catch (_) {
      // ignored
    }

    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(
        uri,
        onJoinCode,
        onClubId,
        onPichangaId,
        onWidgetAction,
        onOpenPichangas,
      ),
      onError: (_) {},
    );
    _initialized = true;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }

  void _handleUri(
    Uri uri,
    void Function(String joinCode) onJoinCode,
    void Function(int clubId)? onClubId,
    void Function(int pichangaId)? onPichangaId,
    void Function(WidgetDeepLinkAction action)? onWidgetAction,
    VoidCallback? onOpenPichangas,
  ) {
    final joinCode = _extractJoinCode(uri);
    if (joinCode == null) {
      final clubId = extractClubId(uri);
      if (clubId != null && onClubId != null) {
        onClubId(clubId);
        return;
      }

      final widgetAction = extractWidgetAction(uri);
      if (widgetAction != null && onWidgetAction != null) {
        onWidgetAction(widgetAction);
        return;
      }

      final pichangaId = extractPichangaId(uri);
      if (pichangaId != null && onPichangaId != null) {
        onPichangaId(pichangaId);
        return;
      }

      final opensPichangas = extractOpenPichangas(uri);
      if (opensPichangas && onOpenPichangas != null) {
        onOpenPichangas();
      }
      return;
    }
    onJoinCode(joinCode);
  }

  @visibleForTesting
  bool extractOpenPichangas(Uri uri) {
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments
        .map((segment) => segment.trim().toLowerCase())
        .where((segment) => segment.isNotEmpty)
        .toList();

    if (host == 'pichangas') {
      return true;
    }

    if (segments.isNotEmpty && segments.first == 'pichangas') {
      return true;
    }

    return false;
  }

  String? _extractJoinCode(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments.first.toLowerCase() == 'join') {
      final code = segments[1].trim().toUpperCase();
      return code.isEmpty ? null : code;
    }

    if (uri.host.toLowerCase() == 'join' && segments.isNotEmpty) {
      final code = segments.first.trim().toUpperCase();
      return code.isEmpty ? null : code;
    }

    if (segments.isNotEmpty && segments.first.toLowerCase() == 'join') {
      final code = segments.length > 1 ? segments[1].trim().toUpperCase() : '';
      return code.isEmpty ? null : code;
    }

    return null;
  }

  @visibleForTesting
  int? extractPichangaId(Uri uri) {
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments
        .where((segment) => segment.trim().isNotEmpty)
        .toList();

    if (host == 'pichanga' && segments.isNotEmpty) {
      return int.tryParse(segments.first.trim());
    }

    if (segments.length >= 2 && segments.first.toLowerCase() == 'pichanga') {
      return int.tryParse(segments[1].trim());
    }

    final queryId = uri.queryParameters['id']?.trim();
    if ((host == 'pichanga' ||
            (segments.isNotEmpty && segments.first == 'pichanga')) &&
        queryId != null &&
        queryId.isNotEmpty) {
      return int.tryParse(queryId);
    }

    return null;
  }

  @visibleForTesting
  int? extractClubId(Uri uri) {
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments
        .where((segment) => segment.trim().isNotEmpty)
        .toList();

    if (host == 'club' && segments.isNotEmpty) {
      return int.tryParse(segments.first.trim());
    }

    if (segments.length >= 2 && segments.first.toLowerCase() == 'club') {
      return int.tryParse(segments[1].trim());
    }

    return null;
  }

  @visibleForTesting
  WidgetDeepLinkAction? extractWidgetAction(Uri uri) {
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();

    String? actionSegment;
    if (host == 'widget' &&
        segments.length >= 2 &&
        segments.first.toLowerCase() == 'confirmed') {
      actionSegment = segments[1].toLowerCase();
    } else if (segments.length >= 3 &&
        segments[0].toLowerCase() == 'widget' &&
        segments[1].toLowerCase() == 'confirmed') {
      actionSegment = segments[2].toLowerCase();
    }

    if (actionSegment == null) {
      return null;
    }

    final pichangaId = int.tryParse((uri.queryParameters['id'] ?? '').trim());
    if (pichangaId == null || pichangaId <= 0) {
      return null;
    }

    final type = switch (actionSegment) {
      'select' => WidgetDeepLinkActionType.select,
      'share-link' => WidgetDeepLinkActionType.shareLink,
      'share-lineup' => WidgetDeepLinkActionType.shareLineup,
      _ => null,
    };

    if (type == null) {
      return null;
    }

    return WidgetDeepLinkAction(type: type, pichangaId: pichangaId);
  }
}

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService();
});
