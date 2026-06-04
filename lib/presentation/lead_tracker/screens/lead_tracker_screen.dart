import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/lead_tracker_bloc.dart';
import '../bloc/lead_tracker_event.dart';
import '../bloc/lead_tracker_state.dart';
import '../../../data/models/lead_model.dart';

const _statuses = ['New', 'Contacted', 'Follow-up', 'Interested', 'Not Interested', 'Closed'];

Color _statusColor(String status) {
  switch (status) {
    case 'New': return const Color(0xFF6B7280);
    case 'Contacted': return const Color(0xFF3B82F6);
    case 'Follow-up': return const Color(0xFFF59E0B);
    case 'Interested': return const Color(0xFF10B981);
    case 'Not Interested': return const Color(0xFFEF4444);
    case 'Closed': return const Color(0xFF059669);
    default: return const Color(0xFF6B7280);
  }
}

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
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String status = 'New';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Lead', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email (optional)', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => status = v ?? 'New'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<LeadTrackerBloc>().add(LeadTrackerCreateRequested(
                  name: nameCtrl.text.trim(),
                  company: companyCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                  status: status,
                ));
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotesDialog(LeadModel lead) {
    final lastContactedCtrl = TextEditingController(
      text: lead.lastContacted != null ? DateFormat('yyyy-MM-dd').format(lead.lastContacted!) : '',
    );
    final painPointsCtrl = TextEditingController(text: lead.painPoints ?? '');
    final objectionsCtrl = TextEditingController(text: lead.objections ?? '');
    final notesCtrl = TextEditingController(text: lead.additionalNotes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lead.name.isNotEmpty ? lead.name : 'Lead Details',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Last Contacted', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                TextField(controller: lastContactedCtrl, decoration: const InputDecoration(hintText: 'YYYY-MM-DD', border: OutlineInputBorder()), keyboardType: TextInputType.datetime),
                const SizedBox(height: 12),
                const Text('Pain Points', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                TextField(controller: painPointsCtrl, decoration: const InputDecoration(hintText: 'What problems are they facing?', border: OutlineInputBorder()), maxLines: 3),
                const SizedBox(height: 12),
                const Text('Objections', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                TextField(controller: objectionsCtrl, decoration: const InputDecoration(hintText: 'Note any objections raised...', border: OutlineInputBorder()), maxLines: 3),
                const SizedBox(height: 12),
                const Text('Additional Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                TextField(controller: notesCtrl, decoration: const InputDecoration(hintText: 'Any other notes...', border: OutlineInputBorder()), maxLines: 4),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LeadTrackerBloc, LeadTrackerState>(
      listener: (context, state) {
        if (state is LeadTrackerLoaded && state.actionMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.actionMessage!), backgroundColor: Colors.green),
          );
        }
        if (state is LeadTrackerError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lead Tracker', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text('Track and manage your sales leads', style: TextStyle(fontSize: 13, color: Colors.white70)),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _showAddDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Lead', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search & Filter
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by name or company...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white38)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterStatus.isEmpty ? null : _filterStatus,
                        hint: const Text('All Statuses', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        dropdownColor: const Color(0xFF1E2A4A),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        icon: const Icon(Icons.filter_list, color: Colors.white54, size: 18),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('All Statuses')),
                          ..._statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                        ],
                        onChanged: (v) => setState(() => _filterStatus = v ?? ''),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Table
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4))],
                  ),
                  child: state is LeadTrackerLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state is LeadTrackerLoaded
                          ? _buildTable(state.leads)
                          : state is LeadTrackerError
                              ? Center(child: Text(state.message, style: const TextStyle(color: Colors.red)))
                              : const Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTable(List<LeadModel> allLeads) {
    final leads = _filtered(allLeads);
    if (leads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(allLeads.isEmpty ? 'No leads yet' : 'No leads match your search',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
            if (allLeads.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add your first lead'),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header row
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF4338CA)]),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
          child: Row(
            children: [
              _headerCell('#', 40),
              _headerCell('Name', 140),
              _headerCell('Company', 150),
              _headerCell('Phone', 130),
              _headerCell('Status', 130),
              _headerCell('Follow-up', 110),
              _headerCell('Notes', 200),
            ],
          ),
        ),
        // Data rows
        Expanded(
          child: ListView.builder(
            itemCount: leads.length,
            itemBuilder: (context, i) {
              final lead = leads[i];
              final isEven = i % 2 == 0;
              return Container(
                color: isEven ? Colors.grey.shade50 : Colors.white,
                child: Row(
                  children: [
                    _cell(Text('${i + 1}', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)), 40),
                    _editableCell(lead, 'name', lead.name, 140),
                    _editableCell(lead, 'company', lead.company, 150),
                    _editableCell(lead, 'phone', lead.phone, 130),
                    _statusCell(lead, 130),
                    _dateCell(lead, 110),
                    _notesCell(lead, 200),
                  ],
                ),
              );
            },
          ),
        ),
        // Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Text(
                leads.length != allLeads.length ? '${leads.length} of ${allLeads.length} leads' : '${allLeads.length} lead${allLeads.length != 1 ? 's' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add row', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF10B981)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String label, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
      ),
    );
  }

  Widget _cell(Widget child, double width) {
    return SizedBox(
      width: width,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: child),
    );
  }

  Widget _editableCell(LeadModel lead, String field, String value, double width) {
    return _cell(
      GestureDetector(
        onTap: () {
          final ctrl = TextEditingController(text: value);
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Edit ${field[0].toUpperCase()}${field.substring(1)}'),
              content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(border: OutlineInputBorder())),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(onPressed: () {
                  Navigator.pop(ctx);
                  context.read<LeadTrackerBloc>().add(LeadTrackerUpdateRequested(id: lead.id, data: {field: ctrl.text.trim()}));
                }, child: const Text('Save')),
              ],
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.transparent),
          ),
          child: Text(value.isEmpty ? '—' : value, style: TextStyle(fontSize: 12, color: value.isEmpty ? Colors.grey.shade300 : Colors.grey.shade800)),
        ),
      ),
      width,
    );
  }

  Widget _statusCell(LeadModel lead, double width) {
    return _cell(
      GestureDetector(
        onTap: () {
          String selected = lead.status;
          showDialog(
            context: context,
            builder: (ctx) => StatefulBuilder(
              builder: (ctx, setState) => AlertDialog(
                title: const Text('Change Status'),
                content: DropdownButtonFormField<String>(
                  value: selected,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => selected = v ?? lead.status),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () {
                    Navigator.pop(ctx);
                    context.read<LeadTrackerBloc>().add(LeadTrackerUpdateRequested(id: lead.id, data: {'status': selected}));
                  }, child: const Text('Save')),
                ],
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor(lead.status).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _statusColor(lead.status).withOpacity(0.3)),
          ),
          child: Text(lead.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _statusColor(lead.status))),
        ),
      ),
      width,
    );
  }

  Widget _dateCell(LeadModel lead, double width) {
    final label = lead.followUpDate != null ? DateFormat('MM/dd/yyyy').format(lead.followUpDate!) : '—';
    return _cell(
      GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: lead.followUpDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (picked != null && mounted) {
            context.read<LeadTrackerBloc>().add(LeadTrackerUpdateRequested(
              id: lead.id,
              data: {'followUpDate': DateFormat('yyyy-MM-dd').format(picked)},
            ));
          }
        },
        child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ),
      width,
    );
  }

  Widget _notesCell(LeadModel lead, double width) {
    return _cell(
      GestureDetector(
        onTap: () => _showNotesDialog(lead),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.transparent),
          ),
          child: Text(
            lead.additionalNotes?.isNotEmpty == true ? lead.additionalNotes! : 'Add notes...',
            style: TextStyle(fontSize: 12, color: lead.additionalNotes?.isNotEmpty == true ? Colors.grey.shade700 : Colors.grey.shade300),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      width,
    );
  }
}
