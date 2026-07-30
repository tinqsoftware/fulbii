import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../pichangas/presentation/create_pichanga_screen.dart';
import '../../profile/data/profile_repository.dart';
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
    final favoriteIds = ref.watch(fieldDetailFavoriteIdsProvider).valueOrNull;
    final isFavorite = favoriteIds?.contains(field.id) ?? false;
    final price = _priceLabel(field);
    final image = (field.urlFoto ?? '').trim();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 270,
            backgroundColor: const Color(0xFF080C0A),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: isFavorite ? 'Quitar favorito' : 'Agregar favorito',
                onPressed: () => _toggleFavorite(context, ref, isFavorite),
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            field.direccion!,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
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
                  if (field.surfaceTypes.isNotEmpty ||
                      field.vsFormats.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...field.surfaceTypes.map(
                          (value) => _DetailTag(label: _surfaceLabel(value)),
                        ),
                        ...field.vsFormats.map(
                          (value) => _DetailTag(label: value),
                        ),
                      ],
                    ),
                  ],
                  if (field.canchas.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const Text(
                      'Canchas disponibles',
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
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.45,
                      ),
                    ),
                  ],
                  if (_hasText(field.celular)) ...[
                    const SizedBox(height: 28),
                    const Text(
                      'Contacto',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      field.celular!,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openInWaze(context, field),
                          icon: const Icon(Icons.alt_route),
                          label: const Text('Waze'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openInMaps(context, field),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Maps'),
                        ),
                      ),
                    ],
                  ),
                  if (price != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Desde',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: Colors.white60),
                    ),
                    Text(
                      price,
                      style: const TextStyle(
                        color: Color(0xFF38D430),
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                      ),
                    ),
                    const Text(
                      'por hora',
                      style: TextStyle(color: Colors.white60),
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
          decoration: const BoxDecoration(
            color: Color(0xFF101612),
            border: Border(top: BorderSide(color: Color(0xFF26332B))),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CreatePichangaScreen(
                  initialFieldId: field.id,
                  initialAddress: field.direccion,
                ),
              ),
            ),
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
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF18211B),
    child: const Center(
      child: Icon(
        Icons.sports_soccer_outlined,
        size: 60,
        color: Color(0xFF38D430),
      ),
    ),
  );
}

class _DetailTag extends StatelessWidget {
  const _DetailTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF2A9C31)),
      color: const Color(0xFF102416),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF9BE594),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

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

    return Container(
      height: 88,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF111613),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2B3931)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
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
                  Text(details, style: const TextStyle(color: Colors.white70)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

bool _hasText(String? value) => (value ?? '').trim().isNotEmpty;

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
    case 'artificial':
      return 'Grass artificial';
    default:
      return value;
  }
}

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
