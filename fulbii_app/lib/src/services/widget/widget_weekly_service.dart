import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../features/pichangas/data/pichangas_repository.dart';
import 'widget_confirmed_mapper.dart';
import 'widget_weekly_mapper.dart';

class WidgetWeeklyService {
  WidgetWeeklyService(this._pichangasRepository);

  static const String _appGroupId = 'group.com.fulbii.shared';
  static const String _payloadKey = 'fulbii_weekly_payload';
  static const String _confirmedPayloadKey = 'fulbii_confirmed_widget_payload';
  static const String _androidProviderName = 'FulbiiWeeklyWidgetProvider';
  static const String _androidConfirmedProviderName =
      'FulbiiConfirmedWidgetProvider';
  static const String _iosWidgetName = 'FulbiiWeeklyWidget';
  static const String _iosConfirmedWidgetName = 'FulbiiConfirmedWidget';

  final PichangasRepository _pichangasRepository;

  Future<void> syncWeekly({bool ignoreErrors = false}) async {
    try {
      await _initializeStorage();

      final response = await _pichangasRepository.availableWithMeta(
        days: WidgetWeeklyMapper.windowDays,
      );
      final payload = WidgetWeeklyMapper.buildPayload(
        response.items,
        monthlyPlayedCount: response.monthlyPlayedCount,
        isLoggedIn: true,
      );
      await HomeWidget.saveWidgetData<String>(
        _payloadKey,
        jsonEncode(payload),
      );
      await _refreshWidgets();
    } catch (e) {
      if (!ignoreErrors) {
        rethrow;
      }
      debugPrint('WidgetWeeklyService sync error: $e');
    }
  }

  Future<void> syncConfirmedWidget({bool ignoreErrors = false}) async {
    try {
      await _initializeStorage();
      final existingSelected = await _readConfirmedSelectedId();
      final items = await _pichangasRepository.confirmedNextWidget(
        limit: WidgetConfirmedMapper.maxItems,
      );
      final payload = WidgetConfirmedMapper.buildPayload(
        items,
        selectedPichangaId: existingSelected,
        isLoggedIn: true,
      );
      await HomeWidget.saveWidgetData<String>(
        _confirmedPayloadKey,
        jsonEncode(payload),
      );
      await _refreshConfirmedWidget();
    } catch (e) {
      if (!ignoreErrors) {
        rethrow;
      }
      debugPrint('WidgetWeeklyService sync confirmed widget error: $e');
    }
  }

  Future<void> syncAll({bool ignoreErrors = false}) async {
    await syncWeekly(ignoreErrors: ignoreErrors);
    await syncConfirmedWidget(ignoreErrors: ignoreErrors);
  }

  Future<void> clearForLoggedOut({bool ignoreErrors = false}) async {
    try {
      await _initializeStorage();
      final payload = WidgetWeeklyMapper.buildLoggedOutPayload();
      final confirmedPayload = WidgetConfirmedMapper.buildLoggedOutPayload();
      await HomeWidget.saveWidgetData<String>(
        _payloadKey,
        jsonEncode(payload),
      );
      await HomeWidget.saveWidgetData<String>(
        _confirmedPayloadKey,
        jsonEncode(confirmedPayload),
      );
      await _refreshWidgets();
      await _refreshConfirmedWidget();
    } catch (e) {
      if (!ignoreErrors) {
        rethrow;
      }
      debugPrint('WidgetWeeklyService clear logout error: $e');
    }
  }

  Future<void> _initializeStorage() async {
    if (!kIsWeb) {
      await HomeWidget.setAppGroupId(_appGroupId);
    }
  }

  Future<void> _refreshWidgets() {
    return HomeWidget.updateWidget(
      androidName: _androidProviderName,
      iOSName: _iosWidgetName,
    );
  }

  Future<void> _refreshConfirmedWidget() {
    return HomeWidget.updateWidget(
      androidName: _androidConfirmedProviderName,
      iOSName: _iosConfirmedWidgetName,
    );
  }

  Future<int?> _readConfirmedSelectedId() async {
    final raw = await HomeWidget.getWidgetData<String>(_confirmedPayloadKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final selected = decoded['selected_pichanga_id'];
      return switch (selected) {
        int value => value,
        String value => int.tryParse(value),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }

  Future<bool> selectConfirmedPichanga(
    int pichangaId, {
    bool ignoreErrors = false,
  }) async {
    try {
      await _initializeStorage();
      final raw = await HomeWidget.getWidgetData<String>(_confirmedPayloadKey);
      if (raw == null || raw.isEmpty) {
        await syncConfirmedWidget(ignoreErrors: true);
      }

      final freshRaw = await HomeWidget.getWidgetData<String>(_confirmedPayloadKey);
      if (freshRaw == null || freshRaw.isEmpty) {
        return false;
      }

      final decoded = jsonDecode(freshRaw);
      if (decoded is! Map) {
        return false;
      }
      final payload = decoded.cast<String, dynamic>();
      final applied = WidgetConfirmedMapper.applySelection(payload, pichangaId);
      if (!applied) {
        return false;
      }

      await HomeWidget.saveWidgetData<String>(
        _confirmedPayloadKey,
        jsonEncode(payload),
      );
      await _refreshConfirmedWidget();
      return true;
    } catch (e) {
      if (!ignoreErrors) {
        rethrow;
      }
      debugPrint('WidgetWeeklyService select confirmed widget error: $e');
      return false;
    }
  }
}

final widgetWeeklyServiceProvider = Provider<WidgetWeeklyService>((ref) {
  final repository = ref.watch(pichangasRepositoryProvider);
  return WidgetWeeklyService(repository);
});
