import 'package:flutter/material.dart';
import '../../../data/models/client_model.dart';
import '../../../data/repositories/client_repository.dart';
import '../../../core/di/service_locator.dart';

class MyClientsSection extends StatefulWidget {
  const MyClientsSection({super.key});

  @override
  State<MyClientsSection> createState() => _MyClientsSectionState();
}

class _MyClientsSectionState extends State<MyClientsSection> {
  final ClientRepository _clientRepository = getIt<ClientRepository>();
  List<ClientModel> _clients = [];
  bool _isLoading = false;
  bool _isInitialLoad = true;
  String? _error;

  static List<ClientModel>? _cachedClients;
  static DateTime? _lastFetchTime;

  @override
  void initState() {
    super.initState();
    if (_cachedClients != null) {
      _clients = _cachedClients!;
      _isInitialLoad = false;
      _isLoading = false;
      if (_lastFetchTime == null ||
          DateTime.now().difference(_lastFetchTime!) >
              const Duration(seconds: 30)) {
        _loadClients(showLoading: false);
      }
    } else {
      _isLoading = true;
      _loadClients(showLoading: true);
    }
  }

  Future<void> _loadClients({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final clients = await _clientRepository.getAssignedClients();
      if (mounted) {
        _cachedClients = clients;
        _lastFetchTime = DateTime.now();
        setState(() {
          _clients = clients;
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  static const _cardGradients = [
    [Color(0xFF7C3AED), Color(0xFF9333EA)],
    [Color(0xFF3B82F6), Color(0xFF2563EB)],
    [Color(0xFFEC4899), Color(0xFFDB2777)],
    [Color(0xFF10B981), Color(0xFF059669)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
    [Color(0xFF6366F1), Color(0xFF4F46E5)],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.people_alt_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'My Clients',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            if (!_isLoading || _clients.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF8B5CF6).withOpacity(0.15)),
                ),
                child: Text(
                  '${_clients.length} ${_clients.length == 1 ? 'Client' : 'Clients'}',
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (_isLoading && _isInitialLoad)
          _buildLoadingState()
        else if (_error != null && _clients.isEmpty)
          _buildErrorState()
        else if (_clients.isEmpty)
          _buildEmptyState()
        else
          _buildClientsList(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: const Center(
        child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white70),
            const SizedBox(height: 16),
            Text(_error!,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () => _loadClients(showLoading: true),
                child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.people_outline,
                size: 64, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No clients assigned yet',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('You will see your assigned clients here',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildClientsList() {
    // Calculate number of rows needed for 2-column grid
    final int rowCount = (_clients.length / 2).ceil();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2, // Wider than tall
      ),
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        return _ClientCard(
          client: _clients[index],
          gradient: _cardGradients[index % _cardGradients.length],
          index: index,
        );
      },
    );
  }
}

class _ClientCard extends StatefulWidget {
  final ClientModel client;
  final List<Color> gradient;
  final int index;

  const _ClientCard({
    required this.client,
    required this.gradient,
    required this.index,
  });

  @override
  State<_ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends State<_ClientCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isMsgHovered = false;
  bool _isMsgPressed = false;
  late AnimationController _entryController;
  late Animation<double> _entryAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    );
    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initials =
        '${widget.client.firstName[0]}${widget.client.lastName[0]}'
            .toUpperCase();
    final name = '${widget.client.firstName} ${widget.client.lastName}';

    return AnimatedBuilder(
      animation: _entryAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.5 + (0.5 * _entryAnimation.value),
          child: Opacity(
            opacity: _entryAnimation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(20),
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -4.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.98),
                Colors.white.withOpacity(0.92),
                Colors.grey.shade50,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
            border: Border.all(
                color: Colors.white.withOpacity(0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.gradient[0]
                    .withOpacity(_isHovered ? 0.35 : 0.15),
                blurRadius: _isHovered ? 24 : 16,
                offset: Offset(0, _isHovered ? 12 : 8),
                spreadRadius: _isHovered ? 1 : 0,
              ),
              BoxShadow(
                color:
                    Colors.white.withOpacity(_isHovered ? 0.15 : 0.08),
                blurRadius: 6,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/messages'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: _isHovered ? 56 : 52,
                  height: _isHovered ? 56 : 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.gradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradient[0]
                            .withOpacity(_isHovered ? 0.5 : 0.3),
                        blurRadius: _isHovered ? 16 : 10,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.7),
                        blurRadius: 3,
                        offset: const Offset(-1, -1),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 5,
                        left: 8,
                        child: Container(
                          width: 18,
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.4),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Name
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.5),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text('Active',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                // Message button with 3D effect
                MouseRegion(
                  onEnter: (_) => setState(() => _isMsgHovered = true),
                  onExit: (_) => setState(() {
                    _isMsgHovered = false;
                    _isMsgPressed = false;
                  }),
                  child: GestureDetector(
                    onTapDown: (_) =>
                        setState(() => _isMsgPressed = true),
                    onTapUp: (_) =>
                        setState(() => _isMsgPressed = false),
                    onTapCancel: () =>
                        setState(() => _isMsgPressed = false),
                    onTap: () =>
                        Navigator.pushNamed(context, '/messages'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      transform: Matrix4.translationValues(
                        0,
                        _isMsgPressed
                            ? 2
                            : (_isMsgHovered ? -1 : 0),
                        0,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _isMsgHovered
                              ? [
                                  widget.gradient[0],
                                  widget.gradient[1],
                                ]
                              : [
                                  widget.gradient[0].withOpacity(0.85),
                                  widget.gradient[1].withOpacity(0.85),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white
                              .withOpacity(_isMsgHovered ? 0.25 : 0.1),
                        ),
                        boxShadow: _isMsgPressed
                            ? [
                                BoxShadow(
                                  color: widget.gradient[0]
                                      .withOpacity(0.15),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color:
                                      widget.gradient[1].withOpacity(0.6),
                                  blurRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                                BoxShadow(
                                  color: widget.gradient[0].withOpacity(
                                      _isMsgHovered ? 0.4 : 0.2),
                                  blurRadius:
                                      _isMsgHovered ? 12 : 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_rounded,
                              size: 14,
                              color: Colors.white.withOpacity(0.95)),
                          const SizedBox(width: 6),
                          const Text(
                            'Message',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}