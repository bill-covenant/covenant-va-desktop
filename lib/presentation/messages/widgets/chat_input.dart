import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/providers/api_provider.dart';
import 'package:get_it/get_it.dart';
import '../bloc/messages_bloc.dart';
import '../bloc/messages_event.dart';
import '../bloc/messages_state.dart';

class ChatInput extends StatefulWidget {
  final ConversationModel conversation;
  final String currentUserId;

  const ChatInput({
    super.key,
    required this.conversation,
    required this.currentUserId,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonScale;
  bool _isFocused = false;
  bool _hasText = false;
  bool _showEmojiPicker = false;
  bool _isUploading = false;

  // Pending files to attach
  List<PlatformFile> _pendingFiles = [];

  // Key for positioning the popup relative to the input bar
  final GlobalKey _inputBarKey = GlobalKey();

  bool get _canSend =>
      (_hasText || _pendingFiles.isNotEmpty) && !_isUploading;

  @override
  void initState() {
    super.initState();
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _sendButtonScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
          parent: _sendButtonController, curve: Curves.easeOutBack),
    );

    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });

    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    _updateSendButton();
  }

  void _updateSendButton() {
    if (_canSend) {
      _sendButtonController.forward();
    } else {
      _sendButtonController.reverse();
    }
  }

  @override
  void dispose() {
    _dismissEmojiPicker();
    _messageController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'jpg', 'jpeg', 'png', 'gif', 'webp', // images
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', // docs
          'txt', 'csv', 'zip', 'rar', // other
        ],
      );

      if (result == null || result.files.isEmpty) return;

      // Filter out files > 10MB
      final validFiles = result.files.where((f) {
        if (f.size > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${f.name} exceeds 10MB limit'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          return false;
        }
        return f.path != null;
      }).toList();

      if (validFiles.isNotEmpty) {
        setState(() {
          _pendingFiles = [..._pendingFiles, ...validFiles];
        });
        _updateSendButton();
      }
    } catch (e) {
      print('❌ File picker error: $e');
    }
  }

  void _removePendingFile(int index) {
    setState(() {
      _pendingFiles.removeAt(index);
    });
    _updateSendButton();
  }

  Future<Map<String, dynamic>?> _uploadFile(PlatformFile file) async {
    try {
      final token = GetIt.instance<ApiProvider>().authToken;
      if (token == null) throw Exception('Not authenticated');

      final uri = Uri.parse('${ApiConstants.baseUrl}/attachments/upload');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token';

      final mimeType = _getMimeType(file.name);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          File(file.path!).readAsBytesSync(),
          filename: file.name,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['attachment'] as Map<String, dynamic>;
      } else {
        print('❌ Upload failed (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Upload error: $e');
      return null;
    }
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty && _pendingFiles.isEmpty) return;

    // Upload files first
    List<Map<String, dynamic>> attachments = [];
    if (_pendingFiles.isNotEmpty) {
      setState(() => _isUploading = true);

      try {
        for (final file in _pendingFiles) {
          final uploaded = await _uploadFile(file);
          if (uploaded != null) {
            attachments.add(uploaded);
          }
        }
      } catch (e) {
        print('❌ Upload failed: $e');
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to upload files'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isUploading = false;
          _pendingFiles = [];
        });
      }
    }

    _messageController.clear();

    context.read<MessagesBloc>().add(
          MessageSendRequested(
            conversationId: widget.conversation.id,
            content: message,
            senderId: widget.currentUserId,
            clientName: widget.conversation.client?.fullName ?? '',
            vaName: widget.conversation.va?.fullName ?? '',
            attachments: attachments,
          ),
        );

    _focusNode.requestFocus();
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      _dismissEmojiPicker();
    } else {
      _showEmojiPickerModal();
    }
  }

  void _showEmojiPickerModal() {
    setState(() => _showEmojiPicker = true);

    final RenderBox? renderBox =
        _inputBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final inputBarTop = position.dy;
    final screenWidth = MediaQuery.of(context).size.width;

    const double gap = 8.0;

    final double right = screenWidth - position.dx - renderBox.size.width + 16;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height - inputBarTop + gap,
              right: right,
              child: Material(
                color: Colors.transparent,
                child: _buildEmojiPopup(dialogContext),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() => _showEmojiPicker = false);
      }
    });
  }

  void _dismissEmojiPicker() {
    if (_showEmojiPicker && mounted) {
      Navigator.of(context, rootNavigator: true).maybePop();
      setState(() => _showEmojiPicker = false);
    }
  }

  Widget _buildEmojiPopup(BuildContext dialogContext) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 380,
        height: 360,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF7C3AED).withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 40,
              offset: const Offset(0, 16),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: EmojiPicker(
            textEditingController: _messageController,
            onBackspacePressed: () {
              _messageController
                ..text = _messageController.text.characters
                    .skipLast(1)
                    .toString()
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: _messageController.text.length),
                );
            },
            onEmojiSelected: (category, emoji) {},
            config: Config(
              height: 360,
              checkPlatformCompatibility: true,
              emojiViewConfig: EmojiViewConfig(
                emojiSizeMax: 28 *
                    (foundation.defaultTargetPlatform == TargetPlatform.iOS
                        ? 1.20
                        : 1.0),
              ),
              skinToneConfig: const SkinToneConfig(),
              viewOrderConfig: const ViewOrderConfig(
                top: EmojiPickerItem.searchBar,
                middle: EmojiPickerItem.categoryBar,
                bottom: EmojiPickerItem.emojiView,
              ),
              categoryViewConfig: CategoryViewConfig(
                indicatorColor: const Color(0xFF7C3AED),
                iconColorSelected: const Color(0xFF7C3AED),
                iconColor: const Color(0xFFB4A3CC),
                dividerColor: const Color(0xFF7C3AED).withOpacity(0.06),
              ),
              bottomActionBarConfig: const BottomActionBarConfig(
                showBackspaceButton: false,
                showSearchViewButton: false,
              ),
              searchViewConfig: SearchViewConfig(
                buttonIconColor: const Color(0xFF7C3AED),
                hintText: 'Search emoji...',
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isImageFile(String name) {
    final ext = name.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;

    return BlocListener<MessagesBloc, MessagesState>(
      listener: (context, state) {
        if (state is MessageSendError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to send message',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pending files preview strip
          if (_pendingFiles.isNotEmpty) _buildPendingFilesStrip(isDark),

          // Input bar
          ClipRect(
            key: _inputBarKey,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFF1A1230),
                            Color(0xFF1E1535),
                          ],
                        )
                      : const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFF7C3AED),
                            Color(0xFFEC4899),
                          ],
                        ),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.white.withOpacity(0.15),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(
                          isDark ? 0.1 : 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Main input container
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          constraints: const BoxConstraints(maxHeight: 120),
                          decoration: BoxDecoration(
                            color: isDark
                                ? (_isFocused
                                    ? Colors.white.withOpacity(0.15)
                                    : Colors.white.withOpacity(0.1))
                                : (_isFocused
                                    ? Colors.white.withOpacity(0.97)
                                    : Colors.white.withOpacity(0.9)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? (_isFocused
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.white.withOpacity(0.15))
                                  : (_isFocused
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.6)),
                              width: _isFocused ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: _isFocused ? 16 : 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 6, bottom: 4),
                                child: _buildInlineButton(
                                  Icons.attach_file_rounded,
                                  onTap: _pickFiles,
                                ),
                              ),
                              Expanded(
                                child: KeyboardListener(
                                  focusNode: FocusNode(),
                                  onKeyEvent: (KeyEvent event) {
                                    if (event is KeyDownEvent &&
                                        event.logicalKey ==
                                            LogicalKeyboardKey.enter &&
                                        !HardwareKeyboard
                                            .instance.isShiftPressed) {
                                      _sendMessage();
                                    }
                                  },
                                  child: TextField(
                                    controller: _messageController,
                                    focusNode: _focusNode,
                                    maxLines: null,
                                    keyboardType: TextInputType.multiline,
                                    textInputAction: TextInputAction.send,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF2D2252),
                                      fontSize: 14.5,
                                      height: 1.45,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Type a message...',
                                      hintStyle: TextStyle(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.5)
                                            : const Color(0xFF9CA3AF)
                                                .withOpacity(0.8),
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 14,
                                      ),
                                    ),
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(right: 6, bottom: 4),
                                child: _buildInlineButton(
                                  _showEmojiPicker
                                      ? Icons.keyboard_rounded
                                      : Icons.emoji_emotions_outlined,
                                  onTap: _toggleEmojiPicker,
                                  isActive: _showEmojiPicker,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Send button
                      AnimatedBuilder(
                        animation: _sendButtonScale,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _canSend ? _sendButtonScale.value : 0.85,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: _canSend
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF8B5CF6),
                                          Color(0xFF7C3AED),
                                        ],
                                      )
                                    : null,
                                color: _canSend
                                    ? null
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _canSend
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF7C3AED)
                                              .withOpacity(0.35),
                                          blurRadius: 14,
                                          offset: const Offset(0, 4),
                                        ),
                                        BoxShadow(
                                          color: const Color(0xFF7C3AED)
                                              .withOpacity(0.15),
                                          blurRadius: 24,
                                          offset: const Offset(0, 8),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _canSend ? _sendMessage : null,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Center(
                                    child: _isUploading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : AnimatedRotation(
                                            turns: _canSend ? -0.05 : 0,
                                            duration: const Duration(
                                                milliseconds: 200),
                                            child: Icon(
                                              Icons.send_rounded,
                                              color: _canSend
                                                  ? Colors.white
                                                  : Colors.white
                                                      .withOpacity(0.5),
                                              size: 20,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingFilesStrip(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1230) : const Color(0xFF6D28D9),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Row(
            children: [
              Icon(
                Icons.attach_file_rounded,
                size: 14,
                color: Colors.white.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                '${_pendingFiles.length} file${_pendingFiles.length > 1 ? 's' : ''} attached',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() => _pendingFiles = []);
                  _updateSendButton();
                },
                child: Text(
                  'Clear all',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Files row
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _pendingFiles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final file = _pendingFiles[index];
                final isImg = _isImageFile(file.name);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (isImg && file.path != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(file.path!),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.insert_drive_file_rounded,
                              color: Colors.white.withOpacity(0.6),
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                file.name,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Remove button
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () => _removePendingFile(index),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineButton(
    IconData icon, {
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Icon(
              icon,
              color: isActive
                  ? (ThemeProvider().isDarkMode ? Colors.white : const Color(0xFF7C3AED))
                  : (ThemeProvider().isDarkMode
                      ? Colors.white.withOpacity(0.5)
                      : const Color(0xFFA78BFA).withOpacity(0.7)),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
