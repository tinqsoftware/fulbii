import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/formatters/spanish_date_formatter.dart';
import '../../profile/data/profile_repository.dart';
import '../../auth/presentation/login_required_sheet.dart';
import '../../auth/session_controller.dart';
import '../../pichangas/data/pichangas_repository.dart';
import '../data/fields_repository.dart';
import '../domain/field_cluster.dart';
import '../domain/field_model.dart';
import 'field_detail_screen.dart';
import 'map_filter_controls.dart';
import 'field_submission_screen.dart';

class MapFilterState {
  const MapFilterState({
    this.priceMin,
    this.priceMax,
    this.surfaceTypes = const [],
    this.vsFormats = const [],
  });

  final double? priceMin;
  final double? priceMax;
  final List<String> surfaceTypes;
  final List<String> vsFormats;

  MapFilterState copyWith({
    double? priceMin,
    double? priceMax,
    List<String>? surfaceTypes,
    List<String>? vsFormats,
  }) {
    return MapFilterState(
      priceMin: priceMin,
      priceMax: priceMax,
      surfaceTypes: surfaceTypes ?? this.surfaceTypes,
      vsFormats: vsFormats ?? this.vsFormats,
    );
  }
}

class _FieldPlaceholder extends StatelessWidget {
  const _FieldPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.sports_soccer_outlined,
          color: colorScheme.primary,
          size: 36,
        ),
      ),
    );
  }
}

final mapFilterStateProvider = StateProvider.autoDispose<MapFilterState>(
  (ref) => const MapFilterState(),
);

final fieldsProvider = FutureProvider.autoDispose<List<FieldModel>>((
  ref,
) async {
  final repo = ref.watch(fieldsRepositoryProvider);
  final filter = ref.watch(mapFilterStateProvider);
  return repo.list(
    limit: 1500,
    priceMin: filter.priceMin,
    priceMax: filter.priceMax,
    surfaceTypes: filter.surfaceTypes,
    vsFormats: filter.vsFormats,
  );
});

final favoriteFieldIdsProvider = FutureProvider.autoDispose<Set<int>>((
  ref,
) async {
  final repo = ref.watch(profileRepositoryProvider);
  final favorites = await repo.favoriteFields();
  return favorites
      .whereType<Map>()
      .map((item) => item['polideportivo_id'])
      .map((id) => int.tryParse(id.toString()))
      .whereType<int>()
      .toSet();
});

final mapScreenMessageProvider = StateProvider<String?>((ref) => null);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({
    required this.onOpenPichanga,
    required this.onOpenInbox,
    super.key,
  });

  final void Function(int pichangaId) onOpenPichanga;
  final VoidCallback onOpenInbox;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _priceMinController = TextEditingController();
  final TextEditingController _priceMaxController = TextEditingController();

  final Set<String> _selectedSurfaceTypes = <String>{};
  final Set<String> _selectedVsFormats = <String>{};
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  final FieldClusterer _clusterer = const FieldClusterer();
  late AnimationController _pulseController;
  LatLng? _currentUserLocation;
  BitmapDescriptor? _userLocationIconCache;

  bool _showList = false;
  // `both` means all fields, while `pichangas` restricts the fields to venues
  // that have an event in the selected period.
  String _mapContent = 'both';
  String _pichangaRange = 'custom';
  DateTimeRange? _customPichangaRange;
  Future<List<Map<String, dynamic>>>? _pichangasFuture;
  FieldModel? _selectedField;
  int? _selectedPichangaId;
  bool _showSelectedFieldPreview = false;
  Future<FieldModel>? _selectedFieldDetail;
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _locationSubscription;
  bool _myLocationEnabled = false;
  bool _didAutoCenterOnLocation = false;
  LatLng? _pendingInitialUserLocation;
  double _cameraZoom = 11.5;
  int _cameraRevision = 0;
  int _filterRequestId = 0;
  List<FieldModel> _lastMapFields = const [];
  bool _fitResultsAfterApplyingFilters = false;

  Future<Set<Marker>>? _markersFuture;
  String _lastMarkersKey = '';

  static const List<String> _surfaceTypeOptions = [
    'losa',
    'sintetico',
    'natural',
  ];
  static const String _mapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#101714"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#c3cdc6"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#101714"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#2b3931"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#101714"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#25332d"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#1a241f"}]},
  {"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#34453d"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#43574e"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#25332d"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#07100d"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#76867d"}]}
]
''';

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _customPichangaRange = DateTimeRange(
      start: today,
      end: today.add(const Duration(days: 6)),
    );
    _pulseController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 900),
        )..addListener(() {
          if (_selectedField != null && mounted) {
            setState(() {
              _cameraRevision++;
            });
          }
        });
    _restoreLocationLayer();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _locationSubscription?.cancel();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(mapScreenMessageProvider, (previous, next) {
      if (next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Crear pichanga'),
              content: Text(next),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
          ref.read(mapScreenMessageProvider.notifier).state = null;
        });
      }
    });

    final fieldsAsync = ref.watch(fieldsProvider);

    return fieldsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No se pudo cargar el mapa: $error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(fieldsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (fields) {
        final validFields = fields
            .where(
              (f) =>
                  f.x != 0 &&
                  f.y != 0 &&
                  f.x >= -90 &&
                  f.x <= 90 &&
                  f.y >= -180 &&
                  f.y <= 180,
            )
            .toList();

        final initial = validFields.isNotEmpty
            ? LatLng(validFields.first.x, validFields.first.y)
            : const LatLng(-12.0464, -77.0428);

        _scheduleResultsFit(validFields);

        return Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _showList
                  ? _buildListView(fields)
                  : _buildMapView(validFields, initial),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    final activeFilters =
        _selectedSurfaceTypes.length +
        _selectedVsFormats.length +
        (_priceMinController.text.isNotEmpty ||
                _priceMaxController.text.isNotEmpty
            ? 1
            : 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final headerColor = isDark ? const Color(0xFF080C0A) : colorScheme.surface;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: headerColor),
      child: Container(
        color: headerColor,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: _openFiltersSheet,
                  tooltip: 'Filtros',
                  icon: Badge(
                    isLabelVisible: activeFilters > 0,
                    label: Text('$activeFilters'),
                    child: const Icon(Icons.tune),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                    segments: const [
                      ButtonSegment(value: false, label: Text('Mapa')),
                      ButtonSegment(value: true, label: Text('Lista')),
                    ],
                    selected: {_showList},
                    onSelectionChanged: (value) =>
                        setState(() => _showList = value.first),
                  ),
                ),
                const SizedBox(width: 8),
                _MapContentBadge(content: _mapContent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceGrid({
    required int columns,
    required double height,
    required List<Widget> children,
  }) {
    const spacing = 6.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map(
                (child) =>
                    SizedBox(width: itemWidth, height: height, child: child),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildMapView(List<FieldModel> fields, LatLng initial) {
    _pichangasFuture ??= _loadMapPichangas();
    return Stack(
      children: [
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _pichangasFuture,
          builder: (context, pichangasSnapshot) {
            final pichangas =
                pichangasSnapshot.data ?? const <Map<String, dynamic>>[];
            final countByField = _pichangaCountsByField(pichangas);
            final visibleFields = _mapContent == 'pichangas'
                ? fields
                      .where((field) => (countByField[field.id] ?? 0) > 0)
                      .toList()
                : fields;
            _lastMapFields = visibleFields;
            _ensureMarkersFuture(visibleFields, countByField.keys.toSet());
            final cameraTarget = visibleFields.isNotEmpty
                ? LatLng(visibleFields.first.x, visibleFields.first.y)
                : initial;
            return FutureBuilder<Set<Marker>>(
              future: _markersFuture,
              builder: (context, snapshot) => GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: cameraTarget,
                  zoom: 11.5,
                ),
                markers: snapshot.data ?? const <Marker>{},
                style: Theme.of(context).brightness == Brightness.dark
                    ? _mapStyle
                    : null,
                myLocationEnabled: _myLocationEnabled,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: true,
                onMapCreated: _onMapCreated,
                onCameraMove: (position) => _cameraZoom = position.zoom,
                onCameraIdle: _handleCameraIdle,
                onTap: (_) => _clearSelectedField(),
              ),
            );
          },
        ),
        if (_hasActiveFilters)
          Positioned(
            top: 12,
            left: 12,
            child: _buildResultsBadge(fields.length),
          ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _pichangasFuture,
            builder: (context, snapshot) {
              final pichangas = _flatMapPichangas(
                snapshot.data ?? const <Map<String, dynamic>>[],
              );
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_selectedField != null && _showSelectedFieldPreview) ...[
                    _buildSelectedPreview(_selectedField!),
                    const SizedBox(height: 10),
                  ],
                  _buildPichangaCarousel(pichangas),
                ],
              );
            },
          ),
        ),
        Positioned(
          right: 16,
          bottom: _selectedField != null && _showSelectedFieldPreview
              ? 390
              : 156,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'my-location',
                onPressed: _centerOnMyLocation,
                tooltip: 'Mi ubicación',
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'submit-field',
                onPressed: _openSubmitFieldDialog,
                child: const Icon(Icons.add_location_alt_outlined),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool get _hasActiveFilters =>
      _selectedSurfaceTypes.isNotEmpty ||
      _selectedVsFormats.isNotEmpty ||
      _priceMinController.text.isNotEmpty ||
      _priceMaxController.text.isNotEmpty;

  Widget _buildResultsBadge(int resultCount) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _openFiltersSheet,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.only(left: 12, right: 3, top: 4, bottom: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.primary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sports_soccer_outlined,
                size: 17,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '$resultCount ${resultCount == 1 ? 'cancha' : 'canchas'}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                onPressed: _clearFilters,
                tooltip: 'Limpiar filtros',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 30,
                  height: 30,
                ),
                icon: const Icon(Icons.close, size: 17),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<FieldModel> fields) {
    // The list and the map intentionally share this request. This keeps every
    // venue's count aligned with the pichanga date filter currently selected.
    _pichangasFuture ??= _loadMapPichangas();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _pichangasFuture,
      builder: (context, snapshot) {
        if (_mapContent == 'pichangas' &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final pichangas = snapshot.data ?? const <Map<String, dynamic>>[];
        final countByField = _pichangaCountsByField(pichangas);
        final visibleFields = _mapContent == 'pichangas'
            ? fields
                  .where((field) => (countByField[field.id] ?? 0) > 0)
                  .toList()
            : fields;

        if (visibleFields.isEmpty) {
          return Center(
            child: Text(
              _mapContent == 'pichangas'
                  ? 'No hay pichangas para este rango de fechas.'
                  : 'No hay polideportivos con estos filtros.',
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(fieldsProvider);
            setState(() => _pichangasFuture = _loadMapPichangas());
            await _pichangasFuture;
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: visibleFields.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final field = visibleFields[index];
              return _buildFieldCard(
                field,
                pichangaCount: countByField[field.id] ?? 0,
              );
            },
          ),
        );
      },
    );
  }

  Map<int, int> _pichangaCountsByField(List<Map<String, dynamic>> venues) {
    final result = <int, int>{};
    for (final venue in venues) {
      final fieldId = (venue['field_id'] as num?)?.toInt();
      if (fieldId == null) continue;
      final items = venue['items'];
      final count = items is List
          ? items.length
          : (venue['mine_count'] as num? ?? 0).toInt() +
                (venue['public_count'] as num? ?? 0).toInt();
      result[fieldId] = count;
    }
    return result;
  }

  List<Map<String, dynamic>> _flatMapPichangas(
    List<Map<String, dynamic>> venues,
  ) {
    final items = <Map<String, dynamic>>[];
    for (final venue in venues) {
      final fieldId = (venue['field_id'] as num?)?.toInt();
      final venueItems = venue['items'];
      if (fieldId == null || venueItems is! List) continue;
      for (final rawItem in venueItems.whereType<Map>()) {
        final item = rawItem.cast<String, dynamic>();
        items.add({...item, 'field_id': fieldId});
      }
    }
    items.sort((a, b) {
      final aDate = SpanishDateFormatter.parse(a['starts_at']?.toString());
      final bDate = SpanishDateFormatter.parse(b['starts_at']?.toString());
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return items;
  }

  Widget _buildPichangaCarousel(List<Map<String, dynamic>> pichangas) {
    final colorScheme = Theme.of(context).colorScheme;
    if (pichangas.isEmpty) {
      return Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.sports_soccer_outlined, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('No hay pichangas abiertas en este rango.'),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 104,
      child: ListView.separated(
        key: const ValueKey('map-pichangas-carousel'),
        scrollDirection: Axis.horizontal,
        itemCount: pichangas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = pichangas[index];
          final id =
              (item['id'] as num?)?.toInt() ??
              int.tryParse(item['id']?.toString() ?? '');
          final selected = id != null && id == _selectedPichangaId;
          final date = SpanishDateFormatter.pichangaDate(
            item['starts_at']?.toString(),
          );
          final court = (item['court_name'] ?? 'Cancha por confirmar')
              .toString();
          final field = (item['field_name'] ?? 'Polideportivo').toString();
          return SizedBox(
            width: 238,
            child: Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFFFF615B)
                      : colorScheme.outlineVariant,
                  width: selected ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: () => _selectMapPichanga(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFFFF9E99)
                                    : colorScheme.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          if (item['is_my_group'] == true)
                            _mapPichangaTag('Mi grupo'),
                          if (item['me_participant_status'] == 'confirmed')
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: _mapPichangaTag('Confirmado'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        (item['title'] ?? 'Pichanga').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$court · $field',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.groups_2_outlined,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${item['confirmed_count'] ?? 0}/${item['capacity'] ?? 0}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${item['spots_left'] ?? 0} cupos',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _mapPichangaTag(String label) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF27452D),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildFieldCard(FieldModel field, {required int pichangaCount}) {
    final isAuthenticated = ref
        .watch(sessionControllerProvider)
        .isAuthenticated;
    final favoriteIds = isAuthenticated
        ? ref.watch(favoriteFieldIdsProvider).valueOrNull ?? const <int>{}
        : const <int>{};
    final isFavorite = favoriteIds.contains(field.id);
    final image = (field.urlFoto ?? '').trim();
    final summary = _courtSummary(field);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openFieldDetail(field.id),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: image.isEmpty
                    ? const _FieldPlaceholder()
                    : Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _FieldPlaceholder(),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            field.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              _toggleFavorite(field.id, isFavorite),
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? const Color(0xFF38D430)
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (summary != null)
                      Text(
                        summary,
                        style: const TextStyle(
                          color: Color(0xFF249D31),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if ((field.direccion ?? '').trim().isNotEmpty)
                      Text(
                        field.direccion!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 7),
                    _PichangaCountBadge(count: pichangaCount),
                    if (_priceLabel(field) != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _priceLabel(field)!,
                          style: const TextStyle(
                            color: Color(0xFF38D430),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _priceLabel(FieldModel field) {
    if (field.precioDesdeNum != null) {
      final value = field.precioDesdeNum!;
      return value <= 0
          ? 'GRATIS'
          : 'S/ ${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}';
    }
    final raw = (field.precioDesde ?? '').trim();
    return raw.isEmpty ? null : _rawPriceBadgeText(raw);
  }

  String? _courtSummary(FieldModel field) {
    if (field.canchasCount >= 3) return '${field.canchasCount} canchas';
    if (field.vsFormats.isEmpty) return null;
    return _sortFormats(field.vsFormats).join(' · ');
  }

  Widget _buildSelectedPreview(FieldModel field) {
    final image = (field.urlFoto ?? '').trim();
    final price = _priceLabel(field);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openFieldDetail(field.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        image.isEmpty
                            ? const _FieldPlaceholder()
                            : Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const _FieldPlaceholder(),
                              ),
                        if (price != null)
                          Positioned(
                            left: 5,
                            right: 5,
                            bottom: 5,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                child: Text(
                                  price == 'GRATIS' ? 'Gratis' : 'Desde $price',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if ((field.direccion ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            field.direccion!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FutureBuilder<FieldModel>(
                future: _selectedFieldDetail,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 34,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final courts =
                      snapshot.data?.canchas ?? const <FieldCourtModel>[];
                  if (courts.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Canchas',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 7),
                      SizedBox(
                        height: 66,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: courts.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, index) =>
                              _buildCourtPreview(courts[index]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourtPreview(FieldCourtModel court) {
    final image = (court.urlFoto ?? '').trim();
    final details = [
      court.vsFormat,
      _surfaceTypeLabel(court.surfaceType ?? ''),
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 152,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            height: double.infinity,
            child: image.isEmpty
                ? const _FieldPlaceholder()
                : Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _FieldPlaceholder(),
                  ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  court.nombre ?? 'Cancha',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (details.isNotEmpty)
                  Text(
                    details,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFiltersSheet() async {
    final draftSurfaces = {..._selectedSurfaceTypes};
    final draftFormats = {..._selectedVsFormats};
    final appliedMin = (_parsePrice(_priceMinController.text) ?? 0)
        .clamp(0, 200)
        .toDouble();
    final appliedMax = (_parsePrice(_priceMaxController.text) ?? 200)
        .clamp(0, 200)
        .toDouble();
    var draftPrice = RangeValues(
      appliedMin,
      appliedMax < appliedMin ? 200 : appliedMax,
    );
    var draftContent = _mapContent;
    var draftRange = _pichangaRange;
    var draftCustomRange = _customPichangaRange;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mostrar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'both',
                            icon: Icon(Icons.stadium_outlined),
                            label: Text('Todas las canchas\ny pichangas'),
                          ),
                          ButtonSegment(
                            value: 'pichangas',
                            icon: Icon(Icons.sports_soccer),
                            label: Text('Solo canchas\ncon pichangas'),
                          ),
                        ],
                        selected: {draftContent},
                        onSelectionChanged: (value) =>
                            setSheetState(() => draftContent = value.first),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Pichangas',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      PichangaRangeSelector(
                        selectedValue: draftRange,
                        customLabel: _pichangaRangeLabel(
                          'custom',
                          draftCustomRange,
                        ),
                        onSelected: (value) async {
                          if (value == 'custom') {
                            final selected = await showDateRangePicker(
                              context: context,
                              initialDateRange: draftCustomRange,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (selected == null) return;
                            draftCustomRange = selected;
                          }
                          setSheetState(() => draftRange = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Buscar',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (draftContent != 'pichangas')
                        const Text(
                          'Tipo de superficie',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      if (draftContent != 'pichangas')
                        _buildChoiceGrid(
                          columns: 3,
                          height: 62,
                          children: _surfaceTypeOptions
                              .map(
                                (type) => CompactFilterChoice(
                                  label: _surfaceTypeLabel(type),
                                  selected: draftSurfaces.contains(type),
                                  icon: _surfaceTypeIcon(type),
                                  controlKey: Key('map-filter-surface-$type'),
                                  fontSize: 10.5,
                                  maxLines: 2,
                                  onTap: () => setSheetState(() {
                                    final selected = draftSurfaces.contains(
                                      type,
                                    );
                                    if (selected) {
                                      draftSurfaces.remove(type);
                                    } else {
                                      draftSurfaces.add(type);
                                    }
                                  }),
                                ),
                              )
                              .toList(),
                        ),
                      if (draftContent != 'pichangas')
                        const SizedBox(height: 12),
                      if (draftContent != 'pichangas')
                        const Text(
                          'Formato',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      _buildChoiceGrid(
                        columns: 5,
                        height: 40,
                        children: ['5v5', '6v6', '7v7', '9v9', '11v11']
                            .map(
                              (format) => CompactFilterChoice(
                                label: format,
                                selected: draftFormats.contains(format),
                                controlKey: Key('map-filter-format-$format'),
                                fontSize: 11,
                                onTap: () => setSheetState(() {
                                  final selected = draftFormats.contains(
                                    format,
                                  );
                                  if (selected) {
                                    draftFormats.remove(format);
                                  } else {
                                    draftFormats.add(format);
                                  }
                                }),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Precio por hora',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (draftContent != 'pichangas')
                        const SizedBox(height: 4),
                      if (draftContent != 'pichangas')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('S/ ${_formatPrice(draftPrice.start)}'),
                            Text(
                              draftPrice.end >= 200
                                  ? 'S/ 200+'
                                  : 'S/ ${_formatPrice(draftPrice.end)}',
                            ),
                          ],
                        ),
                      if (draftContent != 'pichangas')
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF38D430),
                            inactiveTrackColor: const Color(0xFF344139),
                            thumbColor: Colors.white,
                            overlayColor: const Color(
                              0xFF38D430,
                            ).withValues(alpha: 0.18),
                          ),
                          child: RangeSlider(
                            values: draftPrice,
                            min: 0,
                            max: 200,
                            divisions: 20,
                            onChanged: (value) =>
                                setSheetState(() => draftPrice = value),
                          ),
                        ),
                      if (draftContent != 'pichangas')
                        _buildChoiceGrid(
                          columns: 4,
                          height: 40,
                          children: [
                            _pricePreset(
                              '0 - 60',
                              const RangeValues(0, 60),
                              draftPrice,
                              setSheetState,
                              (value) => draftPrice = value,
                            ),
                            _pricePreset(
                              '60 - 100',
                              const RangeValues(60, 100),
                              draftPrice,
                              setSheetState,
                              (value) => draftPrice = value,
                            ),
                            _pricePreset(
                              '100 - 200',
                              const RangeValues(100, 200),
                              draftPrice,
                              setSheetState,
                              (value) => draftPrice = value,
                            ),
                            _pricePreset(
                              '200+',
                              const RangeValues(200, 200),
                              draftPrice,
                              setSheetState,
                              (value) => draftPrice = value,
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                setState(() {
                                  _mapContent = draftContent;
                                  _pichangaRange = draftRange;
                                  _customPichangaRange = draftCustomRange;
                                  _pichangasFuture = _loadMapPichangas();
                                });
                                _commitFilters(
                                  draftSurfaces,
                                  draftFormats,
                                  draftPrice,
                                );
                              },
                              child: const Text('Aplicar filtros'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                _clearFilters();
                              },
                              child: const Text('Limpiar filtros'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _commitFilters(
    Set<String> surfaces,
    Set<String> formats,
    RangeValues price,
  ) {
    _selectedSurfaceTypes
      ..clear()
      ..addAll(surfaces);
    _selectedVsFormats
      ..clear()
      ..addAll(formats);
    _priceMinController.text = price.start <= 0
        ? ''
        : _formatPrice(price.start);
    _priceMaxController.text = price.end >= 200 ? '' : _formatPrice(price.end);
    _applyFilters();
  }

  Future<List<Map<String, dynamic>>> _loadMapPichangas() => ref
      .read(pichangasRepositoryProvider)
      .mapItems(
        range: _pichangaRange,
        from: _customPichangaRange?.start,
        to: _customPichangaRange?.end,
      );

  String _pichangaRangeLabel(String range, DateTimeRange? customRange) {
    if (range == 'today') return 'Hoy';
    if (range == 'today_tomorrow') return 'Hoy y mañana';
    if (customRange == null) return 'Rango personalizado';
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final start = customRange.start;
    final end = customRange.end;
    if (start.month == end.month) {
      return '${start.day}–${end.day} ${months[end.month - 1]}';
    }
    return '${start.day} ${months[start.month - 1]}–${end.day} ${months[end.month - 1]}';
  }

  Widget _pricePreset(
    String label,
    RangeValues value,
    RangeValues current,
    StateSetter setSheetState,
    ValueChanged<RangeValues> onSelected,
  ) {
    return CompactFilterChoice(
      label: 'S/ $label',
      selected: current == value,
      controlKey: Key('map-filter-price-$label'),
      fontSize: 10,
      onTap: () => setSheetState(() => onSelected(value)),
    );
  }

  String _formatPrice(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);

  Future<void> _applyFilters() async {
    final requestId = ++_filterRequestId;
    final min = _parsePrice(_priceMinController.text);
    final max = _parsePrice(_priceMaxController.text);
    if (min != null && max != null && min > max) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El precio mínimo no puede ser mayor al máximo.'),
        ),
      );
      return;
    }

    _fitResultsAfterApplyingFilters = true;
    _clearSelectedField();
    ref.read(mapFilterStateProvider.notifier).state = MapFilterState(
      priceMin: min,
      priceMax: max,
      surfaceTypes: _selectedSurfaceTypes.toList(),
      vsFormats: _selectedVsFormats.toList(),
    );

    // Esperamos la respuesta ya filtrada para encuadrar exactamente esos
    // polideportivos, sin depender de que ocurra otro renderizado del mapa.
    try {
      ref.invalidate(fieldsProvider);
      final fields = await ref.read(fieldsProvider.future);
      if (!mounted || requestId != _filterRequestId) return;
      final validFields = fields
          .where(
            (field) =>
                field.x != 0 &&
                field.y != 0 &&
                field.x.abs() <= 90 &&
                field.y.abs() <= 180,
          )
          .toList();
      _lastMapFields = validFields;
      if (validFields.isNotEmpty) {
        // The provider can finish before Google Maps has laid out its new
        // viewport. Wait for that frame so bounds are calculated from the
        // actual map size, not the previous partial layout.
        await WidgetsBinding.instance.endOfFrame;
        await _fitCameraToResults(validFields);
      } else {
        _fitResultsAfterApplyingFilters = false;
      }
    } catch (_) {
      // El estado de error del proveedor ya informa el fallo de la consulta.
      _fitResultsAfterApplyingFilters = false;
    }
  }

  void _clearFilters() {
    // Clearing filters intentionally preserves the camera the user chose.
    _filterRequestId++;
    _fitResultsAfterApplyingFilters = false;
    _priceMinController.clear();
    _priceMaxController.clear();
    setState(() {
      _selectedSurfaceTypes.clear();
      _selectedVsFormats.clear();
      _mapContent = 'both';
      _pichangaRange = 'custom';
      final today = DateUtils.dateOnly(DateTime.now());
      _customPichangaRange = DateTimeRange(
        start: today,
        end: today.add(const Duration(days: 6)),
      );
      _pichangasFuture = _loadMapPichangas();
      _selectedField = null;
      _selectedFieldDetail = null;
      _selectedPichangaId = null;
      _showSelectedFieldPreview = false;
    });
    ref.read(mapFilterStateProvider.notifier).state = const MapFilterState();
  }

  void _scheduleResultsFit(List<FieldModel> fields) {
    if (!_fitResultsAfterApplyingFilters) return;
    if (fields.isEmpty) {
      _fitResultsAfterApplyingFilters = false;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_fitCameraToResults(fields));
      }
    });
  }

  Future<void> _fitCameraToResults(List<FieldModel> fields) async {
    if (!_fitResultsAfterApplyingFilters) return;
    await WidgetsBinding.instance.endOfFrame;
    final controller = _mapController;
    if (controller == null) return;

    try {
      if (fields.length == 1) {
        final field = fields.single;
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(field.x, field.y), 15),
        );
      } else {
        final latitudes = fields.map((field) => field.x).toList()..sort();
        final longitudes = fields.map((field) => field.y).toList()..sort();
        final southwest = LatLng(latitudes.first, longitudes.first);
        final northeast = LatLng(latitudes.last, longitudes.last);

        // Bounds rejects a zero-area rectangle. If all results share one
        // coordinate, center that point instead of losing the fit request.
        if (southwest == northeast) {
          await controller.animateCamera(
            CameraUpdate.newLatLngZoom(southwest, 15),
          );
        } else {
          await controller.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(southwest: southwest, northeast: northeast),
              52,
            ),
          );
        }
      }
      _fitResultsAfterApplyingFilters = false;
    } on PlatformException {
      // Keep the request pending so onMapCreated/onCameraIdle can retry once
      // Google Maps has completed its layout.
    }
  }

  double? _parsePrice(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  void _ensureMarkersFuture(
    List<FieldModel> fields,
    Set<int> pichangaFieldIds,
  ) {
    final pulseStep = _selectedField != null
        ? (_pulseController.value * 8).round()
        : 0;
    final userLocKey = _currentUserLocation != null
        ? '${_currentUserLocation!.latitude.toStringAsFixed(4)},${_currentUserLocation!.longitude.toStringAsFixed(4)}'
        : 'none';
    final key = fields
        .map(
          (field) =>
              '${field.id}:${field.x.toStringAsFixed(6)}:${field.y.toStringAsFixed(6)}:${_priceBadgeText(field)}:${pichangaFieldIds.contains(field.id)}:${_selectedField?.id == field.id}:${_selectedPichangaId != null}',
        )
        .join('|');
    final clusteredKey =
        '$key:zoom=${_cameraZoom.toStringAsFixed(2)}:userLoc=$userLocKey:pulse=$pulseStep:revision=$_cameraRevision';

    if (_markersFuture == null || clusteredKey != _lastMarkersKey) {
      _lastMarkersKey = clusteredKey;
      _markersFuture = _buildMarkers(fields, pichangaFieldIds);
    }
  }

  Future<Set<Marker>> _buildMarkers(
    List<FieldModel> fields,
    Set<int> pichangaFieldIds,
  ) async {
    final markers = <Marker>{};

    for (final cluster in _clusterer.cluster(fields, _cameraZoom)) {
      if (cluster.isCluster) {
        markers.add(
          Marker(
            markerId: MarkerId('cluster-${cluster.id}'),
            position: LatLng(cluster.latitude, cluster.longitude),
            icon: await _clusterIconForCount(
              cluster.fields.length,
              hasPichangas: cluster.fields.any(
                (field) => pichangaFieldIds.contains(field.id),
              ),
            ),
            zIndexInt: 1,
            onTap: () => _zoomIntoCluster(cluster),
          ),
        );
        continue;
      }

      final field = cluster.fields.single;
      final isSelected = _selectedField?.id == field.id;
      final hasPichangas = pichangaFieldIds.contains(field.id);
      final label = _priceBadgeText(field);
      final icon = await _iconForLabel(
        label,
        selected: isSelected,
        hasPichangas: hasPichangas,
        pulseRed: _selectedPichangaId != null || hasPichangas,
        pulseProgress: isSelected ? _pulseController.value : 0.0,
      );

      markers.add(
        Marker(
          markerId: MarkerId('field-${field.id}'),
          position: LatLng(field.x, field.y),
          icon: icon,
          zIndexInt: isSelected ? 100 : 1,
          onTap: () {
            setState(() => _selectedPichangaId = null);
            _selectField(field);
          },
        ),
      );
    }

    // User location marker with highest zIndexInt (999) so it always renders on top of all sports badges!
    if (_myLocationEnabled && _currentUserLocation != null) {
      final userIcon = await _getUserLocationIcon();
      markers.add(
        Marker(
          markerId: const MarkerId('user-current-location'),
          position: _currentUserLocation!,
          zIndexInt: 999,
          anchor: const Offset(0.5, 0.5),
          icon: userIcon,
        ),
      );
    }

    return markers;
  }

  Future<BitmapDescriptor> _getUserLocationIcon() async {
    if (_userLocationIconCache != null) return _userLocationIconCache!;

    const size = 56.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = const Offset(size / 2, size / 2);

    // Outer subtle translucent blue aura
    final auraPaint = Paint()..color = const Color(0x442196F3);
    canvas.drawCircle(center, size / 2 - 2, auraPaint);

    // Outer glowing blue stroke
    final outerRing = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, size / 2 - 3, outerRing);

    // Solid white circle
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 13, whitePaint);

    // Inner Royal Blue dot
    final bluePaint = Paint()..color = const Color(0xFF1976D2);
    canvas.drawCircle(center, 9.5, bluePaint);

    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final icon = BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      imagePixelRatio: 2.2,
    );
    _userLocationIconCache = icon;
    return icon;
  }

  Future<BitmapDescriptor> _clusterIconForCount(
    int count, {
    required bool hasPichangas,
  }) async {
    final cacheKey = 'cluster:$count:$hasPichangas';
    final cached = _markerIconCache[cacheKey];
    if (cached != null) return cached;

    const size = 74.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = const Offset(size / 2, size / 2);
    final circle = Paint()..color = const Color(0xFF1F8F47);
    canvas.drawCircle(center, size / 2 - 3, circle);
    canvas.drawCircle(
      center,
      size / 2 - 3,
      Paint()
        ..color = hasPichangas
            ? const Color(0xFFD9453D)
            : const Color(0xFF8FE887)
        ..style = PaintingStyle.stroke
        ..strokeWidth = hasPichangas ? 4 : 3,
    );

    // A small football pitch distinguishes a group from an individual field.
    final pitch = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const pitchRect = Rect.fromLTWH(23, 17, 28, 20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pitchRect, const Radius.circular(3)),
      pitch,
    );
    canvas.drawLine(const Offset(37, 17), const Offset(37, 37), pitch);
    canvas.drawCircle(const Offset(37, 27), 3.5, pitch);
    canvas.drawRect(const Rect.fromLTWH(23, 22, 5, 10), pitch);
    canvas.drawRect(const Rect.fromLTWH(46, 22, 5, 10), pitch);

    final painter = TextPainter(
      text: TextSpan(
        text: '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset((size - painter.width) / 2, 45));

    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final icon = BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      imagePixelRatio: 2.2,
    );
    _markerIconCache[cacheKey] = icon;
    return icon;
  }

  Future<void> _zoomIntoCluster(FieldCluster cluster) async {
    final controller = _mapController;
    if (controller == null) return;

    final latitudes = cluster.fields.map((field) => field.x).toList();
    final longitudes = cluster.fields.map((field) => field.y).toList();
    latitudes.sort();
    longitudes.sort();
    final south = latitudes.first;
    final north = latitudes.last;
    final west = longitudes.first;
    final east = longitudes.last;

    if ((north - south).abs() < 0.00001 && (east - west).abs() < 0.00001) {
      final currentZoom = await controller.getZoomLevel();
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(cluster.latitude, cluster.longitude),
          (currentZoom + 2).clamp(0, 20).toDouble(),
        ),
      );
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        72,
      ),
    );
  }

  Future<BitmapDescriptor> _iconForLabel(
    String label, {
    required bool selected,
    required bool hasPichangas,
    required bool pulseRed,
    double pulseProgress = 0.0,
  }) async {
    final step = selected ? (pulseProgress * 8).round() : 0;
    final cacheKey = '$label:$selected:$hasPichangas:$pulseRed:$step';
    final cached = _markerIconCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final icon = await _buildBadgeMarkerIcon(
      label,
      selected: selected,
      hasPichangas: hasPichangas,
      pulseRed: pulseRed,
      pulseProgress: pulseProgress,
    );
    _markerIconCache[cacheKey] = icon;
    return icon;
  }

  Future<BitmapDescriptor> _buildBadgeMarkerIcon(
    String text, {
    required bool selected,
    required bool hasPichangas,
    required bool pulseRed,
    double pulseProgress = 0.0,
  }) async {
    const horizontalPadding = 18.0;
    const verticalPadding = 10.0;
    const radius = 22.0;

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      textAlign: TextAlign.center,
    )..layout();

    final baseWidth = painter.width + horizontalPadding * 2;
    final baseHeight = painter.height + verticalPadding * 2;
    final margin = selected ? 18.0 : 0.0;
    final width = baseWidth + margin * 2;
    final height = baseHeight + margin * 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(margin, margin, baseWidth, baseHeight);

    if (selected) {
      final pulseColor = pulseRed
          ? const Color(0xFFFF5148)
          : const Color(0xFF38D430);
      final haloExpand = 3.0 + 10.0 * pulseProgress;
      final haloAlpha = (0.5 - pulseProgress * 0.35).clamp(0.0, 1.0);
      final haloPaint = Paint()
        ..color = pulseColor.withValues(alpha: haloAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0 + 8.0 * pulseProgress;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.inflate(haloExpand),
          Radius.circular(radius + haloExpand),
        ),
        haloPaint,
      );
    }

    final fillPaint = Paint()..color = const Color(0xFF1F8F47);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(radius)),
      fillPaint,
    );

    final strokeWidth = selected
        ? (7.0 + 4.0 * pulseProgress)
        : (hasPichangas ? 4.0 : 2.0);
    final strokeColor = selected
        ? Color.lerp(
            pulseRed ? const Color(0xFFFF5148) : const Color(0xFF38D430),
            pulseRed ? const Color(0xFFFFB4AF) : const Color(0xFFB4FFB0),
            pulseProgress,
          )!
        : hasPichangas
        ? const Color(0xFFD9453D)
        : Colors.white.withValues(alpha: 0.18);

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(radius)),
      strokePaint,
    );

    painter.paint(
      canvas,
      Offset(
        margin + (baseWidth - painter.width) / 2,
        margin + (baseHeight - painter.height) / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
      width.ceil(),
      height.ceil(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      imagePixelRatio: 2.2,
    );
  }

  String _priceBadgeText(FieldModel field) {
    final priceNum = field.precioDesdeNum;
    final priceLabel = priceNum != null
        ? (priceNum <= 0
              ? 'GRATIS'
              : 'S/ ${priceNum % 1 == 0 ? priceNum.toStringAsFixed(0) : priceNum.toStringAsFixed(1)}')
        : _rawPriceBadgeText(field.precioDesde);
    final summary = _courtSummary(field);
    return summary == null ? priceLabel : '$priceLabel\n$summary';
  }

  String _rawPriceBadgeText(String? price) {
    final raw = (price ?? '').trim();
    if (raw.isEmpty) {
      return 'S/ ?';
    }
    final normalized = raw
        .toLowerCase()
        .replaceAll('s/', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');
    if (normalized == 'gratis' || double.tryParse(normalized) == 0) {
      return 'GRATIS';
    }
    return raw.startsWith('S/') ? raw : 'S/ $raw';
  }

  List<String> _sortFormats(List<String> formats) {
    final unique = formats.toSet().toList();
    unique.sort((a, b) {
      final aPlayers = int.tryParse(a.split('v').first) ?? 0;
      final bPlayers = int.tryParse(b.split('v').first) ?? 0;
      return aPlayers.compareTo(bPlayers);
    });
    return unique;
  }

  void _handleCameraIdle() {
    if (!mounted) return;

    final selectedIsGrouped =
        _selectedField != null &&
        _clusterer
            .cluster(_lastMapFields, _cameraZoom)
            .any(
              (cluster) =>
                  cluster.isCluster &&
                  cluster.fields.any((field) => field.id == _selectedField!.id),
            );
    setState(() {
      _cameraRevision++;
      if (selectedIsGrouped) {
        _selectedField = null;
        _selectedFieldDetail = null;
        _selectedPichangaId = null;
        _showSelectedFieldPreview = false;
      }
    });
  }

  Future<void> _selectMapPichanga(Map<String, dynamic> item) async {
    final fieldId =
        (item['field_id'] as num?)?.toInt() ??
        int.tryParse(item['field_id']?.toString() ?? '');
    final pichangaId =
        (item['id'] as num?)?.toInt() ??
        int.tryParse(item['id']?.toString() ?? '');
    if (fieldId == null || pichangaId == null) return;
    final matches = _lastMapFields.where((field) => field.id == fieldId);
    if (matches.isEmpty) return;
    final field = matches.first;

    setState(() => _selectedPichangaId = pichangaId);
    _selectField(field, showPreview: false);
    final controller = _mapController;
    if (controller != null) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(field.x, field.y), 15),
      );
    }
  }

  void _selectField(FieldModel field, {bool showPreview = true}) {
    setState(() {
      _selectedField = field;
      _showSelectedFieldPreview = showPreview;
      _selectedFieldDetail = showPreview
          ? ref.read(fieldsRepositoryProvider).detail(field.id)
          : null;
    });
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _clearSelectedField() {
    setState(() {
      _selectedField = null;
      _selectedFieldDetail = null;
      _selectedPichangaId = null;
      _showSelectedFieldPreview = false;
    });
    if (_pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  Future<void> _restoreLocationLayer() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      _startLocationUpdates();
      if (_didAutoCenterOnLocation) return;

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        if (!mounted) return;
        _didAutoCenterOnLocation = true;
        final latLng = LatLng(position.latitude, position.longitude);
        setState(() => _currentUserLocation = latLng);
        await _moveCameraToUserLocation(latLng);
      } catch (_) {
        // The map remains on its default area when the device has no location.
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_fitResultsAfterApplyingFilters && _lastMapFields.isNotEmpty) {
      unawaited(_fitCameraToResults(_lastMapFields));
    }
    final pendingLocation = _pendingInitialUserLocation;
    if (pendingLocation == null) return;

    _pendingInitialUserLocation = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_moveCameraToUserLocation(pendingLocation));
      }
    });
  }

  Future<void> _moveCameraToUserLocation(LatLng location) async {
    setState(() => _currentUserLocation = location);
    final controller = _mapController;
    if (controller == null) {
      _pendingInitialUserLocation = location;
      return;
    }

    await controller.animateCamera(CameraUpdate.newLatLngZoom(location, 11.5));
  }

  Future<void> _centerOnMyLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationMessage(
        'Activa la ubicación del dispositivo para ver tu posición.',
        openLocationSettings: true,
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showLocationMessage('Necesitamos tu ubicación para centrar el mapa.');
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      _showLocationMessage(
        'La ubicación está bloqueada para Fulbii.',
        openAppSettings: true,
      );
      return;
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      _showLocationMessage('No se pudo habilitar el permiso de ubicación.');
      return;
    }

    try {
      _startLocationUpdates();
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() => _currentUserLocation = latLng);
      await _moveCameraToUserLocation(latLng);
    } on LocationServiceDisabledException {
      _showLocationMessage(
        'Activa la ubicación del dispositivo para ver tu posición.',
        openLocationSettings: true,
      );
    } catch (_) {
      _showLocationMessage(
        'No se pudo obtener tu ubicación. Inténtalo otra vez.',
      );
    }
  }

  void _startLocationUpdates() {
    if (_locationSubscription != null) return;
    if (!mounted) return;

    setState(() => _myLocationEnabled = true);
    _locationSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen(
          (position) {
            if (!mounted) return;
            final loc = LatLng(position.latitude, position.longitude);
            if (_currentUserLocation != loc) {
              setState(() => _currentUserLocation = loc);
            }
          },
          onError: (_) {
            _locationSubscription?.cancel();
            _locationSubscription = null;
            if (mounted) {
              setState(() => _myLocationEnabled = false);
            }
          },
        );
  }

  void _showLocationMessage(
    String message, {
    bool openLocationSettings = false,
    bool openAppSettings = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: (openLocationSettings || openAppSettings)
            ? SnackBarAction(
                label: 'Ajustes',
                onPressed: () {
                  if (openLocationSettings) {
                    Geolocator.openLocationSettings();
                  } else {
                    Geolocator.openAppSettings();
                  }
                },
              )
            : null,
      ),
    );
  }

  String _surfaceTypeLabel(String value) {
    switch (value) {
      case 'losa':
        return 'Losa';
      case 'sintetico':
        return 'Grass sintético';
      case 'natural':
        return 'Grass natural';
      case 'artificial':
        return 'Grass sintético';
      default:
        return value;
    }
  }

  IconData _surfaceTypeIcon(String value) {
    switch (value) {
      case 'losa':
        return Icons.grid_view_rounded;
      case 'sintetico':
      case 'artificial':
        return Icons.grass_rounded;
      case 'natural':
        return Icons.park_outlined;
      default:
        return Icons.stadium_outlined;
    }
  }

  Future<void> _openFieldDetail(int fieldId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FieldDetailScreen(fieldId: fieldId),
      ),
    );
    if (mounted) {
      if (ref.read(sessionControllerProvider).isAuthenticated) {
        ref.invalidate(favoriteFieldIdsProvider);
      }
    }
  }

  Future<void> _toggleFavorite(int fieldId, bool isFavorite) async {
    if (!await requireSignIn(
      context,
      ref,
      action: 'guardar un polideportivo como favorito',
    )) {
      return;
    }
    final repo = ref.read(profileRepositoryProvider);
    try {
      if (isFavorite) {
        await repo.removeFavoriteField(fieldId);
      } else {
        await repo.addFavoriteField(fieldId);
      }
      ref.invalidate(favoriteFieldIdsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorite
                  ? 'Cancha removida de favoritos.'
                  : 'Cancha agregada a favoritos.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar favorito: $e')),
        );
      }
    }
  }

  Future<void> _openSubmitFieldDialog() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const FieldSubmissionScreen()),
    );
    if (mounted) {
      ref.invalidate(fieldsProvider);
    }
  }
}

/// A compact, text-free summary of the result types currently shown. Keeping
/// it beside the Map/List switch makes the active filter obvious in either
/// view without taking away vertical space from the map.
class _MapContentBadge extends StatelessWidget {
  const _MapContentBadge({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icons = switch (content) {
      'pichangas' => const [Icons.sports_soccer],
      _ => const [Icons.stadium_outlined, Icons.sports_soccer],
    };
    return Semantics(
      label: switch (content) {
        'pichangas' => 'Mostrando solo canchas con pichangas',
        _ => 'Mostrando todas las canchas y pichangas',
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 42, minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < icons.length; index++) ...[
              if (index > 0) const SizedBox(width: 2),
              Icon(icons[index], size: icons.length == 1 ? 21 : 17),
            ],
          ],
        ),
      ),
    );
  }
}

class _PichangaCountBadge extends StatelessWidget {
  const _PichangaCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final hasPichangas = count > 0;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: hasPichangas
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_soccer,
            size: 14,
            color: hasPichangas
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            hasPichangas
                ? '$count ${count == 1 ? 'pichanga' : 'pichangas'}'
                : 'Sin pichangas',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: hasPichangas
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
