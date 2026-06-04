import 'package:flutter/material.dart';
import '../../../data/models/lead_model.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/repositories/lead_repository.dart';

const _vaServiceOptions = [
  'Administrative Support',
  'Customer Service',
  'Social Media Management',
  'Data Entry',
  'Email Management',
  'Scheduling & Calendar',
  'Research',
  'Sales Support',
  'Content Creation',
  'Bookkeeping',
  'Other',
];

class IntakeFormDialog extends StatefulWidget {
  final LeadModel lead;

  const IntakeFormDialog({super.key, required this.lead});

  @override
  State<IntakeFormDialog> createState() => _IntakeFormDialogState();
}

class _IntakeFormDialogState extends State<IntakeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _submitting = false;
  String? _error;
  bool _submitted = false;

  // Controllers pre-filled from lead
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _businessCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _hoursCtrl;
  final Set<String> _selectedServices = {};

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.lead.name);
    _emailCtrl = TextEditingController(text: widget.lead.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.lead.phone);
    _businessCtrl = TextEditingController(text: widget.lead.company);
    _addressCtrl = TextEditingController();
    _hoursCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _businessCtrl.dispose();
    _addressCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  bool get _step0Valid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _emailCtrl.text.trim().isNotEmpty &&
      _phoneCtrl.text.trim().isNotEmpty;

  bool get _step1Valid => _selectedServices.isNotEmpty;

  Future<void> _submit() async {
    if (!_step1Valid) {
      setState(() => _error = 'Please select at least one service type.');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      await getIt<LeadRepository>().submitIntake(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        vaTypes: _selectedServices.toList(),
        businessName: _businessCtrl.text.trim().isEmpty ? null : _businessCtrl.text.trim(),
        businessAddress: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        vaCount: _hoursCtrl.text.trim().isEmpty ? null : _hoursCtrl.text.trim(),
        leadId: widget.lead.id,
      );
      setState(() { _submitted = true; _submitting = false; });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final hintColor = isDark ? Colors.white38 : Colors.grey.shade400;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final fieldBg = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 480,
        child: _submitted ? _buildSuccess(cardBg, textColor) : _buildForm(cardBg, textColor, hintColor, borderColor, fieldBg, isDark),
      ),
    );
  }

  Widget _buildSuccess(Color cardBg, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 20),
          Text('Intake Submitted!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
          const SizedBox(height: 8),
          Text(
            '${widget.lead.name.isNotEmpty ? widget.lead.name : 'The lead'} has been added to the pending clients queue. The admin will review and create their account.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(Color cardBg, Color textColor, Color hintColor, Color borderColor, Color fieldBg, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.assignment_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Client Intake Form', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              Text(widget.lead.name.isNotEmpty ? widget.lead.name : 'New Client', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
            ])),
            // Step indicator
            Row(children: List.generate(2, (i) => Container(
              margin: const EdgeInsets.only(left: 6),
              width: i == _step ? 20 : 8, height: 8,
              decoration: BoxDecoration(
                color: i == _step ? Colors.white : Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ))),
            const SizedBox(width: 8),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          ]),
        ),

        // Content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: _step == 0 ? _buildStep0(textColor, hintColor, borderColor, fieldBg, isDark) : _buildStep1(textColor, hintColor, borderColor, fieldBg, isDark),
            ),
          ),
        ),

        // Footer
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFCA5A5))),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600))),
                  ]),
                ),
              ],
              Row(children: [
                if (_step > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() { _step--; _error = null; }),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: borderColor),
                      ),
                      child: Text('Back', style: TextStyle(color: hintColor, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : () {
                      if (_step == 0) {
                        if (!_step0Valid) { setState(() => _error = 'Please fill in all required fields.'); return; }
                        setState(() { _step = 1; _error = null; });
                      } else {
                        _submit();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_step == 0 ? 'Next →' : 'Submit Intake', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep0(Color textColor, Color hintColor, Color borderColor, Color fieldBg, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Contact Information', textColor),
        const SizedBox(height: 14),
        _field(_nameCtrl, 'Full Name *', Icons.person_outline, textColor, hintColor, borderColor, fieldBg),
        const SizedBox(height: 10),
        _field(_emailCtrl, 'Email Address *', Icons.email_outlined, textColor, hintColor, borderColor, fieldBg, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 10),
        _field(_phoneCtrl, 'Phone Number *', Icons.phone_outlined, textColor, hintColor, borderColor, fieldBg, keyboardType: TextInputType.phone),
        const SizedBox(height: 18),
        _label('Business Information', textColor),
        const SizedBox(height: 14),
        _field(_businessCtrl, 'Company / Business Name', Icons.business_outlined, textColor, hintColor, borderColor, fieldBg),
        const SizedBox(height: 10),
        _field(_addressCtrl, 'Business Address', Icons.location_on_outlined, textColor, hintColor, borderColor, fieldBg),
        const SizedBox(height: 10),
        _field(_hoursCtrl, 'Hours needed per week (e.g. 20)', Icons.schedule_outlined, textColor, hintColor, borderColor, fieldBg, keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildStep1(Color textColor, Color hintColor, Color borderColor, Color fieldBg, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Services Needed *', textColor),
        const SizedBox(height: 6),
        Text('Select all that apply', style: TextStyle(fontSize: 12, color: hintColor)),
        const SizedBox(height: 14),
        ..._vaServiceOptions.map((service) {
          final selected = _selectedServices.contains(service);
          return GestureDetector(
            onTap: () => setState(() {
              if (selected) _selectedServices.remove(service); else _selectedServices.add(service);
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF10B981).withOpacity(0.1) : fieldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? const Color(0xFF10B981).withOpacity(0.4) : borderColor),
              ),
              child: Row(children: [
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF10B981) : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: selected ? const Color(0xFF10B981) : (isDark ? Colors.white30 : Colors.grey.shade400)),
                  ),
                  child: selected ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
                ),
                const SizedBox(width: 12),
                Text(service, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? const Color(0xFF10B981) : textColor)),
              ]),
            ),
          );
        }),
      ],
    );
  }

  Widget _label(String text, Color textColor) {
    return Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor.withOpacity(0.6), letterSpacing: 0.3));
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, Color textColor, Color hintColor, Color borderColor, Color fieldBg, {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: TextStyle(color: textColor, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: hintColor, fontSize: 13),
          prefixIcon: Icon(icon, color: hintColor, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        ),
      ),
    );
  }
}
