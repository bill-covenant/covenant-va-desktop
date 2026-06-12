import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/repositories/blog_repository.dart';

/// "Latest Blog Posts" card on the VA dashboard — shows admin-authored
/// VA-audience blog posts (GET /blog/va). Sits beside Recent Activity, so it
/// always renders a card (with a placeholder when there are no posts yet).
class BlogPreviewSection extends StatefulWidget {
  const BlogPreviewSection({super.key});

  @override
  State<BlogPreviewSection> createState() => _BlogPreviewSectionState();
}

class _BlogPreviewSectionState extends State<BlogPreviewSection> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final posts = await getIt<BlogRepository>().getVaBlogs();
      if (mounted) setState(() { _posts = posts; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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

  String _preview(Map<String, dynamic> p) {
    final ex = (p['excerpt'] ?? '').toString().trim();
    if (ex.isNotEmpty) return ex;
    final body = htmlToText((p['content'] ?? '').toString());
    return body.length > 160 ? '${body.substring(0, 160)}…' : body;
  }

  void _open(Map<String, dynamic> p, bool isDark) {
    showDialog(context: context, builder: (_) => _BlogReaderDialog(post: p, isDark: isDark));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final cardBg = isDark ? const Color(0xFF1A1D2E) : Colors.white;
    final posts = _posts.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]
            : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text('Latest Blog Posts', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary)),
          ]),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)))),
            )
          else if (posts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('No blog posts yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary))),
            )
          else
            _featured(posts.first, posts.skip(1).take(2).toList(), isDark, textPrimary, textSecondary),
        ],
      ),
    );
  }

  Widget _featured(Map<String, dynamic> p, List<Map<String, dynamic>> more, bool isDark, Color textPrimary, Color textSecondary) {
    final cover = (p['coverImage'] ?? '').toString();
    final tags = (p['tags'] is List) ? (p['tags'] as List) : const [];
    return GestureDetector(
      onTap: () => _open(p, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cover.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                cover,
                width: double.infinity,
                // Show the full image (no crop), scaled to the card width.
                fit: BoxFit.fitWidth,
                // Flutter web (CanvasKit) can't draw cross-origin images without
                // CORS headers; fall back to an HTML <img> element so they show.
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(child: Icon(Icons.menu_book_rounded, color: Colors.white54, size: 32)),
                ),
              ),
            ),
          if (cover.isNotEmpty) const SizedBox(height: 14),
          if (tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 6,
                children: tags.take(2).map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(t.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED))),
                )).toList(),
              ),
            ),
          Text((p['title'] ?? '').toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(_preview(p), style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.calendar_today_outlined, size: 12, color: textSecondary),
            const SizedBox(width: 5),
            Text(_fmtDate(p['publishedAt'] ?? p['createdAt']), style: TextStyle(fontSize: 11.5, color: textSecondary)),
            const Spacer(),
            const Text('Read', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED))),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF7C3AED)),
          ]),
          if (more.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
            const SizedBox(height: 6),
            ...more.map((m) => InkWell(
              onTap: () => _open(m, isDark),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(children: [
                  const Icon(Icons.article_outlined, size: 14, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 8),
                  Expanded(child: Text((m['title'] ?? '').toString(), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Text(_fmtDate(m['publishedAt'] ?? m['createdAt']), style: TextStyle(fontSize: 10.5, color: textSecondary)),
                ]),
              ),
            )),
          ],
        ],
      ),
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
    final body = _BlogPreviewSectionState.htmlToText((post['content'] ?? '').toString());

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
                        child: Image.network(cover, width: double.infinity, height: 220, fit: BoxFit.cover, webHtmlElementStrategy: WebHtmlElementStrategy.fallback, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
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
