import 'package:flutter/material.dart';
import '../../../data/models/lead_model.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/repositories/lead_repository.dart';

const _vaExperienceOptions = [
  'Yes, I have worked with a VA before',
  'No, this is my first time',
  "Sort of - I've used freelancers/contractors",
];

class IntakeFormDialog extends StatefulWidget {
  final LeadModel lead;
  const IntakeFormDialog({super.key, required this.lead});

  @override
  State<IntakeFormDialog> createState() => _IntakeFormDialogState();
}

class _IntakeFormDialogState extends State<IntakeFormDialog> {
  int _section = 0;
  bool _submitting = false;
  String? _error;
  bool _submitted = false;

  // Section 0 — Contact Information
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _addressCtrl;

  // Section 1 — About Your Business
  final TextEditingController _aboutCtrl = TextEditingController();
  final TextEditingController _servicesCtrl = TextEditingController();
  final TextEditingController _suggestionsCtrl = TextEditingController();

  // Section 2 — Service Requirements
  final TextEditingController _hoursCtrl = TextEditingController();
  final TextEditingController _timelineCtrl = TextEditingController();
  final TextEditingController _paymentCtrl = TextEditingController();

  // Section 3 — Technical Details
  final TextEditingController _softwareCtrl = TextEditingController();
  String? _vaExperience;
  final TextEditingController _anythingCtrl = TextEditingController();

  final _sections = const [
    _SectionInfo('Contact Information', Icons.person_outline_rounded, Color(0xFF3B82F6)),
    _SectionInfo('About Your Business', Icons.business_center_outlined, Color(0xFF8B5CF6)),
    _SectionInfo('Service Requirements', Icons.schedule_outlined, Color(0xFFF59E0B)),
    _SectionInfo('Technical Details', Icons.settings_outlined, Color(0xFF10B981)),
    _SectionInfo('Confirmation', Icons.check_circle_outline_rounded, Color(0xFF059669)),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.lead.name);
    _phoneCtrl = TextEditingController(text: widget.lead.phone);
    _emailCtrl = TextEditingController(text: widget.lead.email ?? '');
    _companyCtrl = TextEditingController(text: widget.lead.company);
    _addressCtrl = TextEditingController();
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _phoneCtrl, _emailCtrl, _companyCtrl, _addressCtrl,
      _aboutCtrl, _servicesCtrl, _suggestionsCtrl, _hoursCtrl, _timelineCtrl,
      _paymentCtrl, _softwareCtrl, _anythingCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validateSection() {
    switch (_section) {
      case 0:
        if (_nameCtrl.text.trim().isEmpty) return 'Full name is required';
        if (_nameCtrl.text.trim().split(RegExp(r'\s+')).length < 2) return 'Please enter first and last name';
        if (_phoneCtrl.text.trim().isEmpty) return 'Phone number is required';
        if (_emailCtrl.text.trim().isEmpty) return 'Email address is required';
        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(_emailCtrl.text.trim())) return 'Invalid email format';
        if (_companyCtrl.text.trim().isEmpty) return 'Company name is required';
        if (_addressCtrl.text.trim().isEmpty) return 'Company address is required';
        return null;
      case 1:
        if (_aboutCtrl.text.trim().isEmpty) return 'Please tell us about your business';
        if (_servicesCtrl.text.trim().isEmpty) return 'Please describe the services you need';
        if (_suggestionsCtrl.text.trim().isEmpty) return 'This field is required';
        return null;
      case 2:
        if (_hoursCtrl.text.trim().isEmpty) return 'Please specify hours per week';
        if (_timelineCtrl.text.trim().isEmpty) return 'Please specify a start timeline';
        return null;
      default:
        return null;
    }
  }

  void _next() {
    final err = _validateSection();
    if (err != null) { setState(() => _error = err); return; }
    setState(() { _error = null; _section = (_section + 1).clamp(0, _sections.length - 1); });
  }

  void _back() => setState(() { _error = null; _section = (_section - 1).clamp(0, _sections.length - 1); });

  Future<void> _submit() async {
    setState(() { _submitting = true; _error = null; });
    try {
      await getIt<LeadRepository>().submitIntake(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        servicesNeeded: _servicesCtrl.text.trim(),
        businessName: _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
        businessAddress: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        vaCount: _hoursCtrl.text.trim().isEmpty ? null : _hoursCtrl.text.trim(),
        aboutBusiness: _aboutCtrl.text.trim().isEmpty ? null : _aboutCtrl.text.trim(),
        needSuggestions: _suggestionsCtrl.text.trim().isEmpty ? null : _suggestionsCtrl.text.trim(),
        startTimeline: _timelineCtrl.text.trim().isEmpty ? null : _timelineCtrl.text.trim(),
        paymentAcknowledgment: _paymentCtrl.text.trim().isEmpty ? null : _paymentCtrl.text.trim(),
        softwareTools: _softwareCtrl.text.trim().isEmpty ? null : _softwareCtrl.text.trim(),
        vaExperience: _vaExperience,
        anythingElse: _anythingCtrl.text.trim().isEmpty ? null : _anythingCtrl.text.trim(),
        leadId: widget.lead.id,
      );
      setState(() { _submitted = true; _submitting = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _submitting = false; });
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
        width: 560,
        height: 680,
        child: _submitted
            ? _buildSuccess(cardBg, textColor)
            : Column(children: [
                _buildHeader(isDark),
                Expanded(child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                  child: _buildSection(isDark, textColor, hintColor, borderColor, fieldBg),
                )),
                _buildFooter(isDark, cardBg, textColor, hintColor, borderColor),
              ]),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final sec = _sections[_section];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [sec.color.withOpacity(0.3), sec.color.withOpacity(0.15)]
              : [const Color(0xFF7C3AED), const Color(0xFF4F46E5)],
        ),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.assignment_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Get Started with Covenant VA', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              Text('Fill in the intake form to add a new client', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
            ])),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(sec.icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Step ${_section + 1} of ${_sections.length}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600)),
                Text(sec.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              ])),
              Row(children: List.generate(_sections.length, (i) => GestureDetector(
                onTap: i <= _section ? () => setState(() { _section = i; _error = null; }) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(left: 5),
                  width: i == _section ? 20 : 7, height: 7,
                  decoration: BoxDecoration(
                    color: i <= _section ? Colors.white : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(bool isDark, Color textColor, Color hintColor, Color borderColor, Color fieldBg) {
    switch (_section) {
      case 0: return _section0(textColor, hintColor, borderColor, fieldBg);
      case 1: return _section1(textColor, hintColor, borderColor, fieldBg);
      case 2: return _section2(textColor, hintColor, borderColor, fieldBg);
      case 3: return _section3(isDark, textColor, hintColor, borderColor, fieldBg);
      case 4: return _section4(textColor, hintColor);
      default: return const SizedBox();
    }
  }

  Widget _section0(Color textColor, Color hintColor, Color borderColor, Color fieldBg) => Column(children: [
    _field(_nameCtrl, 'Full Name *', 'John Smith', Icons.person_outline, textColor, hintColor, borderColor, fieldBg),
    _gap(),
    _field(_phoneCtrl, 'Phone Number *', '(555) 123-4567', Icons.phone_outlined, textColor, hintColor, borderColor, fieldBg, type: TextInputType.phone),
    _gap(),
    _field(_emailCtrl, 'Email Address *', 'john@company.com', Icons.email_outlined, textColor, hintColor, borderColor, fieldBg, type: TextInputType.emailAddress),
    _gap(),
    _field(_companyCtrl, 'Company Name *', 'ABC Construction', Icons.business_outlined, textColor, hintColor, borderColor, fieldBg),
    _gap(),
    _field(_addressCtrl, 'Company Address *', '123 Main St, City, State', Icons.location_on_outlined, textColor, hintColor, borderColor, fieldBg),
    const SizedBox(height: 4),
  ]);

  Widget _section1(Color textColor, Color hintColor, Color borderColor, Color fieldBg) => Column(children: [
    _label('Tell us about your business *', textColor),
    _hint('Help us understand your business so we can match you with the right VA', hintColor),
    _gap(h: 6),
    _area(_aboutCtrl, 'What type of work do you do? How large is your team?', textColor, hintColor, borderColor, fieldBg),
    _gap(),
    _label('What are you needing help with that our VA can do for you? *', textColor),
    _gap(h: 6),
    _area(_servicesCtrl, 'Examples: scheduling, client communications, data entry, social media, bookkeeping...', textColor, hintColor, borderColor, fieldBg),
    _gap(),
    _label('Do you need help with ideas on what our VA can provide for you? *', textColor),
    _hint('Tell us if you need recommendations', hintColor),
    _gap(h: 6),
    _area(_suggestionsCtrl, "Yes, I'd like suggestions on what tasks a VA could handle...", textColor, hintColor, borderColor, fieldBg),
    const SizedBox(height: 4),
  ]);

  Widget _section2(Color textColor, Color hintColor, Color borderColor, Color fieldBg) => Column(children: [
    _label('How many hours per week do you anticipate needing? *', textColor),
    _hint('Available: 20 hrs/week (\$300/week) or 40 hrs/week (\$600/week)', hintColor),
    _gap(h: 6),
    _field(_hoursCtrl, 'e.g. 20 hours/week', '', Icons.schedule_outlined, textColor, hintColor, borderColor, fieldBg, type: TextInputType.text),
    _gap(),
    _label('When do you need to start? *', textColor),
    _gap(h: 6),
    _field(_timelineCtrl, 'e.g. Immediately, 1-2 weeks, Within 1 month', '', Icons.calendar_today_outlined, textColor, hintColor, borderColor, fieldBg),
    _gap(),
    _label('Payment Information', textColor),
    _hint('Auto-pay required — Payment due on the 1st of every month', hintColor),
    _gap(h: 6),
    _area(_paymentCtrl, 'Please acknowledge: Payment is \$1,200/month (20 hrs) or \$2,400/month (40 hrs). Auto-pay is required.', textColor, hintColor, borderColor, fieldBg, rows: 3),
    const SizedBox(height: 4),
  ]);

  Widget _section3(bool isDark, Color textColor, Color hintColor, Color borderColor, Color fieldBg) => Column(children: [
    _label("What software/tools does your business currently use?", textColor),
    _hint('This helps us ensure your VA is trained on your systems', hintColor),
    _gap(h: 6),
    _area(_softwareCtrl, 'QuickBooks, Microsoft Office, specific CRM systems...', textColor, hintColor, borderColor, fieldBg, rows: 3),
    _gap(),
    _label('Have you worked with a virtual assistant before?', textColor),
    _gap(h: 8),
    ..._vaExperienceOptions.map((opt) {
      final selected = _vaExperience == opt;
      return GestureDetector(
        onTap: () => setState(() => _vaExperience = opt),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF7C3AED).withOpacity(0.1) : fieldBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? const Color(0xFF7C3AED).withOpacity(0.4) : borderColor),
          ),
          child: Row(children: [
            Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF7C3AED) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: selected ? const Color(0xFF7C3AED) : (isDark ? Colors.white30 : Colors.grey.shade400)),
              ),
              child: selected ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(opt, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? const Color(0xFF7C3AED) : textColor))),
          ]),
        ),
      );
    }),
    _gap(),
    _label('Anything else we should know?', textColor),
    _gap(h: 6),
    _area(_anythingCtrl, 'Any specific requirements, concerns, or questions...', textColor, hintColor, borderColor, fieldBg, rows: 3),
    const SizedBox(height: 4),
  ]);

  Widget _section4(Color textColor, Color hintColor) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF10B981).withOpacity(0.1), const Color(0xFF059669).withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.verified_user_outlined, color: Color(0xFF10B981), size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Almost There!', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF059669), fontSize: 15)),
          const SizedBox(height: 4),
          Text('Once submitted, our team will review the client\'s needs and find the perfect VA match. The client will be notified once matched, and payment details are only collected at that time.', style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.65))),
        ])),
      ]),
    ),
    const SizedBox(height: 16),
    _summaryRow('Name', _nameCtrl.text, textColor, hintColor),
    _summaryRow('Email', _emailCtrl.text, textColor, hintColor),
    _summaryRow('Phone', _phoneCtrl.text, textColor, hintColor),
    _summaryRow('Company', _companyCtrl.text, textColor, hintColor),
    if (_hoursCtrl.text.isNotEmpty) _summaryRow('Hours/Week', _hoursCtrl.text, textColor, hintColor),
    if (_timelineCtrl.text.isNotEmpty) _summaryRow('Start Timeline', _timelineCtrl.text, textColor, hintColor),
    const SizedBox(height: 12),
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 15),
        SizedBox(width: 8),
        Expanded(child: Text('No payment will be charged now. The client will set up payment once matched with a VA.', style: TextStyle(color: Color(0xFF92400E), fontSize: 11, fontWeight: FontWeight.w600))),
      ]),
    ),
    const SizedBox(height: 4),
  ]);

  Widget _summaryRow(String label, String value, Color textColor, Color hintColor) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: hintColor)),
        Flexible(child: Text(value, textAlign: TextAlign.end, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _buildFooter(bool isDark, Color cardBg, Color textColor, Color hintColor, Color borderColor) {
    final progress = (_section + 1) / _sections.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
        border: Border(top: BorderSide(color: borderColor)),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF7C3AED)),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 12),
        if (_error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFCA5A5))),
            child: Row(children: [
              const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600))),
            ]),
          ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TextButton(
            onPressed: _section == 0 ? () => Navigator.pop(context) : _back,
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            child: Text(_section == 0 ? 'Cancel' : '← Back', style: TextStyle(color: hintColor, fontWeight: FontWeight.w600)),
          ),
          Text('Step ${_section + 1} of ${_sections.length}', style: TextStyle(fontSize: 12, color: hintColor)),
          _section < _sections.length - 1
              ? ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Next →', style: TextStyle(fontWeight: FontWeight.w700)),
                )
              : ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 16),
                  label: Text(_submitting ? 'Submitting...' : 'Submit Intake', style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
        ]),
      ]),
    );
  }

  Widget _buildSuccess(Color cardBg, Color textColor) => Padding(
    padding: const EdgeInsets.all(36),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
      ),
      const SizedBox(height: 20),
      Text('Intake Submitted!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
      const SizedBox(height: 8),
      Text(
        '${_nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'The client'} has been added to the pending queue. Our team will review and create their account, then find the perfect VA match.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.6), height: 1.5),
      ),
      const SizedBox(height: 28),
      ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    ]),
  );

  Widget _field(TextEditingController c, String hint, String placeholder, IconData icon, Color textColor, Color hintColor, Color borderColor, Color fieldBg, {TextInputType? type}) {
    return Container(
      decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: TextField(
        controller: c,
        keyboardType: type,
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

  Widget _area(TextEditingController c, String hint, Color textColor, Color hintColor, Color borderColor, Color fieldBg, {int rows = 4}) {
    return Container(
      decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: TextField(
        controller: c, maxLines: rows,
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

  Widget _label(String text, Color textColor) => Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor));
  Widget _hint(String text, Color hintColor) => Padding(padding: const EdgeInsets.only(top: 3), child: Text(text, style: TextStyle(fontSize: 11, color: hintColor, fontStyle: FontStyle.italic)));
  Widget _gap({double h = 14}) => SizedBox(height: h);
}

class _SectionInfo {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionInfo(this.title, this.icon, this.color);
}
