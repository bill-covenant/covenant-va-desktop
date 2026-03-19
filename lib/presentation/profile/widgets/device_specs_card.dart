import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';

class DeviceSpecsCard extends StatefulWidget {
  final UserModel user;
  final VoidCallback onUpdated;

  const DeviceSpecsCard({
    super.key,
    required this.user,
    required this.onUpdated,
  });

  @override
  State<DeviceSpecsCard> createState() => _DeviceSpecsCardState();
}

class _DeviceSpecsCardState extends State<DeviceSpecsCard> {
  final _repo = GetIt.I<UserRepository>();
  bool _saving = false;

  late TextEditingController _laptopCtrl;
  late TextEditingController _processorCtrl;
  late TextEditingController _ramCtrl;
  late TextEditingController _storageCtrl;
  late TextEditingController _osCtrl;
  late TextEditingController _internetCtrl;
  late TextEditingController _monitorCtrl;
  late TextEditingController _headsetCtrl;

  @override
  void initState() {
    super.initState();
    final ds = widget.user.profile?.deviceSpecs ?? {};
    _laptopCtrl = TextEditingController(text: ds['laptopModel'] ?? '');
    _processorCtrl = TextEditingController(text: ds['processor'] ?? '');
    _ramCtrl = TextEditingController(text: ds['ram'] ?? '');
    _storageCtrl = TextEditingController(text: ds['storage'] ?? '');
    _osCtrl = TextEditingController(text: ds['os'] ?? '');
    _internetCtrl = TextEditingController(text: ds['internetSpeed'] ?? '');
    _monitorCtrl = TextEditingController(text: ds['monitor'] ?? '');
    _headsetCtrl = TextEditingController(text: ds['headset'] ?? '');
  }

  @override
  void dispose() {
    _laptopCtrl.dispose();
    _processorCtrl.dispose();
    _ramCtrl.dispose();
    _storageCtrl.dispose();
    _osCtrl.dispose();
    _internetCtrl.dispose();
    _monitorCtrl.dispose();
    _headsetCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _repo.updateProfile(
        deviceSpecs: {
          'laptopModel': _laptopCtrl.text,
          'processor': _processorCtrl.text,
          'ram': _ramCtrl.text,
          'storage': _storageCtrl.text,
          'os': _osCtrl.text,
          'internetSpeed': _internetCtrl.text,
          'monitor': _monitorCtrl.text,
          'headset': _headsetCtrl.text,
        },
      );
      widget.onUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Device specs saved'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = ThemeProvider().isDarkMode;
    const iconColor = Color(0xFFF59E0B);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [const Color(0xFF1E2235), const Color(0xFF171B2D)]
              : [Colors.white, const Color(0xFFF8F9FB)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: dark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: dark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: dark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [iconColor, iconColor.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: iconColor.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: const Icon(Icons.computer_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 14),
                Text(
                  'Device Specifications',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: dark ? Colors.white : const Color(0xFF1F2937)),
                ),
                const Spacer(),
                _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: iconColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 20),
            _buildRow(dark, [
              _field(dark, 'Laptop Model', _laptopCtrl, Icons.laptop_rounded),
              _field(dark, 'Processor', _processorCtrl, Icons.memory_rounded),
            ]),
            const SizedBox(height: 10),
            _buildRow(dark, [
              _field(dark, 'RAM', _ramCtrl, Icons.storage_rounded),
              _field(dark, 'Storage', _storageCtrl, Icons.sd_storage_rounded),
            ]),
            const SizedBox(height: 10),
            _buildRow(dark, [
              _field(dark, 'Operating System', _osCtrl, Icons.desktop_windows_rounded),
              _field(dark, 'Internet Speed', _internetCtrl, Icons.wifi_rounded),
            ]),
            const SizedBox(height: 10),
            _buildRow(dark, [
              _field(dark, 'Monitor', _monitorCtrl, Icons.monitor_rounded),
              _field(dark, 'Headset', _headsetCtrl, Icons.headset_rounded),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(bool dark, List<Widget> children) {
    return Row(
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: 14),
        Expanded(child: children[1]),
      ],
    );
  }

  Widget _field(bool dark, String label, TextEditingController ctrl, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dark ? Colors.white.withOpacity(0.5) : const Color(0xFF6B7280))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: TextStyle(fontSize: 14, color: dark ? Colors.white : const Color(0xFF1F2937)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: dark ? Colors.white.withOpacity(0.3) : const Color(0xFF9CA3AF)),
            filled: true,
            fillColor: dark ? Colors.white.withOpacity(0.06) : const Color(0xFFF3F4F6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            hintText: 'Not provided',
            hintStyle: TextStyle(color: dark ? Colors.white.withOpacity(0.2) : const Color(0xFFD1D5DB)),
          ),
        ),
      ],
    );
  }
}
