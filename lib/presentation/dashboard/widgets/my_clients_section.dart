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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Clients',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (!_isLoading || _clients.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_clients.length} ${_clients.length == 1 ? 'Client' : 'Clients'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
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
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadClients(showLoading: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No clients assigned yet',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You will see your assigned clients here',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
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
        childAspectRatio: 1.2,
      ),
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        return _buildClientCard(_clients[index]);
      },
    );
  }

  Widget _buildClientCard(ClientModel client) {
    final initials = '${client.firstName[0]}${client.lastName[0]}'.toUpperCase();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/messages');
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  '${client.firstName} ${client.lastName}',
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                // Message Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.message, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Message',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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
    );
  }
}