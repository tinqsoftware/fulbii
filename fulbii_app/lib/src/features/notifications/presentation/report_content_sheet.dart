import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../data/reports_repository.dart';

Future<bool?> showReportContentSheet(
  BuildContext context, {
  required String targetType,
  required int targetId,
  String? contentType,
  int? contentId,
  String title = 'Reportar contenido',
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ReportContentSheet(
      targetType: targetType,
      targetId: targetId,
      contentType: contentType,
      contentId: contentId,
      title: title,
    ),
  );
}

class _ReportContentSheet extends ConsumerStatefulWidget {
  const _ReportContentSheet({
    required this.targetType,
    required this.targetId,
    required this.title,
    this.contentType,
    this.contentId,
  });

  final String targetType;
  final int targetId;
  final String? contentType;
  final int? contentId;
  final String title;

  @override
  ConsumerState<_ReportContentSheet> createState() =>
      _ReportContentSheetState();
}

class _ReportContentSheetState extends ConsumerState<_ReportContentSheet> {
  static const _reasons = <String, String>{
    'abuse': 'Acoso o abuso',
    'spam': 'Spam o publicidad',
    'inappropriate': 'Contenido inapropiado',
    'impersonation': 'Suplantación',
    'other': 'Otro motivo',
  };

  final _description = TextEditingController();
  String _reason = 'inappropriate';
  bool _sending = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      await ref
          .read(reportsRepositoryProvider)
          .create(
            targetType: widget.targetType,
            targetId: widget.targetId,
            reasonCode: _reason,
            description: _description.text,
            contentType: widget.contentType,
            contentId: widget.contentId,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text('Tu reporte será revisado por el equipo de Fulbii.'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              decoration: const InputDecoration(labelText: 'Motivo'),
              items: _reasons.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: _sending
                  ? null
                  : (value) => setState(() => _reason = value ?? _reason),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              enabled: !_sending,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Detalle opcional',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _sending ? null : _submit,
                icon: const Icon(Icons.flag_outlined),
                label: Text(_sending ? 'Enviando...' : 'Enviar reporte'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
