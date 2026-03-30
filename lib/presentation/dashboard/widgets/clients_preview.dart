import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/card_decoration.dart';
import '../../../data/repositories/client_repository.dart';

class CompactClientsPreview extends StatefulWidget {
  const CompactClientsPreview({super.key});

  @override
  State<CompactClientsPreview> createState() => _CompactClientsPreviewState();
}

class _CompactClientsPreviewState extends State<CompactClientsPreview> {
  List<dynamic> _clients = [];
  bool _isLoading = true;

  static List<dynamic>? _cached;

  static const _avatarColors = [
    [Color(0xFF7C3AED), Color(0xFF9333EA)],
    [Color(0xFF3B82F6), Color(0xFF2563EB)],
    [Color(0xFFEC4899), Color(0xFFDB2777)],
    [Color(0xFF10B981), Color(0xFF059669)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
  ];

  @override
  void initState() {
    super.initState();
    if (_cached != null) {
      _clients = _cached!;
      _isLoading = false;
    }
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final repo = getIt<ClientRepository>();
      final clients = await repo.getAssignedClients();
      if (mounted) {
        _cached = clients;
        setState(() {
          _clients = clients;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('My Clients', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary())),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_clients.length} ${_clients.length == 1 ? 'Client' : 'Clients'}',
                style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const Spacer(),
        // Client avatars row
        if (_isLoading)
          const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
        else if (_clients.isEmpty)
          Center(
            child: Text('No clients yet', style: TextStyle(color: textTertiary(), fontSize: 12)),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _clients.take(5).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final client = entry.value;
              final firstName = (client as dynamic).firstName ?? '';
              final lastName = (client as dynamic).lastName ?? '';
              final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
              final colors = _avatarColors[i % _avatarColors.length];

              return Padding(
                padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
                child: Column(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: (client as dynamic).avatar == null ? LinearGradient(colors: colors) : null,
                        boxShadow: [BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: (client as dynamic).avatar != null
                          ? ClipOval(
                              child: Image.network(
                                (client as dynamic).avatar,
                                fit: BoxFit.cover, width: 44, height: 44,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                            ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 52,
                      child: Text(
                        firstName,
                        style: TextStyle(fontSize: 10, color: textSecondary(), fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        const Spacer(),
      ],
    );
  }
}
