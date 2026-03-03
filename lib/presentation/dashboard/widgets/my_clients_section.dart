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
          DateTime.now().difference(_lastFetchTime!) > const Duration(seconds: 30)) {
        _loadClients(showLoading: false);
      }
    } else {
      _isLoading = true;
      _loadClients(showLoading: true);
    }
  }

  Future<void> _loadClients({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() { _isLoading = true; _error = null; });
    }
    try {
      final clients = await _clientRepository.getAssignedClients();
      if (mounted) {
        _cachedClients = clients;
        _lastFetchTime = DateTime.now();
        setState(() { _clients = clients; _isLoading = false; _isInitialLoad = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
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
                child: Icon(Icons.people_alt_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'My Clients',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            if (!_isLoading || _clients.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: Text(
                  '${_clients.length} ${_clients.length == 1 ? 'Client' : 'Clients'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
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
          _buildClientsGrid(),
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
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
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
            Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => _loadClients(showLoading: true), child: const Text('Retry')),
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
            Icon(Icons.people_outline, size: 64, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No clients assigned yet', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('You will see your assigned clients here', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildClientsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.0,
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

class _ClientCardState extends State<_ClientCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
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
    final initials = '${widget.client.firstName[0]}${widget.client.lastName[0]}'.toUpperCase();
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
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -6.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              // Main shadow
              BoxShadow(
                color: widget.gradient[0].withOpacity(_isHovered ? 0.4 : 0.2),
                blurRadius: _isHovered ? 32 : 20,
                offset: Offset(0, _isHovered ? 16 : 10),
                spreadRadius: _isHovered ? 2 : 0,
              ),
              // Bottom edge glow
              BoxShadow(
                color: widget.gradient[1].withOpacity(_isHovered ? 0.3 : 0.1),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
              // Top-left highlight (3D rim light)
              BoxShadow(
                color: Colors.white.withOpacity(_isHovered ? 0.15 : 0.08),
                blurRadius: 8,
                offset: const Offset(-3, -3),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/messages'),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
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
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative gradient orb (top-right)
                    Positioned(
                      top: -30,
                      right: -30,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _isHovered ? 110 : 90,
                        height: _isHovered ? 110 : 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.gradient[0].withOpacity(_isHovered ? 0.15 : 0.08),
                              widget.gradient[1].withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Decorative gradient orb (bottom-left)
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.gradient[1].withOpacity(0.06),
                              widget.gradient[0].withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Card content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 3D Avatar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: _isHovered ? 72 : 68,
                            height: _isHovered ? 72 : 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: widget.gradient,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.gradient[0].withOpacity(_isHovered ? 0.5 : 0.35),
                                  blurRadius: _isHovered ? 20 : 14,
                                  offset: const Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.8),
                                  blurRadius: 4,
                                  offset: const Offset(-2, -2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Inner shine
                                Positioned(
                                  top: 6,
                                  left: 10,
                                  child: Container(
                                    width: 24,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white.withOpacity(0.45),
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
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Name
                          Text(
                            name,
                            style: TextStyle(
                              color: const Color(0xFF1F2937),
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Status indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withOpacity(0.5),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Active',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Message button
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _isHovered
                                    ? widget.gradient
                                    : [
                                        widget.gradient[0].withOpacity(0.85),
                                        widget.gradient[1].withOpacity(0.85),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.gradient[0].withOpacity(_isHovered ? 0.45 : 0.25),
                                  blurRadius: _isHovered ? 16 : 10,
                                  offset: const Offset(0, 4),
                                ),
                                // Top edge highlight for 3D button
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.15),
                                  blurRadius: 1,
                                  offset: const Offset(0, -1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_rounded,
                                  size: 16,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Message',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}