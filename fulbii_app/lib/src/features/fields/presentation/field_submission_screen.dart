import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_error.dart';
import '../../auth/presentation/login_required_sheet.dart';
import '../../auth/session_controller.dart';
import '../data/fields_repository.dart';
import '../domain/field_cluster.dart';
import '../domain/field_model.dart';
import 'field_detail_screen.dart';

class FieldSubmissionScreen extends ConsumerStatefulWidget {
  const FieldSubmissionScreen({this.showMyContributions = false, super.key});

  final bool showMyContributions;
  @override
  ConsumerState<FieldSubmissionScreen> createState() =>
      _FieldSubmissionScreenState();
}

class _FieldSubmissionScreenState extends ConsumerState<FieldSubmissionScreen> {
  final _address = TextEditingController();
  final _centerName = TextEditingController();
  final _courtName = TextEditingController();
  final _phone = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  final _width = TextEditingController();
  final _length = TextEditingController();
  Timer? _debounce;
  GoogleMapController? _mapController;
  final FieldClusterer _clusterer = const FieldClusterer();
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  int _step = 0;
  LatLng _pin = const LatLng(-12.0464, -77.0428);
  List<Map<String, dynamic>> _suggestions = const [];
  String? _searchError;
  bool _isSearching = false;
  List<FieldModel> _nearby = const [];
  List<FieldModel> _mapFields = const [];
  FieldModel? _existing;
  // This is only the temporary map selection. It can change while the user
  // explores the map and must never decide the final submission by itself.
  int? _existingPolideportivoId;
  String? _existingPolideportivoName;
  int? _confirmedPolideportivoId;
  String? _confirmedPolideportivoName;
  Future<Set<Marker>>? _markersFuture;
  double _cameraZoom = 15;
  int _searchRevision = 0;
  bool _hasSelectedLocation = false;
  final List<File> _venuePhotos = [];
  final List<File> _courtPhotos = [];
  String _surface = 'sintetico';
  String _capacity = '7';
  bool _addDimensions = false;
  bool _wsp = false;
  bool _loading = false;
  bool _pickingPhotos = false;
  bool _submissionSummaryLoading = false;
  Map<String, dynamic>? _submissionData;

  bool get _hasExistingPolideportivo => _confirmedPolideportivoId != null;
  bool get _isNewPolideportivo => !_hasExistingPolideportivo;
  int get _totalSteps => _isNewPolideportivo ? 4 : 3;
  bool get _isReviewStep => _step == _totalSteps - 1;
  bool get _isCourtStep => _isNewPolideportivo ? _step == 2 : _step == 1;

  bool get _hasMapSelectedPolideportivo => _existingPolideportivoId != null;

  String get _existingPolideportivoLabel =>
      _confirmedPolideportivoName ??
      _existingPolideportivoName ??
      _existing?.nombre ??
      'polideportivo';

  String get _mapPolideportivoLabel =>
      _existingPolideportivoName ?? _existing?.nombre ?? 'polideportivo';

  @override
  void initState() {
    super.initState();
    _loadMapFields();
    _loadNearby();
    _loadSubmissionSummary();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [
      _address,
      _centerName,
      _courtName,
      _phone,
      _price,
      _description,
      _width,
      _length,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = (_submissionData?['summary'] as Map?)
        ?.cast<String, dynamic>();
    final pending = (summary?['pending_submission'] as Map?)
        ?.cast<String, dynamic>();
    final canSubmit = summary?['can_submit'] == true;
    final isUnlimited = summary?['is_unlimited'] == true;
    if (widget.showMyContributions) {
      return _buildContributionsScreen(summary, canSubmit);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar cancha o polideportivo')),
      body: _submissionSummaryLoading
          ? const Center(child: CircularProgressIndicator())
          : pending != null && !isUnlimited
          ? _PendingSubmissionState(
              pending: pending,
              summary: summary ?? const {},
            )
          : summary != null && !canSubmit && !isUnlimited
          ? _MonthlyLimitState(summary: summary)
          : SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: List.generate(
                        _totalSteps,
                        (index) => Expanded(
                          child: Container(
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            color: index <= _step
                                ? const Color(0xFF38D430)
                                : const Color(0xFF344139),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _body(),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          if (_step > 0)
                            OutlinedButton(
                              onPressed: () => setState(() => _step--),
                              child: const Text('Anterior'),
                            ),
                          const Spacer(),
                          FilledButton(
                            onPressed:
                                _loading ||
                                    (_step == 0 && !_canContinueLocation)
                                ? null
                                : _next,
                            child: Text(
                              _isReviewStep
                                  ? isUnlimited
                                        ? 'Publicar cancha'
                                        : 'Enviar solicitud'
                                  : _step == 0
                                  ? !_hasMapSelectedPolideportivo
                                        ? 'Continuar creando polideportivo'
                                        : 'Continuar con $_mapPolideportivoLabel'
                                  : 'Siguiente',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _loadSubmissionSummary() async {
    if (!ref.read(sessionControllerProvider).isAuthenticated) return;
    setState(() => _submissionSummaryLoading = true);
    try {
      final data = await ref
          .read(fieldsRepositoryProvider)
          .myFieldSubmissions();
      if (mounted) setState(() => _submissionData = data);
    } catch (_) {
      // Guests and temporary network failures retain the existing form flow;
      // the server remains the authority when the user submits.
    } finally {
      if (mounted) setState(() => _submissionSummaryLoading = false);
    }
  }

  Widget _buildContributionsScreen(
    Map<String, dynamic>? summary,
    bool canSubmit,
  ) {
    final items = (_submissionData?['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Mis aportes')),
      body: _submissionSummaryLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SubmissionUsageCard(summary: summary ?? const {}),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  const _EmptyContributionsState()
                else
                  ...items.map(_buildContributionTile),
              ],
            ),
      floatingActionButton: canSubmit
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const FieldSubmissionScreen(),
                ),
              ),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Agregar aporte'),
            )
          : null,
    );
  }

  Widget _buildContributionTile(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'pending').toString();
    final approvedFieldId =
        int.tryParse((item['approved_polideportivo_id'] ?? '').toString()) ?? 0;
    final colors = Theme.of(context).colorScheme;
    final color = switch (status) {
      'approved' => colors.primary,
      'rejected' => colors.error,
      _ => colors.tertiary,
    };
    final statusLabel = switch (status) {
      'approved' => 'Aprobada',
      'rejected' => 'Rechazada',
      _ => 'En revisión',
    };
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .16),
          child: Icon(
            status == 'approved' ? Icons.check_rounded : Icons.pending_outlined,
            color: color,
          ),
        ),
        title: Text((item['nombre'] ?? 'Cancha').toString()),
        subtitle: Text(statusLabel),
        trailing: approvedFieldId > 0
            ? const Icon(Icons.chevron_right_rounded)
            : null,
        onTap: approvedFieldId > 0
            ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FieldDetailScreen(fieldId: approvedFieldId),
                ),
              )
            : null,
      ),
    );
  }

  Widget _body() {
    switch (_step) {
      case 0:
        return _locationStep();
      case 1:
        return _hasExistingPolideportivo
            ? _courtDetailsStep()
            : _venueDetailsStep();
      case 2:
        return _hasExistingPolideportivo ? _reviewStep() : _courtDetailsStep();
      default:
        return _reviewStep();
    }
  }

  Widget _locationStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '1. Ubicación',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _address,
        onChanged: _search,
        onSubmitted: (_) => _searchAndSelectFirst(),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          labelText: 'Buscar dirección',
          prefixIcon: IconButton(
            tooltip: 'Buscar dirección',
            icon: const Icon(Icons.search),
            onPressed: _searchAndSelectFirst,
          ),
        ),
      ),
      if (_isSearching)
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: LinearProgressIndicator(minHeight: 2),
        ),
      if (_searchError != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            _searchError!,
            style: const TextStyle(color: Color(0xFFFFB4AB)),
          ),
        ),
      for (final item in _suggestions)
        ListTile(
          title: Text('${item['address']}'),
          subtitle: Text('${item['secondary'] ?? ''}'),
          onTap: () => _selectAddress(item),
        ),
      if (_hasSelectedLocation && _address.text.trim().isNotEmpty) ...[
        const SizedBox(height: 10),
        ActionChip(
          avatar: const Icon(Icons.location_on_outlined, size: 18),
          label: Text(
            'Ubicación seleccionada: ${_address.text}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onPressed: _centerOnPin,
        ),
      ],
      const SizedBox(height: 12),
      SizedBox(
        height: 300,
        child: FutureBuilder<Set<Marker>>(
          future: _markersFuture,
          builder: (context, snapshot) => GoogleMap(
            initialCameraPosition: CameraPosition(target: _pin, zoom: 15),
            onMapCreated: (controller) {
              _mapController = controller;
              _refreshMarkers();
              if (_hasSelectedLocation) {
                unawaited(_focusSelectedLocation(zoom: 16));
              }
            },
            style: Theme.of(context).brightness == Brightness.dark
                ? _darkMapStyle
                : null,
            markers: snapshot.data ?? const <Marker>{},
            myLocationButtonEnabled: false,
            rotateGesturesEnabled: true,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            onCameraMove: (position) => _cameraZoom = position.zoom,
            onCameraIdle: _handleCameraIdle,
            onTap: (_) => _clearSelectedPolideportivo(),
          ),
        ),
      ),
      TextButton.icon(
        onPressed: _useLocation,
        icon: const Icon(Icons.my_location),
        label: const Text('Usar mi ubicación'),
      ),
      if (_existing != null) ...[
        const SizedBox(height: 12),
        _buildSelectedPolideportivoPreview(_existing!),
      ],
    ],
  );

  Widget _venueDetailsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '2. Datos del polideportivo',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 18),
      TextField(
        controller: _centerName,
        decoration: _compactDecoration('Nombre del polideportivo *'),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _address,
        readOnly: true,
        decoration: _compactDecoration(
          'Dirección seleccionada',
          suffixIcon: const Icon(Icons.lock_outline, size: 18),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        onChanged: (value) => setState(() {
          if (value.trim().isEmpty) _wsp = false;
        }),
        decoration: _compactDecoration('Celular (opcional)'),
      ),
      const SizedBox(height: 10),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: const Text('Tiene WhatsApp'),
        subtitle: const Text('Disponible cuando indiques un celular.'),
        value: _wsp,
        onChanged: _phone.text.trim().isEmpty
            ? null
            : (v) => setState(() => _wsp = v),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _description,
        maxLines: 3,
        decoration: _compactDecoration('Descripción (opcional)'),
      ),
      const SizedBox(height: 18),
      _photoGallery(
        title: 'Fotos del polideportivo',
        helper: 'Hasta 5 fotos. La primera será la portada.',
        photos: _venuePhotos,
        limit: 5,
      ),
    ],
  );

  Widget _courtDetailsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${_isNewPolideportivo ? '3' : '2'}. Datos de la cancha',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
      if (_hasExistingPolideportivo) ...[
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.business),
            title: Text(_existingPolideportivoLabel),
            subtitle: const Text('Polideportivo seleccionado'),
            trailing: const Icon(Icons.lock_outline, size: 20),
          ),
        ),
      ],
      const SizedBox(height: 18),
      TextField(
        controller: _courtName,
        decoration: _compactDecoration('Nombre de la cancha *'),
      ),
      const SizedBox(height: 16),
      const Text('Superficie'),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ['sintetico', 'natural', 'losa']
            .map(
              (v) => ChoiceChip(
                label: Text(
                  v == 'sintetico'
                      ? 'Grass sintético'
                      : v == 'natural'
                      ? 'Grass natural'
                      : 'Losa',
                ),
                selected: _surface == v,
                onSelected: (_) => setState(() => _surface = v),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 16),
      const Text('Capacidad'),
      const SizedBox(height: 8),
      Row(
        children: [
          for (final value in ['5', '6', '7', '8', '9', '11']) ...[
            Expanded(child: _capacityOption(value)),
            if (value != '11') const SizedBox(width: 4),
          ],
        ],
      ),
      const SizedBox(height: 8),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: const Text('Agregar tamaño (metros)'),
        value: _addDimensions,
        onChanged: (enabled) => setState(() {
          _addDimensions = enabled;
          if (!enabled) {
            _width.clear();
            _length.clear();
          }
        }),
      ),
      if (_addDimensions) ...[
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _width,
                keyboardType: TextInputType.number,
                decoration: _compactDecoration('Ancho (m)'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _length,
                keyboardType: TextInputType.number,
                decoration: _compactDecoration('Largo (m)'),
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 18),
      _photoGallery(
        title: 'Fotos de la cancha',
        helper: 'Hasta 3 fotos. La primera será la portada.',
        photos: _courtPhotos,
        limit: 3,
      ),
    ],
  );

  InputDecoration _compactDecoration(String label, {Widget? suffixIcon}) =>
      InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      );

  Widget _capacityOption(String value) {
    final selected = _capacity == value;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _capacity = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF38D430) : const Color(0xFF101A14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF38D430) : const Color(0xFF526158),
          ),
        ),
        child: Text(
          '${value}v$value',
          style: TextStyle(
            color: selected ? const Color(0xFF071108) : Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _photoGallery({
    required String title,
    required String helper,
    required List<File> photos,
    required int limit,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(helper, style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 10),
      if (photos.isNotEmpty)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            photos.length,
            (index) => _photoTile(photos, index),
          ),
        ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: photos.length >= limit || _pickingPhotos
                ? null
                : () => _pickPhotos(photos, limit, ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Cámara'),
          ),
          OutlinedButton.icon(
            onPressed: photos.length >= limit || _pickingPhotos
                ? null
                : () => _pickPhotos(photos, limit, ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(_pickingPhotos ? 'Cargando…' : 'Galería'),
          ),
        ],
      ),
    ],
  );

  Widget _photoTile(List<File> photos, int index) => SizedBox(
    width: 116,
    height: 116,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(photos[index], fit: BoxFit.cover),
        ),
        if (index == 0)
          const Positioned(
            left: 4,
            top: 4,
            child: Chip(
              label: Text('Portada', style: TextStyle(fontSize: 10)),
              visualDensity: VisualDensity.compact,
            ),
          ),
        Positioned(
          right: 0,
          top: 0,
          child: IconButton.filled(
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => photos.removeAt(index)),
            icon: const Icon(Icons.close, size: 16),
          ),
        ),
        if (index > 0)
          Positioned(
            left: 0,
            bottom: 0,
            child: IconButton.filled(
              visualDensity: VisualDensity.compact,
              tooltip: 'Hacer portada',
              onPressed: () => setState(() {
                final photo = photos.removeAt(index);
                photos.insert(0, photo);
              }),
              icon: const Icon(Icons.star, size: 16),
            ),
          ),
        if (index > 0)
          Positioned(
            right: 36,
            bottom: 0,
            child: IconButton.filled(
              visualDensity: VisualDensity.compact,
              tooltip: 'Mover antes',
              onPressed: () => setState(() {
                final photo = photos.removeAt(index);
                photos.insert(index - 1, photo);
              }),
              icon: const Icon(Icons.chevron_left, size: 16),
            ),
          ),
        if (index < photos.length - 1)
          Positioned(
            right: 0,
            bottom: 0,
            child: IconButton.filled(
              visualDensity: VisualDensity.compact,
              tooltip: 'Mover después',
              onPressed: () => setState(() {
                final photo = photos.removeAt(index);
                photos.insert(index + 1, photo);
              }),
              icon: const Icon(Icons.chevron_right, size: 16),
            ),
          ),
      ],
    ),
  );

  Widget _reviewStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '4. Revisar y enviar',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 16),
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 150,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: _pin, zoom: 16),
            style: Theme.of(context).brightness == Brightness.dark
                ? _darkMapStyle
                : null,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId('review-location'),
                position: _pin,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
              ),
            },
          ),
        ),
      ),
      const SizedBox(height: 12),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.location_on),
        title: Text(
          _address.text.isEmpty
              ? 'Ubicación seleccionada en mapa'
              : _address.text,
        ),
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.business, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _hasExistingPolideportivo
                      ? _existingPolideportivoLabel
                      : _centerName.text,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              _reviewTypeBadge,
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.sports_soccer),
        title: Text(_courtName.text),
        subtitle: Text('${_capacity}v$_capacity · $_surface'),
      ),
      Text(
        '${_venuePhotos.length} foto(s) del polideportivo · ${_courtPhotos.length} foto(s) de la cancha',
      ),
      const SizedBox(height: 12),
      const Text(
        'Tu aporte será revisado antes de publicarse.',
        style: TextStyle(color: Colors.white70),
      ),
    ],
  );

  Widget get _reviewTypeBadge {
    final existing = _hasExistingPolideportivo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: existing ? const Color(0xFF1C5A42) : const Color(0xFF244F7A),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        existing ? 'Existente' : 'Nuevo',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildSelectedPolideportivoPreview(FieldModel field) {
    final image = (field.urlFoto ?? '').trim();
    final formats = field.vsFormats.join(' · ');
    final count = field.canchasCount;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _centerOnPin,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: image.isEmpty
                    ? const ColoredBox(
                        color: Color(0xFF18211B),
                        child: Icon(
                          Icons.stadium_outlined,
                          color: Color(0xFF38D430),
                        ),
                      )
                    : Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Color(0xFF18211B),
                          child: Icon(
                            Icons.stadium_outlined,
                            color: Color(0xFF38D430),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Polideportivo seleccionado',
                      style: TextStyle(
                        color: Color(0xFF9BE594),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      field.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if ((field.direccion ?? '').trim().isNotEmpty)
                      Text(
                        field.direccion!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60),
                      ),
                    Text(
                      [
                        if (formats.isNotEmpty) formats,
                        if (count > 0) '$count canchas',
                      ].join(' · '),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: Color(0xFF38D430)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadMapFields() async {
    try {
      final fields = await ref.read(fieldsRepositoryProvider).list();
      if (!mounted) return;
      setState(() => _mapFields = fields.where(_hasCoordinates).toList());
      _refreshMarkers();
    } catch (_) {
      // The pin workflow remains available even if the centers cannot load.
    }
  }

  bool _hasCoordinates(FieldModel field) =>
      field.x != 0 &&
      field.y != 0 &&
      field.x >= -90 &&
      field.x <= 90 &&
      field.y >= -180 &&
      field.y <= 180;

  void _refreshMarkers() {
    if (!mounted) return;
    setState(() => _markersFuture = _buildMarkers());
  }

  Future<Set<Marker>> _buildMarkers() async {
    final markers = <Marker>{};

    if (_hasSelectedLocation) {
      markers.add(
        Marker(
          markerId: const MarkerId('draft-location'),
          position: _pin,
          draggable: true,
          zIndexInt: 1000,
          icon: await _markerIcon(
            'draft-location',
            size: 72,
            selected: true,
            label: '',
            pointed: true,
          ),
          onDragEnd: (point) => _movePin(point, focusMap: true),
        ),
      );
    }

    final nearbyIds = _nearby.map((field) => field.id).toSet();
    final fields = [..._mapFields]
      ..sort((a, b) {
        final aPriority = nearbyIds.contains(a.id) ? 0 : 1;
        final bPriority = nearbyIds.contains(b.id) ? 0 : 1;
        return aPriority == bPriority
            ? a.id.compareTo(b.id)
            : aPriority - bPriority;
      });

    for (final cluster in _clusterer.cluster(fields, _cameraZoom)) {
      if (cluster.isCluster) {
        markers.add(
          Marker(
            markerId: MarkerId('cluster-${cluster.id}'),
            position: LatLng(cluster.latitude, cluster.longitude),
            icon: await _clusterIcon(cluster.fields.length),
            anchor: const Offset(0.5, 0.5),
            onTap: () => _zoomIntoCluster(cluster),
          ),
        );
      } else {
        final field = cluster.fields.single;
        markers.add(
          Marker(
            markerId: MarkerId('field-${field.id}'),
            position: LatLng(field.x, field.y),
            icon: await _fieldIcon(selected: _existing?.id == field.id),
            anchor: const Offset(0.5, 0.5),
            onTap: () => _selectPolideportivo(field),
          ),
        );
      }
    }
    return markers;
  }

  Future<BitmapDescriptor> _fieldIcon({required bool selected}) =>
      _markerIcon('field-$selected', size: 62, selected: selected, label: '');

  Future<BitmapDescriptor> _clusterIcon(int count) =>
      _markerIcon('cluster-$count', size: 70, selected: false, label: '$count');

  Future<BitmapDescriptor> _markerIcon(
    String cacheKey, {
    required double size,
    required bool selected,
    required String label,
    bool pointed = false,
  }) async {
    final cached = _markerIconCache[cacheKey];
    if (cached != null) return cached;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, pointed ? size * .39 : size / 2);
    final radius = pointed ? size * .28 : size * .43;
    final fill = Paint()
      ..color = pointed ? const Color(0xFF1976D2) : const Color(0xFF18A957);
    final border = Paint()
      ..color = selected
          ? const Color(0xFFB4F7A9)
          : Colors.white.withValues(alpha: .75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 5 : 3;
    if (pointed) {
      final path = Path()
        ..moveTo(center.dx - radius * .42, center.dy + radius * .68)
        ..lineTo(center.dx, size - 3)
        ..lineTo(center.dx + radius * .42, center.dy + radius * .68)
        ..close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, border);
    }
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, border);
    _drawPitch(canvas, center, radius * 1.08);
    if (label.isNotEmpty) {
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset((size - painter.width) / 2, size * .69));
    }
    final image = await recorder.endRecording().toImage(
      size.ceil(),
      size.ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final icon = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: 2.2,
    );
    _markerIconCache[cacheKey] = icon;
    return icon;
  }

  void _drawPitch(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final rect = Rect.fromCenter(
      center: center,
      width: size,
      height: size * .68,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, rect.top),
      Offset(center.dx, rect.bottom),
      paint,
    );
    canvas.drawCircle(center, size * .13, paint);
  }

  Future<void> _selectPolideportivo(FieldModel field) async {
    _debounce?.cancel();
    _searchRevision++;
    setState(() {
      _existing = field;
      _existingPolideportivoId = field.id;
      _existingPolideportivoName = field.nombre;
      _pin = LatLng(field.x, field.y);
      _hasSelectedLocation = true;
      _address.text = field.direccion?.trim().isNotEmpty == true
          ? field.direccion!
          : field.nombre;
      _suggestions = const [];
      _isSearching = false;
      _searchError = null;
    });
    await _centerOnPin();
    _refreshMarkers();
  }

  void _clearSelectedPolideportivo() {
    if (_existing == null && _existingPolideportivoId == null) return;
    setState(() {
      _existing = null;
      _existingPolideportivoId = null;
      _existingPolideportivoName = null;
    });
    _refreshMarkers();
  }

  Future<void> _centerOnPin() async {
    await _focusSelectedLocation(zoom: _cameraZoom < 15 ? 15 : _cameraZoom);
  }

  Future<void> _focusSelectedLocation({required double zoom}) async {
    final controller = _mapController;
    if (controller == null || !mounted) return;
    await controller.animateCamera(CameraUpdate.newLatLngZoom(_pin, zoom));
  }

  void _handleCameraIdle() {
    _refreshMarkers();
  }

  Future<void> _zoomIntoCluster(FieldCluster cluster) async {
    final controller = _mapController;
    if (controller == null) return;
    final latitudes = cluster.fields.map((field) => field.x).toList()..sort();
    final longitudes = cluster.fields.map((field) => field.y).toList()..sort();
    final south = latitudes.first;
    final north = latitudes.last;
    final west = longitudes.first;
    final east = longitudes.last;
    if ((north - south).abs() < .00001 && (east - west).abs() < .00001) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(cluster.latitude, cluster.longitude),
          (_cameraZoom + 2).clamp(0, 20),
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

  void _search(String value) {
    _debounce?.cancel();
    final revision = ++_searchRevision;
    if (value.trim().length < 3) {
      setState(() {
        _suggestions = const [];
        _searchError = null;
        _isSearching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted ||
          revision != _searchRevision ||
          _address.text.trim() != value.trim()) {
        return;
      }
      setState(() {
        _isSearching = true;
        _searchError = null;
      });
      try {
        final items = await ref
            .read(fieldsRepositoryProvider)
            .addressSuggestions(
              value,
              LatLngBias(_pin.latitude, _pin.longitude),
            );
        if (mounted &&
            revision == _searchRevision &&
            _address.text.trim() == value.trim()) {
          setState(() {
            _suggestions = items;
            _isSearching = false;
            _searchError = items.isEmpty
                ? 'No encontramos direcciones. Prueba con distrito o avenida.'
                : null;
          });
        }
      } on ApiError catch (error) {
        if (mounted && revision == _searchRevision) {
          setState(() {
            _isSearching = false;
            _searchError = error.message;
          });
        }
      } catch (_) {
        if (mounted && revision == _searchRevision) {
          setState(() {
            _isSearching = false;
            _searchError =
                'No se pudo buscar la dirección. Puedes mover el pin manualmente.';
          });
        }
      }
    });
  }

  Future<void> _searchAndSelectFirst() async {
    _debounce?.cancel();
    final revision = ++_searchRevision;
    final query = _address.text.trim();
    if (query.length < 3) {
      setState(
        () => _searchError = 'Escribe al menos 3 caracteres para buscar.',
      );
      return;
    }
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      final items = await ref
          .read(fieldsRepositoryProvider)
          .addressSuggestions(query, LatLngBias(_pin.latitude, _pin.longitude));
      if (!mounted ||
          revision != _searchRevision ||
          _address.text.trim() != query) {
        return;
      }
      if (items.isEmpty) {
        setState(() {
          _isSearching = false;
          _suggestions = const [];
          _searchError =
              'No encontramos direcciones. Prueba con distrito o avenida.';
        });
        return;
      }
      setState(() {
        _isSearching = false;
        _suggestions = items;
      });
      await _selectAddress(items.first);
    } on ApiError catch (error) {
      if (mounted && revision == _searchRevision) {
        setState(() {
          _isSearching = false;
          _searchError = error.message;
        });
      }
    } catch (_) {
      if (mounted && revision == _searchRevision) {
        setState(() {
          _isSearching = false;
          _searchError =
              'No se pudo buscar la dirección. Puedes mover el pin manualmente.';
        });
      }
    }
  }

  Future<void> _selectAddress(Map<String, dynamic> item) async {
    final lat = (item['lat'] as num).toDouble();
    final lng = (item['lng'] as num).toDouble();
    _debounce?.cancel();
    _searchRevision++;
    setState(() {
      _suggestions = const [];
      _isSearching = false;
      _searchError = null;
    });
    await _movePin(
      LatLng(lat, lng),
      selectedAddress: item['address'].toString(),
      focusMap: true,
    );
  }

  Future<void> _movePin(
    LatLng point, {
    String? selectedAddress,
    bool focusMap = false,
  }) async {
    _debounce?.cancel();
    _searchRevision++;
    final snapped = _nearestFieldWithin(point, 3);
    final resolvedPoint = snapped == null
        ? point
        : LatLng(snapped.x, snapped.y);
    final snappedAddress = snapped?.direccion?.trim();
    setState(() {
      _pin = resolvedPoint;
      _hasSelectedLocation = true;
      _existing = snapped;
      _existingPolideportivoId = snapped?.id;
      _existingPolideportivoName = snapped?.nombre;
      _suggestions = const [];
      _isSearching = false;
      _searchError = null;
      if ((snappedAddress ?? '').isNotEmpty) {
        _address.text = snappedAddress!;
      } else if ((selectedAddress ?? '').trim().isNotEmpty) {
        _address.text = selectedAddress!.trim();
      }
    });
    if (focusMap) {
      // Do not wait for reverse geocoding or nearby-centre requests.
      unawaited(_focusSelectedLocation(zoom: 16));
    }
    if ((snappedAddress ?? '').isEmpty &&
        (selectedAddress ?? '').trim().isEmpty) {
      try {
        final item = await ref
            .read(fieldsRepositoryProvider)
            .reverseGeocode(_pin.latitude, _pin.longitude);
        if (mounted && item != null) {
          setState(() {
            _address.text = item['address']?.toString() ?? _address.text;
          });
        }
      } catch (_) {}
    }
    _refreshMarkers();
    await _loadNearby();
  }

  FieldModel? _nearestFieldWithin(LatLng point, double radiusMeters) {
    FieldModel? nearest;
    var shortestDistance = radiusMeters;
    for (final field in _mapFields) {
      final distance = Geolocator.distanceBetween(
        point.latitude,
        point.longitude,
        field.x,
        field.y,
      );
      if (distance <= shortestDistance) {
        nearest = field;
        shortestDistance = distance;
      }
    }
    return nearest;
  }

  Future<void> _loadNearby() async {
    try {
      final items = await ref
          .read(fieldsRepositoryProvider)
          .nearby(_pin.latitude, _pin.longitude);
      if (mounted) {
        setState(() {
          _nearby = items;
        });
      }
      _refreshMarkers();
    } catch (_) {}
  }

  Future<void> _useLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activa la ubicación para usar tu posición actual.'),
          ),
        );
      }
      return;
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permite la ubicación desde Ajustes para centrar el mapa.',
            ),
          ),
        );
      }
      return;
    }
    if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
        await _movePin(LatLng(pos.latitude, pos.longitude), focusMap: true);
      } on TimeoutException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La ubicación tardó demasiado. Inténtalo nuevamente.',
              ),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No pudimos obtener tu ubicación actual.'),
            ),
          );
        }
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Necesitamos permiso de ubicación para centrar el mapa.',
          ),
        ),
      );
    }
  }

  Future<void> _pickPhotos(
    List<File> destination,
    int limit,
    ImageSource source,
  ) async {
    if (_pickingPhotos || destination.length >= limit) return;
    setState(() => _pickingPhotos = true);

    try {
      // Choosing one photo at a time avoids the PHPicker multi-select flow
      // freezing on some iOS simulator versions. The user can add up to the
      // existing limit by tapping Galería again.
      final image = await ImagePicker()
          .pickImage(
            source: source,
            imageQuality: 82,
            maxWidth: 1920,
            maxHeight: 1920,
          )
          .timeout(const Duration(seconds: 45));
      if (image == null) return;

      final compressed = await _compressPhoto(
        image,
      ).timeout(const Duration(seconds: 30));
      if (compressed != null && mounted) {
        setState(() => destination.add(compressed));
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La foto tardó demasiado. Intenta elegir otra imagen.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos abrir o procesar la foto seleccionada.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingPhotos = false);
    }
  }

  Future<File?> _compressPhoto(XFile image) async {
    final original = File(image.path);
    if (await original.length() <= 716800) return original;
    for (final quality in [60, 45]) {
      final target =
          '${Directory.systemTemp.path}/fulbii_${DateTime.now().microsecondsSinceEpoch}_$quality.jpg';
      final output = await FlutterImageCompress.compressAndGetFile(
        image.path,
        target,
        minWidth: 1280,
        minHeight: 1280,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      if (output != null && await output.length() <= 716800) {
        return File(output.path);
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo comprimir la foto a menos de 700 KB.'),
        ),
      );
    }
    return null;
  }

  Future<void> _next() async {
    if (_step == 0) {
      if (!_canContinueLocation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Elige una dirección, usa tu ubicación o ubica el pin en el mapa.',
            ),
          ),
        );
        return;
      }
      // The destination is decided only here. Later map refreshes cannot
      // turn an existing-centre contribution into a new-centre one.
      setState(() {
        _confirmedPolideportivoId = _existingPolideportivoId;
        _confirmedPolideportivoName = _existingPolideportivoName;
        _step++;
      });
      return;
    }
    if (_step == 1 &&
        _isNewPolideportivo &&
        (_centerName.text.trim().isEmpty || _address.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los campos obligatorios.')),
      );
      return;
    }
    if (_isCourtStep && _courtName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica el nombre de la cancha.')),
      );
      return;
    }
    if (!_isReviewStep) {
      setState(() => _step++);
      return;
    }
    setState(() => _loading = true);
    try {
      final existingPolideportivoId = _confirmedPolideportivoId;
      if (_hasExistingPolideportivo &&
          (existingPolideportivoId == null || existingPolideportivoId <= 0)) {
        throw const _ExistingPolideportivoSelectionException();
      }
      if (!ref.read(sessionControllerProvider).isAuthenticated) {
        final signedIn = await requireSignIn(
          context,
          ref,
          action: 'enviar tu aporte de cancha',
        );
        if (!signedIn) return;
      }
      final result = await ref
          .read(fieldsRepositoryProvider)
          .submitField(
            nombre: _hasExistingPolideportivo
                ? _existingPolideportivoLabel
                : _centerName.text.trim(),
            submissionType: existingPolideportivoId == null
                ? 'new_polideportivo'
                : 'existing_polideportivo',
            existingPolideportivoId: existingPolideportivoId,
            canchaNombre: _courtName.text.trim(),
            canchaEquiposvs: _capacity,
            canchaTipoSuperficie: _surface,
            direccion: _address.text.trim(),
            x: _pin.latitude,
            y: _pin.longitude,
            celular: _hasExistingPolideportivo ? '' : _phone.text.trim(),
            wsp: _hasExistingPolideportivo ? false : _wsp,
            descripcion: _hasExistingPolideportivo
                ? ''
                : _description.text.trim(),
            canchaAncho: _addDimensions ? _width.text.trim() : '',
            canchaLargo: _addDimensions ? _length.text.trim() : '',
            venuePhotoFiles: _isNewPolideportivo ? _venuePhotos : const [],
            courtPhotoFiles: _courtPhotos,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (result['message'] ?? 'Solicitud enviada a moderación.')
                  .toString(),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } on _ExistingPolideportivoSelectionException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Selecciona el polideportivo nuevamente antes de enviar.',
            ),
          ),
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _canContinueLocation =>
      _hasSelectedLocation && _address.text.trim().isNotEmpty;
}

class _ExistingPolideportivoSelectionException implements Exception {
  const _ExistingPolideportivoSelectionException();
}

class _SubmissionUsageCard extends StatelessWidget {
  const _SubmissionUsageCard({required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final used = int.tryParse((summary['monthly_used'] ?? 0).toString()) ?? 0;
    final unlimited = summary['is_unlimited'] == true;
    final limit = int.tryParse((summary['monthly_limit'] ?? 3).toString()) ?? 3;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_location_alt_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              unlimited
                  ? '$used aportes publicados este mes · sin límite de admin'
                  : '$used de $limit aportes enviados este mes',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingSubmissionState extends StatelessWidget {
  const _PendingSubmissionState({required this.pending, required this.summary});

  final Map<String, dynamic> pending;
  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'Ya tienes un aporte en revisión',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                (pending['nombre'] ?? 'Solicitud de cancha').toString(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              _SubmissionUsageCard(summary: summary),
              const SizedBox(height: 12),
              const Text(
                'Podrás enviar otra solicitud cuando esta sea aprobada o rechazada.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthlyLimitState extends StatelessWidget {
  const _MonthlyLimitState({required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_busy_outlined, size: 54),
              const SizedBox(height: 16),
              Text(
                'Alcanzaste el límite mensual',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Puedes enviar hasta tres aportes de cancha por mes calendario.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              _SubmissionUsageCard(summary: summary),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyContributionsState extends StatelessWidget {
  const _EmptyContributionsState();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 72),
    child: Column(
      children: [
        Icon(Icons.add_location_alt_outlined, size: 48),
        SizedBox(height: 12),
        Text('Aún no has enviado aportes de canchas.'),
      ],
    ),
  );
}

// Retained for the native marker artwork fallback used by older cached builds.
// ignore: unused_element
class _FulbiiLocationPin extends StatelessWidget {
  const _FulbiiLocationPin();

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1479E8);
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 38,
          child: Transform.rotate(
            angle: .785398,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: blue,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.stadium_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),
        ),
      ],
    );
  }
}

const _darkMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#0c1510"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#c8d3cc"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0c1510"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#32443b"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#06100b"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#13221a"}]},
  {"featureType":"poi","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","elementType":"labels.icon","stylers":[{"visibility":"off"}]}
]''';
