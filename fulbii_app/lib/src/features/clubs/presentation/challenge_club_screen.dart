import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../challenges/data/challenges_repository.dart';

class ChallengeClubScreen extends ConsumerStatefulWidget {
  const ChallengeClubScreen({
    required this.targetClubId,
    required this.targetClubName,
    required this.myClubs,
    super.key,
  });

  final int targetClubId;
  final String targetClubName;
  final List<Map<String, dynamic>> myClubs;

  @override
  ConsumerState<ChallengeClubScreen> createState() => _ChallengeClubScreenState();
}

class _ChallengeClubScreenState extends ConsumerState<ChallengeClubScreen> {
  late int _selectedMyClubId;
  int _teamSize = 6;
  String _challengeWindow = 'next_week';
  final TextEditingController _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedMyClubId = int.tryParse(widget.myClubs.first['id'].toString()) ?? 0;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitChallenge() async {
    if (_selectedMyClubId <= 0) return;

    setState(() => _submitting = true);

    try {
      await ref.read(challengesRepositoryProvider).create(
            fromClubId: _selectedMyClubId,
            challengedClubId: widget.targetClubId,
            teamSize: _teamSize,
            challengeWindow: _challengeWindow,
            requestedNote: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Reto enviado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo enviar el reto.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Reto'),
      ),
      body: _submitting
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                // Encabezado
                Text(
                  'Retar a ${widget.targetClubName}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configura los detalles del partido de reto que enviarás al grupo.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 28),

                // Seleccionar Tu Grupo
                Text(
                  '¿Con cuál de tus grupos retarás?',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...widget.myClubs.map((club) {
                  final id = int.tryParse(club['id'].toString()) ?? 0;
                  final isSelected = _selectedMyClubId == id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      elevation: isSelected ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => setState(() => _selectedMyClubId = id),
                        title: Text(
                          (club['nombre'] ?? 'Grupo').toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${club['miembros_count'] ?? 0} integrantes',
                        ),
                        trailing: Radio<int>(
                          value: id,
                          groupValue: _selectedMyClubId,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedMyClubId = val);
                            }
                          },
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Formato de Jugadores (counter vs)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Jugadores por equipo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _teamSize > 4
                              ? () => setState(() => _teamSize--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_teamSize vs $_teamSize',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _teamSize < 11
                              ? () => setState(() => _teamSize++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Ventana temporal del reto
                const Text(
                  'Cuándo jugar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  children: [
                    _buildWindowChip(
                      value: 'next_week',
                      label: 'Siguiente semana',
                      colorScheme: colorScheme,
                    ),
                    _buildWindowChip(
                      value: 'next_fortnight',
                      label: 'Siguiente quincena',
                      colorScheme: colorScheme,
                    ),
                    _buildWindowChip(
                      value: 'next_month',
                      label: 'Siguiente mes',
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Nota / Mensaje opcional
                TextField(
                  controller: _noteController,
                  maxLines: 4,
                  minLines: 2,
                  maxLength: 250,
                  decoration: InputDecoration(
                    labelText: 'Mensaje de reto (opcional)',
                    hintText: 'Ej. ¡Los retamos a jugar un amistoso este sábado en la tarde!',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // CTA Button
                FilledButton(
                  onPressed: _submitChallenge,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Enviar Reto al Grupo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWindowChip({
    required String value,
    required String label,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _challengeWindow == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _challengeWindow = value);
        }
      },
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
