import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../data/clubs_repository.dart';

class JoinClubByLinkScreen extends ConsumerStatefulWidget {
  const JoinClubByLinkScreen({this.initialCode, super.key});

  final String? initialCode;

  @override
  ConsumerState<JoinClubByLinkScreen> createState() =>
      _JoinClubByLinkScreenState();
}

class _JoinClubByLinkScreenState extends ConsumerState<JoinClubByLinkScreen> {
  final _controller = TextEditingController();
  Map<String, dynamic>? _preview;
  bool _loading = false;
  bool _sending = false;
  bool _canceling = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCode?.trim() ?? '';
    if (initial.isNotEmpty) {
      _controller.text = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) => _previewByCode());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final club = (_preview?['club'] as Map?)?.cast<String, dynamic>();
    final me = (_preview?['me'] as Map?)?.cast<String, dynamic>();
    final clubId = int.tryParse(club?['id']?.toString() ?? '');
    final pendingRequestId = int.tryParse(
      me?['pending_request_id']?.toString() ?? '',
    );
    final isMember = me?['is_member'] == true;
    final hasPending = pendingRequestId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar por link')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Código o link',
              hintText: 'AB12CD34EF56',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _previewByCode,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.visibility_outlined),
            label: const Text('Ver grupo'),
          ),
          if (club != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (club['nombre'] ?? '').toString(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if ((club['descripcion'] ?? '').toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text((club['descripcion'] ?? '').toString()),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      (club['is_visible'] == true)
                          ? 'Grupo visible'
                          : 'Grupo oculto (acceso por link)',
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: (_sending || isMember || hasPending)
                          ? null
                          : _sendRequest,
                      child: Text(
                        isMember
                            ? 'Ya eres miembro'
                            : hasPending
                            ? 'Solicitud pendiente'
                            : 'Solicitar ingreso',
                      ),
                    ),
                    if (hasPending && clubId != null) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _canceling
                            ? null
                            : () => _cancelRequest(
                                clubId: clubId,
                                requestId: pendingRequestId,
                              ),
                        child: const Text('Cancelar solicitud'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _previewByCode() async {
    final code = _extractCode(_controller.text);
    if (code.isEmpty) {
      _showMessage('Ingresa un código o link válido.');
      return;
    }

    setState(() {
      _loading = true;
      _preview = null;
    });

    try {
      final data = await ref
          .read(clubsRepositoryProvider)
          .joinPreviewByCode(code);
      if (!mounted) {
        return;
      }
      setState(() => _preview = data);
    } on ApiError catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _sendRequest() async {
    final code = _extractCode(_controller.text);
    if (code.isEmpty) {
      return;
    }

    setState(() => _sending = true);
    try {
      await ref.read(clubsRepositoryProvider).requestJoinByCode(code);
      if (!mounted) {
        return;
      }
      _showMessage('Solicitud enviada.');
      await _previewByCode();
    } on ApiError catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  String _extractCode(String rawInput) {
    final input = rawInput.trim();
    if (input.isEmpty) {
      return '';
    }

    final parsed = Uri.tryParse(input);
    if (parsed != null) {
      if (parsed.pathSegments.isNotEmpty) {
        final code = parsed.pathSegments.last.trim();
        if (code.isNotEmpty) {
          return code;
        }
      }
      if (parsed.host.toLowerCase() == 'join' &&
          parsed.pathSegments.isNotEmpty) {
        final code = parsed.pathSegments.first.trim();
        if (code.isNotEmpty) {
          return code;
        }
      }
    }

    return input;
  }

  Future<void> _cancelRequest({
    required int clubId,
    required int requestId,
  }) async {
    setState(() => _canceling = true);
    try {
      await ref
          .read(clubsRepositoryProvider)
          .cancelJoinRequest(clubId, requestId);
      if (!mounted) {
        return;
      }
      _showMessage('Solicitud cancelada.');
      await _previewByCode();
    } on ApiError catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) {
        setState(() => _canceling = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
