import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/formatters/spanish_date_formatter.dart';
import '../../pichangas/presentation/create_pichanga_screen.dart';
import '../../pichangas/presentation/pichanga_detail_screen.dart';
import '../../profile/data/profile_repository.dart';
import '../../auth/presentation/login_required_sheet.dart';
import '../../auth/session_controller.dart';
import '../data/fields_repository.dart';
import '../domain/field_model.dart';

final fieldDetailProvider = FutureProvider.autoDispose.family<FieldModel, int>(
  (ref, fieldId) => ref.watch(fieldsRepositoryProvider).detail(fieldId),
);

final fieldDetailFavoriteIdsProvider = FutureProvider.autoDispose<Set<int>>((
  ref,
) async {
  final favorites = await ref.watch(profileRepositoryProvider).favoriteFields();
  return favorites
      .whereType<Map>()
      .map((item) => int.tryParse((item['polideportivo_id'] ?? '').toString()))
      .whereType<int>()
      .toSet();
});

class FieldDetailScreen extends ConsumerWidget {
  const FieldDetailScreen({required this.fieldId, super.key});

  final int fieldId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldAsync = ref.watch(fieldDetailProvider(fieldId));
    return fieldAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No se pudo cargar esta cancha: $error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(fieldDetailProvider(fieldId)),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (field) => _FieldDetailBody(field: field),
    );
  }
}

class _FieldDetailBody extends ConsumerWidget {
  const _FieldDetailBody({required this.field});

  final FieldModel field;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final isAuthenticated = session.isAuthenticated;
    final favoriteIds = isAuthenticated
        ? ref.watch(fieldDetailFavoriteIdsProvider).valueOrNull
        : const <int>{};
    final isFavorite = favoriteIds?.contains(field.id) ?? false;
    final price = _priceLabel(field);
    final image = (field.urlFoto ?? '').trim();
    final coverHeight = MediaQuery.sizeOf(context).width / 2.2;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: coverHeight,
            backgroundColor: isDark
                ? const Color(0xFF080C0A)
                : colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            actions: [
              IconButton(
                tooltip: isFavorite ? 'Quitar favorito' : 'Agregar favorito',
                onPressed: () async {
                  if (!await requireSignIn(
                    context,
                    ref,
                    action: 'guardar un polideportivo como favorito',
                  )) {
                    return;
                  }
                  await _toggleFavorite(context, ref, isFavorite);
                },
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: image.isEmpty
                  ? const _FieldImagePlaceholder()
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const _FieldImagePlaceholder(),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 132),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.nombre,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_hasText(field.direccion)) ...[
                    const SizedBox(height: 4),
                    Text(
                      field.direccion!,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _FieldLocationSection(field: field),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (await requireSignIn(
                              context,
                              ref,
                              action: 'abrir Waze',
                            )) {
                              await _openInWaze(context, field);
                            }
                          },
                          icon: const Icon(Icons.alt_route),
                          label: const Text('Waze'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (await requireSignIn(
                              context,
                              ref,
                              action: 'abrir Google Maps',
                            )) {
                              await _openInMaps(context, field);
                            }
                          },
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Google Maps'),
                        ),
                      ),
                    ],
                  ),
                  if (price != null || _hasText(field.celular)) ...[
                    const SizedBox(height: 14),
                    _FieldContactSummary(
                      price: price,
                      phone: field.celular,
                      hasWhatsApp: field.wsp,
                      isAuthenticated: isAuthenticated,
                      onLoginRequired: () => requireSignIn(
                        context,
                        ref,
                        action: 'ver el teléfono del polideportivo',
                      ),
                    ),
                  ],
                  if (field.rating != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      '★ ${field.rating!.toStringAsFixed(1)}${field.ratingCount == null ? '' : ' (${field.ratingCount})'}',
                      style: const TextStyle(
                        color: Color(0xFFFFD21F),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (field.canchas.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const Text(
                      'Canchas',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...field.canchas.map(
                      (court) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CourtDetailCard(court: court),
                      ),
                    ),
                  ],
                  if (field.openPichangas.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const Row(
                      children: [
                        Icon(Icons.sports_soccer_outlined, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Pichangas abiertas',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Disponibles próximamente en este polideportivo.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    ...field.openPichangas.map(
                      (pichanga) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OpenPichangaCard(
                          pichanga: pichanga,
                          onTap: () {
                            final id = switch (pichanga['id']) {
                              int value => value,
                              final Object value =>
                                int.tryParse(value.toString()) ?? 0,
                              _ => 0,
                            };
                            if (id <= 0) return;
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    PichangaDetailScreen(pichangaId: id),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  if (_hasText(field.descripcion)) ...[
                    const SizedBox(height: 28),
                    const Text(
                      'Sobre esta cancha',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      field.descripcion!,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: FilledButton.icon(
            onPressed: () async {
              if (!await requireSignIn(
                context,
                ref,
                action: 'crear una pichanga',
              )) {
                return;
              }
              if (!context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CreatePichangaScreen(
                    initialFieldId: field.id,
                    initialAddress: field.direccion,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.sports_soccer),
            label: const Text('Crear pichanga aquí'),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    bool isFavorite,
  ) async {
    try {
      final repository = ref.read(profileRepositoryProvider);
      if (isFavorite) {
        await repository.removeFavoriteField(field.id);
      } else {
        await repository.addFavoriteField(field.id);
      }
      ref.invalidate(fieldDetailFavoriteIdsProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar favorito: $error')),
        );
      }
    }
  }
}

class _FieldImagePlaceholder extends StatelessWidget {
  const _FieldImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.sports_soccer_outlined,
          size: 60,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _FieldLocationSection extends StatelessWidget {
  const _FieldLocationSection({required this.field});

  final FieldModel field;

  bool get _hasCoordinates =>
      field.x != 0 &&
      field.y != 0 &&
      field.x.abs() <= 90 &&
      field.y.abs() <= 180;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 132,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: _hasCoordinates
          ? IgnorePointer(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(field.x, field.y),
                  zoom: 15.5,
                ),
                style: Theme.of(context).brightness == Brightness.dark
                    ? _detailMapStyle
                    : null,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                markers: {
                  Marker(
                    markerId: MarkerId('field-${field.id}'),
                    position: LatLng(field.x, field.y),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                  ),
                },
              ),
            )
          : ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Center(
                child: Icon(
                  Icons.map_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
    ),
  );
}

class _FieldContactSummary extends StatelessWidget {
  const _FieldContactSummary({
    this.price,
    this.phone,
    required this.hasWhatsApp,
    required this.isAuthenticated,
    required this.onLoginRequired,
  });

  final String? price;
  final String? phone;
  final bool hasWhatsApp;
  final bool isAuthenticated;
  final Future<void> Function() onLoginRequired;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (price != null)
        Expanded(
          child: _ContactMetric(
            icon: Icons.payments_outlined,
            label: 'Precio desde',
            value: price!,
            valueColor: const Color(0xFF38D430),
          ),
        ),
      if (price != null && phone != null) const SizedBox(width: 10),
      if (phone != null)
        Expanded(
          child: _ContactMetric(
            icon: Icons.phone_outlined,
            label: 'Celular',
            value: isAuthenticated ? phone! : _maskPhone(phone!),
            onTap: () {
              if (!isAuthenticated) {
                onLoginRequired();
                return;
              }
              _showContactOptions(
                context,
                phone: phone!,
                hasWhatsApp: hasWhatsApp,
              );
            },
          ),
        ),
    ],
  );
}

class _ContactMetric extends StatelessWidget {
  const _ContactMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: valueColor ?? colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
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
}

class _OpenPichangaCard extends StatelessWidget {
  const _OpenPichangaCard({required this.pichanga, required this.onTap});

  final Map<String, dynamic> pichanga;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = (pichanga['title'] ?? 'Pichanga abierta').toString();
    final court = (pichanga['court_name'] ?? '').toString().trim();
    final confirmed = _toInt(pichanga['confirmed_count']);
    final capacity = _toInt(pichanga['capacity']);
    final spots = _toInt(pichanga['spots_left']);
    final format = _displayMatchFormat(pichanga);
    final summary = [
      court,
      format ?? '',
      '$confirmed/$capacity confirmados',
    ].where((value) => value.isNotEmpty).join(' · ');
    final date = SpanishDateFormatter.pichangaDate(
      pichanga['starts_at']?.toString(),
    );

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey('field-open-pichanga-${pichanga['id']}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.sports_soccer_outlined,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Text(
                    '$spots cupos',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _toInt(dynamic value) => switch (value) {
  int number => number,
  num number => number.toInt(),
  _ => int.tryParse(value?.toString() ?? '') ?? 0,
};

String? _displayMatchFormat(Map<String, dynamic> pichanga) {
  final raw = (pichanga['match_format'] ?? '').toString().trim();
  if (raw.isNotEmpty) return _formatVsLabel(raw);
  final perTeam = _toInt(pichanga['players_per_team']);
  return perTeam > 0 ? '${perTeam}vs$perTeam' : null;
}

String _formatVsLabel(String value) => value.replaceAllMapped(
  RegExp(r'^(\d+)v(?:s)?(\d+)$', caseSensitive: false),
  (match) => '${match.group(1)}vs${match.group(2)}',
);

class _CourtDetailCard extends StatelessWidget {
  const _CourtDetailCard({required this.court});

  final FieldCourtModel court;

  @override
  Widget build(BuildContext context) {
    final image = (court.urlFoto ?? '').trim();
    final details = [
      court.vsFormat,
      _surfaceLabel(court.surfaceType ?? ''),
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');
    final dimensions = _courtDimensions(court);

    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => _CourtDetailDialog(court: court),
        ),
        child: Container(
          height: 96,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 104,
                height: double.infinity,
                child: image.isEmpty
                    ? const _FieldImagePlaceholder()
                    : Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const _FieldImagePlaceholder(),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      court.nombre ?? 'Cancha',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        details,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                    if (dimensions != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        dimensions,
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourtDetailDialog extends StatelessWidget {
  const _CourtDetailDialog({required this.court});

  final FieldCourtModel court;

  @override
  Widget build(BuildContext context) {
    final image = (court.urlFoto ?? '').trim();
    final dimensions = _courtDimensions(court);
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: colorScheme.surface,
      insetPadding: const EdgeInsets.all(22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    court.nombre ?? 'Cancha',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: image.isEmpty
                    ? const _FieldImagePlaceholder()
                    : Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const _FieldImagePlaceholder(),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            _CourtInfoRow(label: 'Capacidad', value: court.vsFormat),
            _CourtInfoRow(
              label: 'Superficie',
              value: _surfaceLabel(court.surfaceType ?? ''),
            ),
            _CourtInfoRow(label: 'Tamaño', value: dimensions),
          ],
        ),
      ),
    );
  }
}

class _CourtInfoRow extends StatelessWidget {
  const _CourtInfoRow({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (!_hasText(value)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

bool _hasText(String? value) => (value ?? '').trim().isNotEmpty;

String _maskPhone(String phone) {
  final visible = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (visible.length <= 3) return '***';
  return '${visible.substring(0, 3)}${'*' * (visible.length - 3)}';
}

String? _priceLabel(FieldModel field) {
  if (field.precioDesdeNum != null) {
    final value = field.precioDesdeNum!;
    return 'S/ ${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}';
  }
  final raw = (field.precioDesde ?? '').trim();
  return raw.isEmpty ? null : (raw.startsWith('S/') ? raw : 'S/ $raw');
}

String _surfaceLabel(String value) {
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

String? _courtDimensions(FieldCourtModel court) {
  final width = court.widthM;
  final length = court.lengthM;
  if (width == null && length == null) return null;
  if (width != null && length != null) {
    return '${_formatMeasure(width)} m x ${_formatMeasure(length)} m';
  }
  if (width != null) return 'Ancho: ${_formatMeasure(width)} m';
  return 'Largo: ${_formatMeasure(length!)} m';
}

String _formatMeasure(double value) =>
    value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);

const _detailMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#101a15"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#c7d1cb"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#101a15"}]},
  {"featureType":"poi","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#385046"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#08110d"}]}
]''';

Future<void> _openInWaze(BuildContext context, FieldModel field) async {
  final appUri = Uri.parse('waze://?ll=${field.x},${field.y}&navigate=yes');
  final webUri = Uri.parse(
    'https://waze.com/ul?ll=${field.x},${field.y}&navigate=yes',
  );
  final uri = await canLaunchUrl(appUri) ? appUri : webUri;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('No se pudo abrir Waze.')));
  }
}

Future<void> _openInMaps(BuildContext context, FieldModel field) async {
  final webUri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=${field.x},${field.y}',
  );
  if (Platform.isIOS) {
    final googleMapsUri = Uri.parse(
      'comgooglemaps://?daddr=${field.x},${field.y}&directionsmode=driving',
    );
    final appleMapsUri = Uri.parse(
      'http://maps.apple.com/?daddr=${field.x},${field.y}&dirflg=d',
    );
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      return;
    }
    if (await canLaunchUrl(appleMapsUri)) {
      await launchUrl(appleMapsUri, mode: LaunchMode.externalApplication);
      return;
    }
  }
  if (await canLaunchUrl(webUri)) {
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  } else if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('No se pudo abrir Maps.')));
  }
}

Future<void> _callPhone(BuildContext context, String phone) async {
  final normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (normalized.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('El número de celular no es válido.')),
    );
    return;
  }

  final uri = Uri(scheme: 'tel', path: normalized);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo iniciar la llamada.')),
    );
  }
}

void _showContactOptions(
  BuildContext context, {
  required String phone,
  required bool hasWhatsApp,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contactar polideportivo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              phone,
              style: TextStyle(
                color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.call_outlined),
              title: const Text('Llamar'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _callPhone(context, phone);
              },
            ),
            if (hasWhatsApp)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.chat_outlined),
                title: const Text('Escribir por WhatsApp'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openWhatsApp(context, phone);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _openWhatsApp(BuildContext context, String phone) async {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('El número de WhatsApp no es válido.')),
    );
    return;
  }

  // Los celulares peruanos se guardan normalmente con nueve dígitos.
  final internationalNumber = digits.length == 9
      ? '51$digits'
      : digits.startsWith('0')
      ? '51${digits.substring(1)}'
      : digits;
  const text =
      'Hola, te hablo desde Fulbii. Quisiera consultar por las canchas.';
  final message = Uri.encodeComponent(text);
  final appUri = Uri.parse(
    'whatsapp://send?phone=$internationalNumber&text=$message',
  );
  final webUri = Uri.parse('https://wa.me/$internationalNumber?text=$message');
  final uri = await canLaunchUrl(appUri) ? appUri : webUri;

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp.')));
  }
}
