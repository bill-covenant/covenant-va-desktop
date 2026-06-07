import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import '../bloc/lead_tracker_bloc.dart';
import '../bloc/lead_tracker_event.dart';
import '../bloc/lead_tracker_state.dart';
import '../../../data/models/lead_model.dart';
import '../../../core/theme/theme_provider.dart';
import '../widgets/intake_form_dialog.dart';

const _statuses = ['New', 'Contacted', 'Follow-up', 'Interested', 'Not Interested', 'Closed'];

const _dispositions = [
  'New Lead', 'Attempted Contact', 'Contacted', 'Interested',
  'Meeting Scheduled', 'Nurture', 'Not Interested', 'DNC', 'Closed Deal',
];

const _dispositionColors = {
  'New Lead':          Color(0xFF6B7280),
  'Attempted Contact': Color(0xFF0EA5E9),
  'Contacted':         Color(0xFF3B82F6),
  'Interested':        Color(0xFF10B981),
  'Meeting Scheduled': Color(0xFF8B5CF6),
  'Nurture':           Color(0xFFF59E0B),
  'Not Interested':    Color(0xFFF97316),
  'DNC':               Color(0xFFEF4444),
  'Closed Deal':       Color(0xFF0D9488),
};

const _outcomes = ['Busy', 'Voicemail', 'Wrong Number', 'Disconnected Number', 'Contact Hang Up'];

const _outcomeColors = {
  'Busy':               Color(0xFFF59E0B),
  'Voicemail':          Color(0xFF3B82F6),
  'Wrong Number':       Color(0xFFF97316),
  'Disconnected Number':Color(0xFFEF4444),
  'Contact Hang Up':    Color(0xFFE11D48),
};

const _outcomeBg = {
  'Busy':               Color(0xFFFFFBEB),
  'Voicemail':          Color(0xFFEFF6FF),
  'Wrong Number':       Color(0xFFFFF7ED),
  'Disconnected Number':Color(0xFFFEF2F2),
  'Contact Hang Up':    Color(0xFFFFF1F2),
};

const _dispositionBg = {
  'New Lead':          Color(0xFFF3F4F6),
  'Attempted Contact': Color(0xFFE0F2FE),
  'Contacted':         Color(0xFFEFF6FF),
  'Interested':        Color(0xFFECFDF5),
  'Meeting Scheduled': Color(0xFFF5F3FF),
  'Nurture':           Color(0xFFFFFBEB),
  'Not Interested':    Color(0xFFFFF7ED),
  'DNC':               Color(0xFFFEF2F2),
  'Closed Deal':       Color(0xFFCCFBF1),
};

const _statusColors = {
  'New':           Color(0xFF6B7280),
  'Contacted':     Color(0xFF3B82F6),
  'Follow-up':     Color(0xFFF59E0B),
  'Interested':    Color(0xFF10B981),
  'Not Interested':Color(0xFFEF4444),
  'Closed':        Color(0xFF059669),
};

const _statusBg = {
  'New':           Color(0xFFF3F4F6),
  'Contacted':     Color(0xFFEFF6FF),
  'Follow-up':     Color(0xFFFFFBEB),
  'Interested':    Color(0xFFECFDF5),
  'Not Interested':Color(0xFFFEF2F2),
  'Closed':        Color(0xFFD1FAE5),
};

class LeadTrackerScreen extends StatefulWidget {
  const LeadTrackerScreen({super.key});

  @override
  State<LeadTrackerScreen> createState() => _LeadTrackerScreenState();
}

class _LeadTrackerScreenState extends State<LeadTrackerScreen> {
  final _searchCtrl = TextEditingController();
  String _filterStatus = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<LeadTrackerBloc>().add(const LeadTrackerLoadRequested());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<LeadModel> _filtered(List<LeadModel> leads) {
    return leads.where((l) {
      final matchSearch = _searchQuery.isEmpty ||
          l.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.company.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchStatus = _filterStatus.isEmpty || l.status == _filterStatus;
      return matchSearch && matchStatus;
    }).toList();
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final industryCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String status = 'New';
    final isDark = ThemeProvider().isDarkMode;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final hintColor = isDark ? Colors.white38 : Colors.grey.shade400;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text('Add New Lead', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close, color: hintColor, size: 18)),
                ]),
                const SizedBox(height: 20),
                _dialogField(nameCtrl, 'Name', Icons.person_outline, isDark, textColor, hintColor, borderColor),
                const SizedBox(height: 12),
                _dialogField(companyCtrl, 'Company', Icons.business_outlined, isDark, textColor, hintColor, borderColor),
                const SizedBox(height: 12),
                _dialogField(industryCtrl, 'Industry (optional)', Icons.apartment_outlined, isDark, textColor, hintColor, borderColor),
                const SizedBox(height: 12),
                _dialogField(phoneCtrl, 'Phone', Icons.phone_outlined, isDark, textColor, hintColor, borderColor),
                const SizedBox(height: 12),
                _dialogField(emailCtrl, 'Email (optional)', Icons.email_outlined, isDark, textColor, hintColor, borderColor),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: status,
                      isExpanded: true,
                      dropdownColor: cardColor,
                      style: TextStyle(color: textColor, fontSize: 13),
                      items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => status = v ?? 'New'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderColor)),
                      ),
                      child: Text('Cancel', style: TextStyle(color: hintColor, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<LeadTrackerBloc>().add(LeadTrackerCreateRequested(
                          name: nameCtrl.text.trim(),
                          company: companyCtrl.text.trim(),
                          industry: industryCtrl.text.trim().isEmpty ? null : industryCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                          status: status,
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Add Lead', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint, IconData? icon, bool isDark, Color textColor, Color hintColor, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: ctrl,
        style: TextStyle(color: textColor, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: hintColor, fontSize: 13),
          prefixIcon: icon != null ? Icon(icon, color: hintColor, size: 18) : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: icon != null ? 12 : 16),
        ),
      ),
    );
  }

  // Maps a CSV header to a lead field key (case-insensitive, common aliases).
  String? _mapHeader(String raw) {
    final k = raw.trim().toLowerCase();
    if (['name', 'full name', 'lead name', 'contact', 'contact name', 'contact person'].contains(k)) return 'name';
    if (['company', 'company name', 'business', 'business name', 'organization', 'organisation'].contains(k)) return 'company';
    if (['industry', 'sector', 'niche'].contains(k)) return 'industry';
    if (['phone', 'phone number', 'mobile', 'mobile number', 'contact number', 'number', 'tel', 'telephone'].contains(k)) return 'phone';
    if (['email', 'email address', 'e-mail', 'e mail'].contains(k)) return 'email';
    if (['status', 'lead status'].contains(k)) return 'status';
    return null;
  }

  void _showImportError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _handleImportCsv() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      _showImportError('Could not read the selected file.');
      return;
    }

    List<List<dynamic>> rows;
    try {
      var content = utf8.decode(bytes, allowMalformed: true);
      content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(content);
    } catch (_) {
      _showImportError('Could not parse the CSV file.');
      return;
    }
    if (rows.isEmpty) {
      _showImportError('The file appears to be empty.');
      return;
    }

    final headers = rows.first.map((e) => e.toString()).toList();
    final fieldIndex = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      final field = _mapHeader(headers[i]);
      if (field != null && !fieldIndex.containsKey(field)) fieldIndex[field] = i;
    }
    if (!fieldIndex.containsKey('name') && !fieldIndex.containsKey('company') && !fieldIndex.containsKey('phone')) {
      _showImportError('No recognizable columns. Add a header row with Name, Company, Phone, Email, or Industry.');
      return;
    }

    String cell(List<dynamic> row, String field) {
      final idx = fieldIndex[field];
      if (idx == null || idx >= row.length) return '';
      return row[idx].toString().trim();
    }

    final leads = <Map<String, dynamic>>[];
    for (final row in rows.skip(1)) {
      if (row.every((c) => c.toString().trim().isEmpty)) continue;
      final name = cell(row, 'name');
      final company = cell(row, 'company');
      final phone = cell(row, 'phone');
      final email = cell(row, 'email');
      final industry = cell(row, 'industry');
      final status = cell(row, 'status');
      if (name.isEmpty && company.isEmpty && phone.isEmpty && email.isEmpty) continue;
      leads.add({
        'name': name,
        'company': company,
        if (industry.isNotEmpty) 'industry': industry,
        'phone': phone,
        if (email.isNotEmpty) 'email': email,
        if (status.isNotEmpty) 'status': status,
      });
    }

    if (leads.isEmpty) {
      _showImportError('No leads found in the file.');
      return;
    }
    if (!mounted) return;

    final isDark = ThemeProvider().isDarkMode;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final hintColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final detected = fieldIndex.keys.map((k) => '${k[0].toUpperCase()}${k.substring(1)}').join(', ');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text('Import Leads', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
            ]),
            const SizedBox(height: 16),
            Text('Found ${leads.length} lead${leads.length == 1 ? '' : 's'} in ${file.name}.',
                style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Detected columns: $detected', style: TextStyle(fontSize: 12, color: hintColor)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: TextStyle(color: hintColor, fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: Text('Import ${leads.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
              )),
            ]),
          ]),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      context.read<LeadTrackerBloc>().add(LeadTrackerImportRequested(leads));
    }
  }

  void _showNotesDialog(LeadModel lead, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final hintColor = isDark ? Colors.white38 : Colors.grey.shade400;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final lastContactedCtrl = TextEditingController(
      text: lead.lastContacted != null ? DateFormat('yyyy-MM-dd').format(lead.lastContacted!) : '',
    );
    final painPointsCtrl = TextEditingController(text: lead.painPoints ?? '');
    final objectionsCtrl = TextEditingController(text: lead.objections ?? '');
    final notesCtrl = TextEditingController(text: lead.additionalNotes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notes_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Lead Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
                    if (lead.name.isNotEmpty)
                      Text('${lead.name}${lead.company.isNotEmpty ? ' · ${lead.company}' : ''}',
                          style: TextStyle(fontSize: 11, color: hintColor)),
                  ]),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close, color: hintColor, size: 18)),
                ]),
                const SizedBox(height: 20),
                _sectionLabel('Last Contacted', textColor),
                const SizedBox(height: 6),
                _dialogField(lastContactedCtrl, 'YYYY-MM-DD', null, isDark, textColor, hintColor, borderColor),
                const SizedBox(height: 14),
                _sectionLabel('Pain Points', textColor),
                const SizedBox(height: 6),
                _dialogTextArea(painPointsCtrl, 'What problems are they facing?', isDark, textColor, hintColor, borderColor),
                const SizedBox(height: 14),
                _sectionLabel('Objections', textColor),
                const SizedBox(height: 6),
                _dialogTextArea(objectionsCtrl, 'Note any objections raised...', isDark, textColor, hintColor, borderColor),
                const SizedBox(height: 14),
                _sectionLabel('Additional Notes', textColor),
                const SizedBox(height: 6),
                _dialogTextArea(notesCtrl, 'Any other notes...', isDark, textColor, hintColor, borderColor, maxLines: 4),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderColor)),
                      ),
                      child: Text('Cancel', style: TextStyle(color: hintColor, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<LeadTrackerBloc>().add(LeadTrackerUpdateRequested(
                          id: lead.id,
                          data: {
                            'lastContacted': lastContactedCtrl.text.trim().isEmpty ? null : lastContactedCtrl.text.trim(),
                            'painPoints': painPointsCtrl.text.trim(),
                            'objections': objectionsCtrl.text.trim(),
                            'additionalNotes': notesCtrl.text.trim(),
                          },
                        ));
                      },
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, Color textColor) {
    return Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor.withOpacity(0.5), letterSpacing: 0.5));
  }

  Widget _dialogTextArea(TextEditingController ctrl, String hint, bool isDark, Color textColor, Color hintColor, Color borderColor, {int maxLines = 3}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: TextStyle(color: textColor, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: hintColor, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider(),
      builder: (context, _) {
        final isDark = ThemeProvider().isDarkMode;
        return BlocConsumer<LeadTrackerBloc, LeadTrackerState>(
          listener: (context, state) {
            if (state is LeadTrackerLoaded && state.actionMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.actionMessage!),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            }
            if (state is LeadTrackerError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            }
          },
          builder: (context, state) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Container(
                decoration: isDark
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF0F172A),
                            const Color(0xFF064E3B).withOpacity(0.3),
                            const Color(0xFF0F172A),
                          ],
                        ),
                      )
                    : null,
                child: Column(
                  children: [
                    _buildHeader(context, state, isDark),
                    if (state is LeadTrackerLoaded) ...[
                      _buildStats(state.leads, isDark),
                      _buildSearchBar(isDark),
                      Expanded(child: _buildTable(context, state.leads, isDark)),
                    ] else if (state is LeadTrackerLoading) ...[
                      Expanded(child: Center(child: CircularProgressIndicator(color: isDark ? const Color(0xFF10B981) : Colors.white))),
                    ] else if (state is LeadTrackerError) ...[
                      Expanded(child: Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.error_outline, color: isDark ? const Color(0xFFEF4444) : Colors.white70, size: 48),
                          const SizedBox(height: 12),
                          Text(state.message, style: TextStyle(color: isDark ? Colors.white70 : Colors.white)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.read<LeadTrackerBloc>().add(const LeadTrackerLoadRequested()),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF10B981) : Colors.white,
                              foregroundColor: isDark ? Colors.white : const Color(0xFF10B981),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ]),
                      )),
                    ] else ...[
                      const Expanded(child: SizedBox()),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, LeadTrackerState state, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 28, 28, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isDark
              ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
              : [const Color(0xFF10B981), const Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF10B981).withOpacity(isDark ? 0.15 : 0.4), blurRadius: 20, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.1)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lead Tracker', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                Text(
                  state is LeadTrackerLoaded
                      ? '${state.leads.length} lead${state.leads.length == 1 ? '' : 's'} total'
                      : 'Track and manage your sales leads',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Row(children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: IconButton(
                onPressed: () => context.read<LeadTrackerBloc>().add(const LeadTrackerLoadRequested()),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                tooltip: 'Refresh',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: IconButton(
                onPressed: _handleImportCsv,
                icon: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 18),
                tooltip: 'Import leads from CSV',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(width: 8),
            if (state is LeadTrackerLoaded)
              // Submit Intake button
              ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const IntakeFormDialog(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Submit Intake', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _showAddDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF10B981) : Colors.white,
                  foregroundColor: isDark ? Colors.white : const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: isDark ? 0 : 3,
                  shadowColor: Colors.black.withOpacity(0.2),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, size: 16, color: isDark ? Colors.white : const Color(0xFF059669)),
                  const SizedBox(width: 6),
                  Text('Add Lead', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF059669))),
                ]),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildStats(List<LeadModel> leads, bool isDark) {
    final counts = <String, int>{
      'New': 0, 'Contacted': 0, 'Follow-up': 0,
      'Interested': 0, 'Not Interested': 0, 'Closed': 0,
    };
    for (final l in leads) {
      counts[l.status] = (counts[l.status] ?? 0) + 1;
    }

    final chips = [
      ('New', counts['New']!, const Color(0xFF6B7280), const Color(0xFFF9FAFB)),
      ('Contacted', counts['Contacted']!, const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
      ('Follow-up', counts['Follow-up']!, const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
      ('Interested', counts['Interested']!, const Color(0xFF10B981), const Color(0xFFECFDF5)),
      ('Closed', counts['Closed']!, const Color(0xFF059669), const Color(0xFFD1FAE5)),
      ('Not Interested', counts['Not Interested']!, const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(28, 14, 28, 0),
      child: Row(
        children: chips.map((chip) {
          final (label, count, color, bg) = chip;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? color.withOpacity(0.12) : bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.15)),
                boxShadow: [BoxShadow(color: color.withOpacity(isDark ? 0.08 : 0.06), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
                  const SizedBox(height: 2),
                  Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? color.withOpacity(0.8) : color.withOpacity(0.7))),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final bg = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200;

    return Container(
      margin: const EdgeInsets.fromLTRB(28, 12, 28, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1F2937), fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by name or company...',
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white30 : Colors.grey.shade400, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterStatus.isEmpty ? null : _filterStatus,
                hint: Row(children: [
                  Icon(Icons.filter_list_rounded, size: 16, color: isDark ? Colors.white38 : Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text('All Statuses', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 13)),
                ]),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1F2937), fontSize: 13),
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white38 : Colors.grey.shade400, size: 18),
                items: [
                  DropdownMenuItem(value: '', child: Text('All Statuses', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600))),
                  ..._statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                ],
                onChanged: (v) => setState(() => _filterStatus = v ?? ''),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<LeadModel> allLeads, bool isDark) {
    final leads = _filtered(allLeads);
    final cardBg = isDark ? const Color(0xFF0F1E35).withOpacity(0.8) : Colors.white;
    final headerBg = isDark
        ? const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF065F46)])
        : const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF4338CA)]);
    final borderColor = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100;

    if (leads.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF10B981).withOpacity(0.12), const Color(0xFF059669).withOpacity(0.06)]),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.trending_up_rounded, size: 48, color: const Color(0xFF10B981).withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          Text(allLeads.isEmpty ? 'No leads yet' : 'No leads match your search',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isDark ? Colors.white54 : Colors.grey.shade500)),
          const SizedBox(height: 6),
          Text(allLeads.isEmpty ? 'Tap Add Lead to get started' : 'Try a different search or filter',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.grey.shade400)),
          if (allLeads.isEmpty) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add your first lead', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ]
        ]),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 24, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.15 : 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(gradient: headerBg),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              child: Row(children: [
                _thFlex('#', 1),
                _thFlex('Name', 2),
                _thFlex('Email Address', 3),
                _thFlex('Company', 2),
                _thFlex('Industry', 2),
                _thFlex('Phone', 2),
                _thFlex('Status', 2),
                _thFlex('Call Disposition', 2),
                _thFlex('Follow-up', 2),
                _thFlex('Notes', 3),
                const SizedBox(width: 80),
              ]),
            ),
            // Rows
            Expanded(
              child: ListView.builder(
                itemCount: leads.length,
                itemBuilder: (context, i) {
                  final lead = leads[i];
                  return _buildRow(context, lead, i, isDark, borderColor);
                },
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Icon(Icons.people_outline, size: 14, color: isDark ? Colors.white30 : Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text(
                    leads.length != allLeads.length ? '${leads.length} of ${allLeads.length} leads' : '${allLeads.length} lead${allLeads.length != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showAddDialog,
                    icon: Icon(Icons.add_rounded, size: 14, color: const Color(0xFF10B981).withOpacity(0.8)),
                    label: Text('Add row', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF10B981).withOpacity(0.8))),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _th(String label, double width) {
    final child = Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.3));
    if (width == double.infinity) return Expanded(child: child);
    return SizedBox(width: width, child: child);
  }

  Widget _thFlex(String label, int flex) {
    return Expanded(
      flex: flex,
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.3)),
    );
  }

  Widget _editableCellFlex(BuildContext context, LeadModel lead, String field, String value, bool isDark) {
    return GestureDetector(
      onTap: () {
        final ctrl = TextEditingController(text: value);
        final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SizedBox(
              width: 380,
              child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Edit ${field[0].toUpperCase()}${field.substring(1)}', style: TextStyle(fontWeight: FontWeight.w800, color: textColor)),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<LeadTrackerBloc>().add(LeadTrackerUpdateRequested(id: lead.id, data: {field: ctrl.text.trim()}));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                  )),
                ]),
              ]),
            ),
          ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(
          value.isEmpty ? '—' : value,
          style: TextStyle(
            fontSize: 12,
            color: value.isEmpty ? (isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade300) : (isDark ? Colors.white.withOpacity(0.87) : const Color(0xFF374151)),
            fontWeight: value.isEmpty ? FontWeight.w400 : FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, LeadModel lead, int index, bool isDark, Color borderColor) {
    final isEven = index % 2 == 0;
    final rowBg = isDark
        ? (isEven ? Colors.white.withOpacity(0.0) : Colors.white.withOpacity(0.02))
        : (isEven ? Colors.white : const Color(0xFFF9FAFB));

    return InkWell(
      onTap: () => _showNotesDialog(lead, isDark),
      hoverColor: isDark ? const Color(0xFF10B981).withOpacity(0.05) : const Color(0xFFECFDF5),
      child: Container(
        decoration: BoxDecoration(
          color: rowBg,
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(flex: 1, child: Text('${index + 1}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.grey.shade400, fontWeight: FontWeight.w600))),
            Expanded(flex: 2, child: _editableCellFlex(context, lead, 'name', lead.name, isDark)),
            Expanded(flex: 3, child: _editableCellFlex(context, lead, 'email', lead.email ?? '', isDark)),
            Expanded(flex: 2, child: _editableCellFlex(context, lead, 'company', lead.company, isDark)),
            Expanded(flex: 2, child: _editableCellFlex(context, lead, 'industry', lead.industry ?? '', isDark)),
            Expanded(flex: 2, child: _editableCellFlex(context, lead, 'phone', lead.phone, isDark)),
            Expanded(flex: 2, child: _dispositionChip(context, lead, isDark)),
            Expanded(flex: 2, child: _outcomeChip(context, lead, isDark)),
            Expanded(flex: 2, child: _datePicker(context, lead, isDark)),
            Expanded(flex: 3, child: _notesPreview(lead, isDark)),
            SizedBox(
              width: 36,
              child: IconButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => IntakeFormDialog(lead: lead),
                ),
                icon: const Icon(Icons.assignment_turned_in_outlined, size: 17),
                color: const Color(0xFF10B981).withOpacity(0.7),
                hoverColor: const Color(0xFF10B981).withOpacity(0.1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Submit client intake form',
              ),
            ),
            SizedBox(
              width: 36,
              child: IconButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('Delete Lead', style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1F2937))),
                      content: Text('Remove ${lead.name.isNotEmpty ? lead.name : 'this lead'}? This cannot be undone.', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 13)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                          child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    context.read<LeadTrackerBloc>().add(LeadTrackerDeleteRequested(id: lead.id));
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: const Color(0xFFEF4444).withOpacity(0.6),
                hoverColor: const Color(0xFFEF4444).withOpacity(0.1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Delete lead',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editableCell(BuildContext context, LeadModel lead, String field, String value, double width, bool isDark) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: () {
          final ctrl = TextEditingController(text: value);
          final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
          final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
          showDialog(
            context: context,
            builder: (ctx) => Dialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SizedBox(
                width: 380,
                child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Edit ${field[0].toUpperCase()}${field.substring(1)}', style: TextStyle(fontWeight: FontWeight.w800, color: textColor)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    style: TextStyle(color: textColor, fontSize: 13),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
                    const SizedBox(width: 8),
                    Expanded(child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<LeadTrackerBloc>().add(LeadTrackerUpdateRequested(id: lead.id, data: {field: ctrl.text.trim()}));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                      child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                    )),
                  ]),
                ]),
              ),
            ),
          ),
        );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(
              fontSize: 12,
              color: value.isEmpty ? (isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade300) : (isDark ? Colors.white.withOpacity(0.87) : const Color(0xFF374151)),
              fontWeight: value.isEmpty ? FontWeight.w400 : FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context, LeadModel lead, bool isDark) {
    final color = _statusColors[lead.status] ?? const Color(0xFF6B7280);
    final bg = isDark ? color.withOpacity(0.15) : (_statusBg[lead.status] ?? const Color(0xFFF3F4F6));

    return GestureDetector(
      onTap: () {
        String selected = lead.status;
        final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) => Dialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Change Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF1F2937))),
                    const SizedBox(height: 14),
                    ..._statuses.map((s) {
                      final sColor = _statusColors[s] ?? const Color(0xFF6B7280);
                      final sBg = isDark ? sColor.withOpacity(0.12) : (_statusBg[s] ?? const Color(0xFFF3F4F6));
                      return GestureDetector(
                        onTap: () {
                          setState(() => selected = s);
                          Navigator.pop(ctx);
                          context.read<LeadTrackerBloc>().add(LeadTrackerUpdateRequested(id: lead.id, data: {'status': s}));
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected == s ? sBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: selected == s ? sColor.withOpacity(0.3) : Colors.transparent),
                          ),
                          child: Row(children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: sColor, shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Text(s, style: TextStyle(fontSize: 13, fontWeight: selected == s ? FontWeight.w700 : FontWeight.w500, color: selected == s ? sColor : (isDark ? Colors.white70 : Colors.grey.shade700))),
                            if (selected == s) ...[const Spacer(), Icon(Icons.check_rounded, size: 16, color: sColor)],
                          ]),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(lead.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }

  Widget _dispositionChip(BuildContext context, LeadModel lead, bool isDark) {
    final disp = lead.callDisposition;
    final color = disp != null ? (_dispositionColors[disp] ?? const Color(0xFF6B7280)) : const Color(0xFF6B7280);
    final bg = disp != null ? (_dispositionBg[disp] ?? const Color(0xFFF3F4F6)) : Colors.transparent;

    return GestureDetector(
      onTap: () {
        String? selected = lead.callDisposition;
        final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) => Dialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SizedBox(
                width: 340,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Call Disposition', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: textColor)),
                      const SizedBox(height: 14),
                      ...[ null, ..._dispositions].map((d) {
                        final dColor = d != null ? (_dispositionColors[d] ?? const Color(0xFF6B7280)) : const Color(0xFF6B7280);
                        final dBg = d != null ? (_dispositionBg[d] ?? const Color(0xFFF3F4F6)) : Colors.transparent;
                        final isSelected = selected == d;
                        return GestureDetector(
                          onTap: () {
                            setState(() => selected = d);
                            Navigator.pop(ctx);
                            context.read<LeadTrackerBloc>().add(LeadTrackerUpdateRequested(id: lead.id, data: {'callDisposition': d}));
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected ? (isDark ? dColor.withOpacity(0.15) : dBg) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSelected ? dColor.withOpacity(0.3) : Colors.transparent),
                            ),
                            child: Row(children: [
                              if (d != null) ...[
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: dColor, shape: BoxShape.circle)),
                                const SizedBox(width: 10),
                              ],
                              Text(
                                d ?? '— Clear —',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: d != null
                                      ? (isSelected ? dColor : (isDark ? Colors.white70 : Colors.grey.shade700))
                                      : (isDark ? Colors.white38 : Colors.grey.shade400),
                                  fontStyle: d == null ? FontStyle.italic : FontStyle.normal,
                                ),
                              ),
                              if (isSelected) ...[const Spacer(), Icon(Icons.check_rounded, size: 16, color: dColor)],
                            ]),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: disp != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? color.withOpacity(0.15) : bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Flexible(child: Text(disp, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color), overflow: TextOverflow.ellipsis)),
              ]),
            )
          : Text('— Set —', style: TextStyle(fontSize: 11, color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade300, fontStyle: FontStyle.italic)),
    );
  }

  Widget _outcomeChip(BuildContext context, LeadModel lead, bool isDark) {
    final outcome = lead.callOutcome;
    final color = outcome != null ? (_outcomeColors[outcome] ?? const Color(0xFF6B7280)) : const Color(0xFF6B7280);
    final bg = outcome != null ? (_outcomeBg[outcome] ?? const Color(0xFFF3F4F6)) : Colors.transparent;

    return GestureDetector(
      onTap: () {
        String? selected = lead.callOutcome;
        final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) => Dialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SizedBox(
                width: 300,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Call Disposition', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: textColor)),
                      const SizedBox(height: 14),
                      ...[null, ..._outcomes].map((o) {
                        final oColor = o != null ? (_outcomeColors[o] ?? const Color(0xFF6B7280)) : const Color(0xFF6B7280);
                        final oBg = o != null ? (_outcomeBg[o] ?? const Color(0xFFF3F4F6)) : Colors.transparent;
                        final isSelected = selected == o;
                        return GestureDetector(
                          onTap: () {
                            setState(() => selected = o);
                            Navigator.pop(ctx);
                            context.read<LeadTrackerBloc>().add(LeadTrackerUpdateRequested(id: lead.id, data: {'callOutcome': o}));
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected ? (isDark ? oColor.withOpacity(0.15) : oBg) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSelected ? oColor.withOpacity(0.3) : Colors.transparent),
                            ),
                            child: Row(children: [
                              if (o != null) ...[
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: oColor, shape: BoxShape.circle)),
                                const SizedBox(width: 10),
                              ],
                              Text(
                                o ?? '— Clear —',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: o != null
                                      ? (isSelected ? oColor : (isDark ? Colors.white70 : Colors.grey.shade700))
                                      : (isDark ? Colors.white38 : Colors.grey.shade400),
                                  fontStyle: o == null ? FontStyle.italic : FontStyle.normal,
                                ),
                              ),
                              if (isSelected) ...[const Spacer(), Icon(Icons.check_rounded, size: 16, color: oColor)],
                            ]),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: outcome != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? color.withOpacity(0.15) : bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Flexible(child: Text(outcome, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color), overflow: TextOverflow.ellipsis)),
              ]),
            )
          : Text('— Set —', style: TextStyle(fontSize: 11, color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade300, fontStyle: FontStyle.italic)),
    );
  }

  Widget _datePicker(BuildContext context, LeadModel lead, bool isDark) {
    final label = lead.followUpDate != null ? DateFormat('MM/dd/yy').format(lead.followUpDate!) : '—';
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: lead.followUpDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (ctx, child) => Theme(
            data: ThemeData(
              colorScheme: isDark
                  ? const ColorScheme.dark(primary: Color(0xFF10B981))
                  : const ColorScheme.light(primary: Color(0xFF10B981)),
            ),
            child: child!,
          ),
        );
        if (picked != null && mounted) {
          context.read<LeadTrackerBloc>().add(LeadTrackerUpdateRequested(id: lead.id, data: {'followUpDate': DateFormat('yyyy-MM-dd').format(picked)}));
        }
      },
      child: Row(children: [
        Icon(Icons.calendar_today_outlined, size: 12, color: isDark ? Colors.white30 : Colors.grey.shade400),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _notesPreview(LeadModel lead, bool isDark) {
    final hasNotes = lead.additionalNotes?.isNotEmpty == true;
    return Text(
      hasNotes ? lead.additionalNotes! : 'Tap to add notes...',
      style: TextStyle(
        fontSize: 12,
        color: hasNotes ? (isDark ? Colors.white.withOpacity(0.6) : Colors.grey.shade600) : (isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade300),
        fontStyle: hasNotes ? FontStyle.normal : FontStyle.italic,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
