import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../core/di/service_locator.dart';

class ProfileCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onAvatarUpload;

  const ProfileCard({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onAvatarUpload,
  });

  Future<void> _handleUploadAvatar(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) {
        print('❌ No image selected');
        return;
      }

      print('📸 Image selected: ${image.path}');

      // Read file
      final bytes = await File(image.path).readAsBytes();
      print('📦 File size: ${bytes.length} bytes');

      // Check file size (max 2MB)
      if (bytes.length > 2 * 1024 * 1024) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image too large! Please select an image under 2MB.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      // Convert to base64
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      print('🔄 Uploading avatar...');

      final userRepository = getIt<UserRepository>();
      await userRepository.uploadAvatar(base64Image);

      print('✅ Avatar uploaded successfully!');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      onAvatarUpload();
    } catch (e) {
      print('❌ Avatar upload error: $e');
      
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = ThemeProvider().isDarkMode;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A1D2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: dark ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
        boxShadow: [
          BoxShadow(
            color: dark ? Colors.black.withOpacity(0.3) : const Color(0xFF7C3AED).withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(context),
          const SizedBox(width: 32),
          Expanded(child: _buildInfo()),
          _buildEditButton(),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
            ),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: user.profile?.avatar != null
              ? ClipOval(
                  child: Image.memory(
                    base64Decode(user.profile!.avatar!.split(',')[1]),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('❌ Error loading avatar: $error');
                      return Center(
                        child: Text(
                          user.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                )
              : Center(
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _handleUploadAvatar(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.fullName,
          style: TextStyle(
            color: ThemeProvider().isDarkMode ? Colors.white : const Color(0xFF1F2937),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user.email,
          style: TextStyle(
            color: ThemeProvider().isDarkMode ? Colors.white70 : const Color(0xFF6B7280),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildInfoChip(Icons.badge, user.role, const Color(0xFF8B5CF6)),
            const SizedBox(width: 12),
            if (user.profile?.company != null)
              _buildInfoChip(Icons.business, user.profile!.company!, const Color(0xFF10B981)),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onEdit,
        icon: const Icon(Icons.edit, color: Colors.white, size: 24),
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}