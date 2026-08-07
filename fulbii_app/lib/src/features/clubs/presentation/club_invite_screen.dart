import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../data/clubs_repository.dart';

class ClubInviteScreen extends ConsumerStatefulWidget {
  const ClubInviteScreen({required this.clubId, super.key});

  final int clubId;

  @override
  ConsumerState<ClubInviteScreen> createState() => _ClubInviteScreenState();
}

class _ClubInviteScreenState extends ConsumerState<ClubInviteScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  String _errorMessage = '';
  Timer? _debounceTimer;
  Map<int, bool> _sendingInvitation = {};

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _searching = false;
        _errorMessage = '';
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _searching = true;
      _errorMessage = '';
    });

    try {
      final results = await ref
          .read(clubsRepositoryProvider)
          .searchUsers(query: query, clubId: widget.clubId);
      
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } on ApiError catch (e) {
      setState(() {
        _errorMessage = e.message;
        _searching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudo realizar la búsqueda.';
        _searching = false;
      });
    }
  }

  Future<void> _sendInvitation(Map<String, dynamic> user) async {
    final userId = int.tryParse(user['id'].toString()) ?? 0;
    if (userId <= 0) return;

    setState(() {
      _sendingInvitation[userId] = true;
    });

    try {
      await ref.read(clubsRepositoryProvider).inviteByNickOrEmail(
            widget.clubId,
            nick: user['nick']?.toString(),
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitación enviada a @${user['nick']}'),
            backgroundColor: Colors.green,
          ),
        );
        // Exclude user from search results since they are invited
        setState(() {
          _searchResults.removeWhere((u) => u['id'] == user['id']);
        });
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
            content: Text('Error al enviar la invitación.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sendingInvitation[userId] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitar Miembro'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Buscar jugador por nick o nombre',
                hintText: 'Ej. jhon_doe',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Expanded(
            child: _searching
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _searchController.text.trim().length < 2
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_search_outlined,
                                  size: 64,
                                  color: colorScheme.outline,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Escribe al menos 2 letras para buscar',
                                  style: TextStyle(color: colorScheme.outline),
                                ),
                              ],
                            ),
                          )
                        : _searchResults.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.search_off_outlined,
                                      size: 64,
                                      color: colorScheme.outline,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No se encontraron jugadores',
                                      style: TextStyle(color: colorScheme.outline),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _searchResults.length,
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (context, index) {
                                  final user = _searchResults[index];
                                  final userId = int.tryParse(user['id'].toString()) ?? 0;
                                  final isInviting = _sendingInvitation[userId] == true;

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: colorScheme.primaryContainer,
                                      child: Text(
                                        user['nick']
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                            '?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      user['name']?.toString() ?? 'Jugador',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text('@${user['nick']}'),
                                    trailing: isInviting
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : FilledButton(
                                            onPressed: () => _sendInvitation(user),
                                            style: FilledButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Text('Invitar'),
                                          ),
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }
}
