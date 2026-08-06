import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../profile/data/profile_repository.dart';
import '../../auth/presentation/login_required_sheet.dart';
import '../../auth/session_controller.dart';
import '../data/fields_repository.dart';
import '../domain/field_cluster.dart';
import '../domain/field_model.dart';
import 'field_detail_screen.dart';
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

class _FilterChoice extends StatelessWidget {
  const _FilterChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.fontSize = 13,
    this.maxLines = 1,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double fontSize;
  final int maxLines;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? const Color(0xFF1B8F24) : colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF38D430)
                  : colorScheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
            ),
          ),
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

class _MapScreenState extends ConsumerState<MapScreen> {
  final TextEditingController _priceMinController = TextEditingController();
  final TextEditingController _priceMaxController = TextEditingController();

  final Set<String> _selectedSurfaceTypes = <String>{};
  final Set<String> _selectedVsFormats = <String>{};
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  final FieldClusterer _clusterer = const FieldClusterer();
  bool _showList = false;
  FieldModel? _selectedField;
  Future<FieldModel>? _selectedFieldDetail;
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _locationSubscription;
  bool _myLocationEnabled = false;
  bool _didAutoCenterOnLocation = false;
  LatLng? _pendingInitialUserLocation;
  double _cameraZoom = 13;
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
    _restoreLocationLayer();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

        _ensureMarkersFuture(validFields);
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
                OutlinedButton.icon(
                  onPressed: _openFiltersSheet,
                  icon: const Icon(Icons.tune, size: 17),
                  label: Text(
                    activeFilters == 0 ? 'Filtros' : 'Filtros $activeFilters',
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
                IconButton(
                  onPressed: widget.onOpenInbox,
                  icon: const Icon(Icons.notifications_none),
                ),
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
    const spacing = 8.0;
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
    _lastMapFields = fields;
    return Stack(
      children: [
        FutureBuilder<Set<Marker>>(
          future: _markersFuture,
          builder: (context, snapshot) => GoogleMap(
            initialCameraPosition: CameraPosition(target: initial, zoom: 13),
            markers: snapshot.data ?? <Marker>{},
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
        ),
        if (_hasActiveFilters)
          Positioned(
            top: 12,
            left: 12,
            child: _buildResultsBadge(fields.length),
          ),
        if (_selectedField != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: _buildSelectedPreview(_selectedField!),
          ),
        Positioned(
          right: 16,
          bottom: _selectedField == null ? 20 : 244,
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
    if (fields.isEmpty) {
      return const Center(
        child: Text('No hay polideportivos con estos filtros.'),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(fieldsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: fields.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _buildFieldCard(fields[index]),
      ),
    );
  }

  Widget _buildFieldCard(FieldModel field) {
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
    final summary = _courtSummary(field);

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
                    child: image.isEmpty
                        ? const _FieldPlaceholder()
                        : Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _FieldPlaceholder(),
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
                        if (price != null || summary != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            [price, summary].whereType<String>().join('  ·  '),
                            style: TextStyle(
                              color: price != null
                                  ? const Color(0xFF249D31)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buscar',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Tipo de superficie',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      _buildChoiceGrid(
                        columns: 3,
                        height: 64,
                        children: _surfaceTypeOptions
                            .map(
                              (type) => _FilterChoice(
                                label: _surfaceTypeLabel(type),
                                selected: draftSurfaces.contains(type),
                                fontSize: 12,
                                maxLines: 2,
                                onTap: () => setSheetState(() {
                                  final selected = draftSurfaces.contains(type);
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
                      const SizedBox(height: 16),
                      const Text(
                        'Formato',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      _buildChoiceGrid(
                        columns: 5,
                        height: 42,
                        children: ['5v5', '6v6', '7v7', '9v9', '11v11']
                            .map(
                              (format) => _FilterChoice(
                                label: format,
                                selected: draftFormats.contains(format),
                                fontSize: 12,
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
                      const SizedBox(height: 16),
                      const Text(
                        'Precio por hora',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
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
                      _buildChoiceGrid(
                        columns: 4,
                        height: 42,
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
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
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

  Widget _pricePreset(
    String label,
    RangeValues value,
    RangeValues current,
    StateSetter setSheetState,
    ValueChanged<RangeValues> onSelected,
  ) {
    return _FilterChoice(
      label: 'S/ $label',
      selected: current == value,
      fontSize: 10.5,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
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
      _selectedField = null;
      _selectedFieldDetail = null;
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

  void _ensureMarkersFuture(List<FieldModel> fields) {
    final key = fields
        .map(
          (field) =>
              '${field.id}:${field.x.toStringAsFixed(6)}:${field.y.toStringAsFixed(6)}:${_priceBadgeText(field)}:${_selectedField?.id == field.id}',
        )
        .join('|');
    final clusteredKey =
        '$key:zoom=${_cameraZoom.toStringAsFixed(2)}:revision=$_cameraRevision';

    if (_markersFuture == null || clusteredKey != _lastMarkersKey) {
      _lastMarkersKey = clusteredKey;
      _markersFuture = _buildMarkers(fields);
    }
  }

  Future<Set<Marker>> _buildMarkers(List<FieldModel> fields) async {
    final markers = <Marker>{};

    for (final cluster in _clusterer.cluster(fields, _cameraZoom)) {
      if (cluster.isCluster) {
        markers.add(
          Marker(
            markerId: MarkerId('cluster-${cluster.id}'),
            position: LatLng(cluster.latitude, cluster.longitude),
            icon: await _clusterIconForCount(cluster.fields.length),
            onTap: () => _zoomIntoCluster(cluster),
          ),
        );
        continue;
      }

      final field = cluster.fields.single;
      final label = _priceBadgeText(field);
      final icon = await _iconForLabel(
        label,
        selected: _selectedField?.id == field.id,
      );

      markers.add(
        Marker(
          markerId: MarkerId('field-${field.id}'),
          position: LatLng(field.x, field.y),
          icon: icon,
          onTap: () => _selectField(field),
        ),
      );
    }

    return markers;
  }

  Future<BitmapDescriptor> _clusterIconForCount(int count) async {
    final cacheKey = 'cluster:$count';
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
        ..color = const Color(0xFF8FE887)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
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
  }) async {
    final cacheKey = '$label:$selected';
    final cached = _markerIconCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final icon = await _buildBadgeMarkerIcon(label, selected: selected);
    _markerIconCache[cacheKey] = icon;
    return icon;
  }

  Future<BitmapDescriptor> _buildBadgeMarkerIcon(
    String text, {
    required bool selected,
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

    final width = painter.width + horizontalPadding * 2;
    final height = painter.height + verticalPadding * 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, width, height);

    final fillPaint = Paint()..color = const Color(0xFF1F8F47);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(radius)),
      fillPaint,
    );

    final strokePaint = Paint()
      ..color = selected
          ? const Color(0xFF8FE887)
          : Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 4 : 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(radius)),
      strokePaint,
    );

    painter.paint(
      canvas,
      Offset((width - painter.width) / 2, (height - painter.height) / 2),
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
      }
    });
  }

  void _selectField(FieldModel field) {
    setState(() {
      _selectedField = field;
      _selectedFieldDetail = ref
          .read(fieldsRepositoryProvider)
          .detail(field.id);
    });
  }

  void _clearSelectedField() {
    setState(() {
      _selectedField = null;
      _selectedFieldDetail = null;
    });
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
        await _moveCameraToUserLocation(
          LatLng(position.latitude, position.longitude),
        );
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
    final controller = _mapController;
    if (controller == null) {
      _pendingInitialUserLocation = location;
      return;
    }

    await controller.animateCamera(CameraUpdate.newLatLngZoom(location, 15.5));
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
      await _moveCameraToUserLocation(
        LatLng(position.latitude, position.longitude),
      );
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
            distanceFilter: 10,
          ),
        ).listen(
          (_) {
            // Google Maps renders the blue location point from this native stream.
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
