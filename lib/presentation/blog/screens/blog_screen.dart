import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/repositories/blog_repository.dart';

/// VA-facing reader for admin-authored blog posts (audience = VA).
class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<BlogRepository>().getVaBlogs();
  }

  void _refresh() {
    setState(() {
      _future = getIt<BlogRepository>().getVaBlogs();
    });
  }

  static String htmlToText(String html) {
    var s = html;
    s = s.replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'</\s*(p|div|h[1-6]|li|ul|ol|blockquote)\s*>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    s = s
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    return s;
  }

  String _fmtDate(dynamic iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso.toString());
    return d == null ? '' : DateFormat('MMM d, yyyy').format(d.toLocal());
  }

  String _preview(Map<String, dynamic> post) {
    final excerpt = (post['excerpt'] ?? '').toString().trim();
    if (excerpt.isNotEmpty) return excerpt;
    final body = htmlToText((post['content'] ?? '').toString());
    return body.length > 180 ? '${body.substring(0, 180)}…' : body;
  }

  void _openPost(Map<String, dynamic> post, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => _BlogReaderDialog(post: post, isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider(),
      builder: (context, _) {
        final isDark = ThemeProvider().isDarkMode;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: isDark
                ? const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0F172A), Color(0xFF1A1025), Color(0xFF0F172A)],
                    ),
                  )
                : null,
            child: Column(
              children: [
                _buildHeader(isDark),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
                      }
                      if (snap.hasError) {
                        return _emptyState(isDark, 'Failed to load posts', 'Pull to refresh or try again later');
                      }
                      final posts = snap.data ?? [];
                      if (posts.isEmpty) {
                        return _emptyState(isDark, 'No posts yet', 'New posts from the team will show up here');
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
                        itemCount: posts.length,
                        itemBuilder: (context, i) => _buildCard(posts[i], isDark),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 28, 28, 12),
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Blog', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                Text('Updates and resources from the team', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              tooltip: 'Refresh',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> post, bool isDark) {
    final title = (post['title'] ?? '').toString();
    final cover = (post['coverImage'] ?? '').toString();
    final author = post['author'] is Map
        ? '${(post['author']['firstName'] ?? '').toString()} ${(post['author']['lastName'] ?? '').toString()}'.trim()
        : '';
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final hintColor = isDark ? Colors.white60 : Colors.grey.shade600;

    return GestureDetector(
      onTap: () => _openPost(post, isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.06), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cover.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  cover,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor)),
                  const SizedBox(height: 8),
                  Text(_preview(post), style: TextStyle(fontSize: 13, color: hintColor, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.calendar_today_outlined, size: 12, color: hintColor),
                    const SizedBox(width: 5),
                    Text(_fmtDate(post['publishedAt'] ?? post['createdAt']), style: TextStyle(fontSize: 11, color: hintColor)),
                    if (author.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.person_outline, size: 12, color: hintColor),
                      const SizedBox(width: 5),
                      Text(author, style: TextStyle(fontSize: 11, color: hintColor)),
                    ],
                    const Spacer(),
                    Text('Read', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED))),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF7C3AED)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(bool isDark, String title, String subtitle) {
    final hintColor = isDark ? Colors.white54 : Colors.grey.shade500;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.menu_book_outlined, size: 48, color: const Color(0xFF7C3AED).withOpacity(0.5)),
        const SizedBox(height: 14),
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: hintColor)),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(fontSize: 12, color: hintColor.withOpacity(0.8))),
      ]),
    );
  }
}

class _BlogReaderDialog extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool isDark;
  const _BlogReaderDialog({required this.post, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final hintColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final title = (post['title'] ?? '').toString();
    final cover = (post['coverImage'] ?? '').toString();
    final body = _BlogScreenState.htmlToText((post['content'] ?? '').toString());

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 640,
        height: 700,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 12, 8),
              child: Row(children: [
                Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor))),
                IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: hintColor, size: 20)),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cover.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(cover, width: double.infinity, height: 220, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                      ),
                    if (cover.isNotEmpty) const SizedBox(height: 16),
                    SelectableText(body, style: TextStyle(fontSize: 14, height: 1.6, color: textColor)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
