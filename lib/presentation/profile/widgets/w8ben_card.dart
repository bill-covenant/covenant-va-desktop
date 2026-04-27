import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:signature/signature.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/repositories/user_repository.dart';

class W8BenCard extends StatefulWidget {
  const W8BenCard({super.key});

  @override
  State<W8BenCard> createState() => _W8BenCardState();
}

class _W8BenCardState extends State<W8BenCard> {
  final UserRepository _repo = getIt<UserRepository>();
  Map<String, dynamic>? _form;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final form = await _repo.getW8BenForm();
      if (mounted) setState(() { _form = form; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('W-8BEN Tax Form',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    Text('Certificate of Foreign Status',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  ],
                ),
              ),
              if (!_loading)
                _StatusBadge(submitted: _form != null),
            ],
          ),
          const SizedBox(height: 20),

          if (_loading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          else if (_form != null)
            _SubmittedView(form: _form!, onResubmit: () => _openForm(prefill: _form))
          else
            _NotSubmittedView(onSubmit: () => _openForm()),
        ],
      ),
    );
  }

  Future<void> _openForm({Map<String, dynamic>? prefill}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => W8BenFormDialog(prefill: prefill, repo: _repo),
    );
    if (result == true) _load();
  }
}

// ── Status badge ────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool submitted;
  const _StatusBadge({required this.submitted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: submitted
            ? const Color(0xFF10B981).withOpacity(0.15)
            : const Color(0xFFF59E0B).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: submitted ? const Color(0xFF10B981).withOpacity(0.4) : const Color(0xFFF59E0B).withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            submitted ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 13,
            color: submitted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 5),
          Text(
            submitted ? 'Submitted' : 'Pending',
            style: TextStyle(
              color: submitted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Submitted view ───────────────────────────────────────────────────────────
class _SubmittedView extends StatelessWidget {
  final Map<String, dynamic> form;
  final VoidCallback onResubmit;
  const _SubmittedView({required this.form, required this.onResubmit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoRow('Country of Citizenship', form['countryOfCitizenship'] ?? '—'),
        const SizedBox(height: 8),
        _InfoRow('Date of Birth', form['dateOfBirth'] ?? '—'),
        const SizedBox(height: 8),
        _InfoRow('Address', '${form['permanentAddress']}, ${form['city']}, ${form['country']}'),
        const SizedBox(height: 8),
        _InfoRow('Submitted', _formatDate(form['submittedAt'])),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onResubmit,
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Update Form'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic val) {
    if (val == null) return '—';
    try {
      return DateTime.parse(val.toString())
          .toLocal()
          .toString()
          .substring(0, 10);
    } catch (_) {
      return val.toString();
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ── Not submitted view ───────────────────────────────────────────────────────
class _NotSubmittedView extends StatelessWidget {
  final VoidCallback onSubmit;
  const _NotSubmittedView({required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.25)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You have not submitted your W-8BEN form yet. This form is required for U.S. tax withholding purposes.',
                  style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.edit_document, size: 16),
            label: const Text('Fill Out W-8BEN Form'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// W-8BEN Form Dialog
// ══════════════════════════════════════════════════════════════════════════════

class W8BenFormDialog extends StatefulWidget {
  final Map<String, dynamic>? prefill;
  final UserRepository repo;
  const W8BenFormDialog({super.key, this.prefill, required this.repo});

  @override
  State<W8BenFormDialog> createState() => _W8BenFormDialogState();
}

class _W8BenFormDialogState extends State<W8BenFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Part I controllers
  late final TextEditingController _countryCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _postalCtrl;
  late final TextEditingController _countryAddrCtrl;
  late final TextEditingController _mailingAddressCtrl;
  late final TextEditingController _mailingCityCtrl;
  late final TextEditingController _mailingPostalCtrl;
  late final TextEditingController _mailingCountryCtrl;
  late final TextEditingController _usTaxIdCtrl;
  late final TextEditingController _foreignTaxIdCtrl;
  late final TextEditingController _refNumberCtrl;
  late final TextEditingController _dobCtrl;
  bool _ftinNotRequired = false;

  // Part II controllers
  late final TextEditingController _treatyCountryCtrl;
  late final TextEditingController _treatyArticleCtrl;
  late final TextEditingController _treatyParaCtrl;
  late final TextEditingController _withholdingRateCtrl;
  late final TextEditingController _incomeTypeCtrl;
  late final TextEditingController _additionalCondCtrl;

  // Signature
  final SignatureController _sigController = SignatureController(
    penStrokeWidth: 2.5,
    penColor: Colors.white,
    exportBackgroundColor: Colors.transparent,
  );

  bool _certified = false;
  bool _saving = false;
  String? _error;
  int _step = 0; // 0 = Part I, 1 = Part II, 2 = Sign & Certify

  @override
  void initState() {
    super.initState();
    final p = widget.prefill ?? {};
    _countryCtrl       = TextEditingController(text: p['countryOfCitizenship'] ?? '');
    _addressCtrl       = TextEditingController(text: p['permanentAddress'] ?? '');
    _cityCtrl          = TextEditingController(text: p['city'] ?? '');
    _postalCtrl        = TextEditingController(text: p['postalCode'] ?? '');
    _countryAddrCtrl   = TextEditingController(text: p['country'] ?? '');
    _mailingAddressCtrl= TextEditingController(text: p['mailingAddress'] ?? '');
    _mailingCityCtrl   = TextEditingController(text: p['mailingCity'] ?? '');
    _mailingPostalCtrl = TextEditingController(text: p['mailingPostalCode'] ?? '');
    _mailingCountryCtrl= TextEditingController(text: p['mailingCountry'] ?? '');
    _usTaxIdCtrl       = TextEditingController(text: p['usTaxId'] ?? '');
    _foreignTaxIdCtrl  = TextEditingController(text: p['foreignTaxId'] ?? '');
    _refNumberCtrl     = TextEditingController(text: p['referenceNumber'] ?? '');
    _dobCtrl           = TextEditingController(text: p['dateOfBirth'] ?? '');
    _ftinNotRequired   = p['fTINNotRequired'] ?? false;

    _treatyCountryCtrl  = TextEditingController(text: p['treatyCountry'] ?? '');
    _treatyArticleCtrl  = TextEditingController(text: p['treatyArticle'] ?? '');
    _treatyParaCtrl     = TextEditingController(text: p['treatyParagraph'] ?? '');
    _withholdingRateCtrl= TextEditingController(text: p['withholdingRate'] ?? '');
    _incomeTypeCtrl     = TextEditingController(text: p['incomeType'] ?? '');
    _additionalCondCtrl = TextEditingController(text: p['additionalConditions'] ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _countryCtrl, _addressCtrl, _cityCtrl, _postalCtrl, _countryAddrCtrl,
      _mailingAddressCtrl, _mailingCityCtrl, _mailingPostalCtrl, _mailingCountryCtrl,
      _usTaxIdCtrl, _foreignTaxIdCtrl, _refNumberCtrl, _dobCtrl,
      _treatyCountryCtrl, _treatyArticleCtrl, _treatyParaCtrl,
      _withholdingRateCtrl, _incomeTypeCtrl, _additionalCondCtrl,
    ]) { c.dispose(); }
    _sigController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sigController.isEmpty) {
      setState(() => _error = 'Please sign the form before submitting.');
      return;
    }
    if (!_certified) {
      setState(() => _error = 'Please check the certification checkbox.');
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      // Export signature as PNG bytes then base64
      final sigImage = await _sigController.toImage();
      final byteData = await sigImage!.toByteData(format: ui.ImageByteFormat.png);
      final sigBase64 = 'data:image/png;base64,${base64Encode(byteData!.buffer.asUint8List())}';

      final today = DateTime.now();
      final dateStr =
          '${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}-${today.year}';

      await widget.repo.submitW8BenForm({
        'countryOfCitizenship': _countryCtrl.text.trim(),
        'permanentAddress': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'postalCode': _postalCtrl.text.trim(),
        'country': _countryAddrCtrl.text.trim(),
        'mailingAddress': _mailingAddressCtrl.text.trim().isEmpty ? null : _mailingAddressCtrl.text.trim(),
        'mailingCity': _mailingCityCtrl.text.trim().isEmpty ? null : _mailingCityCtrl.text.trim(),
        'mailingPostalCode': _mailingPostalCtrl.text.trim().isEmpty ? null : _mailingPostalCtrl.text.trim(),
        'mailingCountry': _mailingCountryCtrl.text.trim().isEmpty ? null : _mailingCountryCtrl.text.trim(),
        'usTaxId': _usTaxIdCtrl.text.trim().isEmpty ? null : _usTaxIdCtrl.text.trim(),
        'foreignTaxId': _foreignTaxIdCtrl.text.trim().isEmpty ? null : _foreignTaxIdCtrl.text.trim(),
        'fTINNotRequired': _ftinNotRequired,
        'referenceNumber': _refNumberCtrl.text.trim().isEmpty ? null : _refNumberCtrl.text.trim(),
        'dateOfBirth': _dobCtrl.text.trim(),
        'treatyCountry': _treatyCountryCtrl.text.trim().isEmpty ? null : _treatyCountryCtrl.text.trim(),
        'treatyArticle': _treatyArticleCtrl.text.trim().isEmpty ? null : _treatyArticleCtrl.text.trim(),
        'treatyParagraph': _treatyParaCtrl.text.trim().isEmpty ? null : _treatyParaCtrl.text.trim(),
        'withholdingRate': _withholdingRateCtrl.text.trim().isEmpty ? null : _withholdingRateCtrl.text.trim(),
        'incomeType': _incomeTypeCtrl.text.trim().isEmpty ? null : _incomeTypeCtrl.text.trim(),
        'additionalConditions': _additionalCondCtrl.text.trim().isEmpty ? null : _additionalCondCtrl.text.trim(),
        'signatureData': sigBase64,
        'certificationDate': dateStr,
      });

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() { _error = 'Failed to submit: ${e.toString()}'; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Container(
        width: 640,
        constraints: const BoxConstraints(maxHeight: 720),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1226),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 40, offset: const Offset(0, 20)),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Form W-8BEN', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                        Text('Certificate of Foreign Status — IRS', style: TextStyle(color: Color(0xFFC4B5FD), fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                  ),
                ],
              ),
            ),

            // Step indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  _StepDot(label: 'Part I', active: _step == 0, done: _step > 0),
                  _StepLine(done: _step > 0),
                  _StepDot(label: 'Part II', active: _step == 1, done: _step > 1),
                  _StepLine(done: _step > 1),
                  _StepDot(label: 'Sign & Certify', active: _step == 2, done: false),
                ],
              ),
            ),

            // Form content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _step == 0
                      ? _buildPartI()
                      : _step == 1
                          ? _buildPartII()
                          : _buildPartIII(),
                ),
              ),
            ),

            // Error
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
                    ],
                  ),
                ),
              ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() { _step--; _error = null; }),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saving ? null : (_step < 2 ? _nextStep : _submit),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      child: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_step < 2 ? 'Continue' : 'Submit Form'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    if (_step == 0 && !_formKey.currentState!.validate()) return;
    setState(() { _step++; _error = null; });
  }

  Widget _buildPartI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Part I — Identification of Beneficial Owner'),
        const SizedBox(height: 16),
        _field('1 — Country of Citizenship *', _countryCtrl, hint: 'e.g. Philippines', required: true),
        const SizedBox(height: 12),
        _field('3 — Permanent Residence Address *', _addressCtrl, hint: 'Street, apt. or suite no.', required: true),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _field('City / Town *', _cityCtrl, hint: 'City', required: true)),
          const SizedBox(width: 10),
          Expanded(child: _field('Postal Code', _postalCtrl, hint: 'Postal code')),
          const SizedBox(width: 10),
          Expanded(child: _field('Country *', _countryAddrCtrl, hint: 'Country', required: true)),
        ]),
        const SizedBox(height: 12),
        _field('4 — Mailing Address (if different)', _mailingAddressCtrl, hint: 'Leave blank if same as above'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _field('Mailing City', _mailingCityCtrl, hint: 'City')),
          const SizedBox(width: 10),
          Expanded(child: _field('Mailing Postal', _mailingPostalCtrl, hint: 'Postal code')),
          const SizedBox(width: 10),
          Expanded(child: _field('Mailing Country', _mailingCountryCtrl, hint: 'Country')),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _field('5 — U.S. Taxpayer ID (SSN/ITIN)', _usTaxIdCtrl, hint: 'If applicable')),
          const SizedBox(width: 10),
          Expanded(child: _field('6a — Foreign Tax ID', _foreignTaxIdCtrl, hint: 'If applicable', enabled: !_ftinNotRequired)),
        ]),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _ftinNotRequired,
              onChanged: (v) => setState(() { _ftinNotRequired = v ?? false; if (_ftinNotRequired) _foreignTaxIdCtrl.clear(); }),
              fillColor: WidgetStateProperty.resolveWith((s) =>
                  s.contains(WidgetState.selected) ? const Color(0xFF6366F1) : Colors.transparent),
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            const Text('6b — FTIN not legally required', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _field('7 — Reference Number(s)', _refNumberCtrl, hint: 'Optional')),
          const SizedBox(width: 10),
          Expanded(child: _field('8 — Date of Birth (MM-DD-YYYY) *', _dobCtrl, hint: 'MM-DD-YYYY', required: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              final reg = RegExp(r'^\d{2}-\d{2}-\d{4}$');
              if (!reg.hasMatch(v)) return 'Format: MM-DD-YYYY';
              return null;
            },
          )),
        ]),
      ],
    );
  }

  Widget _buildPartII() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Part II — Claim of Tax Treaty Benefits'),
        const SizedBox(height: 4),
        const Text('Optional. Fill out only if you are claiming tax treaty benefits.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        const SizedBox(height: 16),
        _field('9 — Treaty Country', _treatyCountryCtrl, hint: 'Country with U.S. tax treaty'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _field('Article', _treatyArticleCtrl, hint: 'Article number')),
          const SizedBox(width: 10),
          Expanded(child: _field('Paragraph', _treatyParaCtrl, hint: 'Paragraph')),
          const SizedBox(width: 10),
          Expanded(child: _field('Withholding Rate (%)', _withholdingRateCtrl, hint: 'e.g. 0')),
        ]),
        const SizedBox(height: 12),
        _field('Type of Income', _incomeTypeCtrl, hint: 'e.g. Services, Royalties'),
        const SizedBox(height: 12),
        _field('Additional Conditions', _additionalCondCtrl, hint: 'Explain eligibility conditions', maxLines: 3),
      ],
    );
  }

  Widget _buildPartIII() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Part III — Certification & Signature'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: const Text(
            'Under penalties of perjury, I declare that I have examined the information on this form and to the '
            'best of my knowledge and belief it is true, correct, and complete. I certify that I am the individual '
            'that is the beneficial owner of all the income to which this form relates and that I am not a U.S. person.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, height: 1.6),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Draw your signature below:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2235),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Signature(
              controller: _sigController,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _sigController.clear(),
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('Clear Signature', style: TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _certified,
              onChanged: (v) => setState(() => _certified = v ?? false),
              fillColor: WidgetStateProperty.resolveWith((s) =>
                  s.contains(WidgetState.selected) ? const Color(0xFF6366F1) : Colors.transparent),
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            const Expanded(
              child: Text(
                'I certify that I have the capacity to sign for the person identified on line 1 of this form.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF4F46E5).withOpacity(0.3), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: const Color(0xFF6366F1), width: 3)),
      ),
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {
    String? hint, bool required = false, int maxLines = 1,
    String? Function(String?)? validator, bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        TextFormField(
          controller: ctrl,
          enabled: enabled,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12),
            filled: true,
            fillColor: enabled ? const Color(0xFF1E2235) : const Color(0xFF161828),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            errorStyle: const TextStyle(fontSize: 10),
          ),
          validator: validator ?? (required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null),
        ),
      ],
    );
  }
}

// ── Step indicator dots ──────────────────────────────────────────────────────
class _StepDot extends StatelessWidget {
  final String label;
  final bool active;
  final bool done;
  const _StepDot({required this.label, required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    final color = done
        ? const Color(0xFF10B981)
        : active
            ? const Color(0xFF6366F1)
            : const Color(0xFF374151);
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: active ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)] : [],
          ),
          child: Icon(
            done ? Icons.check_rounded : Icons.circle,
            size: done ? 16 : 8,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: active ? Colors.white : const Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool done;
  const _StepLine({required this.done});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: done ? const Color(0xFF10B981) : const Color(0xFF1F2937),
      ),
    );
  }
}
