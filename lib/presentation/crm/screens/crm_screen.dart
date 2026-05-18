import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/crm_bloc.dart';
import '../bloc/crm_event.dart';
import '../bloc/crm_state.dart';
import '../../../data/models/crm_customer_model.dart';
import '../../../data/models/crm_branch_model.dart';

class CrmScreen extends StatefulWidget {
  const CrmScreen({super.key});

  @override
  State<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends State<CrmScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    context.read<CrmBloc>().add(const CrmLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CrmBloc, CrmState>(
      listener: (context, state) {
        if (state is CrmLoaded && state.actionMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.actionMessage!),
            backgroundColor: const Color(0xFF7C3AED),
            behavior: SnackBarBehavior.floating,
          ));
        }
        if (state is CrmError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0F172A),
                  const Color(0xFF1E1B4B).withOpacity(0.8),
                  const Color(0xFF0F172A),
                ],
              ),
            ),
            child: Column(
              children: [
                _buildHeader(context, state),
                if (state is CrmLoaded) ...[
                  _buildSearchBar(),
                  Expanded(child: _buildCustomerList(context, state)),
                ] else if (state is CrmLoading) ...[
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                    ),
                  ),
                ] else if (state is CrmError) ...[
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                          const SizedBox(height: 12),
                          Text(state.message, style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.read<CrmBloc>().add(const CrmLoadRequested()),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const Expanded(child: SizedBox()),
                ],
              ],
            ),
          ),
          floatingActionButton: state is CrmLoaded
              ? FloatingActionButton.extended(
                  onPressed: () => _showCustomerForm(context, state.branches),
                  backgroundColor: const Color(0xFF7C3AED),
                  icon: const Icon(Icons.person_add_rounded, color: Colors.white),
                  label: const Text('Add Customer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                )
              : null,
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, CrmState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.people_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Flooring Liquidators',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  state is CrmLoaded
                      ? '${state.customers.length} customer${state.customers.length == 1 ? '' : 's'}'
                      : 'Customer inquiries & branch notifications',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.read<CrmBloc>().add(const CrmLoadRequested()),
            icon: Icon(Icons.refresh_rounded, color: Colors.white.withOpacity(0.6)),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search customers...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.4)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF7C3AED)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCustomerList(BuildContext context, CrmLoaded state) {
    final q = _search.toLowerCase();
    final filtered = state.customers.where((c) {
      if (q.isEmpty) return true;
      return c.fullName.toLowerCase().contains(q) ||
          (c.email?.toLowerCase().contains(q) ?? false) ||
          (c.company?.toLowerCase().contains(q) ?? false) ||
          (c.branch?.name.toLowerCase().contains(q) ?? false);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, color: Colors.white.withOpacity(0.2), size: 64),
            const SizedBox(height: 16),
            Text(
              _search.isEmpty ? 'No customers yet' : 'No results for "$_search"',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16),
            ),
            if (_search.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Tap + Add Customer to log your first customer',
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 100),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildCustomerCard(context, filtered[index], state);
      },
    );
  }

  Widget _buildCustomerCard(BuildContext context, CrmCustomerModel customer, CrmLoaded state) {
    final isNotifying = state.isNotifying && state.notifyingCustomerId == customer.id;
    final hasNotified = customer.notifiedAt != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${customer.firstName[0]}${customer.lastName[0]}'.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (customer.company != null)
                        Text(
                          customer.company!,
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _showCustomerForm(context, state.branches, customer: customer);
                    if (v == 'delete') _confirmDelete(context, customer);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 16), SizedBox(width: 8), Text('Edit')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 16, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                  ],
                  color: const Color(0xFF1E1B4B),
                  icon: Icon(Icons.more_vert_rounded, color: Colors.white.withOpacity(0.4)),
                ),
              ],
            ),
            if (customer.email != null || customer.phone != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (customer.email != null)
                    _chip(Icons.email_rounded, customer.email!),
                  if (customer.phone != null)
                    _chip(Icons.phone_rounded, customer.phone!),
                ],
              ),
            ],
            if (customer.branch != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.store_rounded, size: 14, color: const Color(0xFF7C3AED).withOpacity(0.8)),
                  const SizedBox(width: 6),
                  Text(
                    customer.branch!.name,
                    style: TextStyle(color: const Color(0xFF7C3AED).withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            if (customer.orderDetails != null && customer.orderDetails!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 14, color: Colors.white.withOpacity(0.4)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        customer.orderDetails!,
                        style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12, height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (hasNotified)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF166534).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF166534).withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF4ADE80)),
                          const SizedBox(width: 6),
                          Text(
                            'Notified ${_formatDate(customer.notifiedAt!)}',
                            style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
                if (hasNotified) const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: customer.branch == null || isNotifying
                      ? null
                      : () => _confirmNotify(context, customer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    disabledBackgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: isNotifying
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 14),
                  label: Text(
                    customer.branch == null ? 'No Branch' : (hasNotified ? 'Re-notify' : 'Notify Branch'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withOpacity(0.4)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  void _confirmNotify(BuildContext context, CrmCustomerModel customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Notify Branch?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Send an email to ${customer.branch!.name} (${customer.branch!.email}) with ${customer.fullName}\'s details?',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CrmBloc>().add(CrmNotifyBranchRequested(customerId: customer.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, CrmCustomerModel customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Customer?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Remove ${customer.fullName} from your CRM? This cannot be undone.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CrmBloc>().add(CrmCustomerDeleteRequested(id: customer.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCustomerForm(BuildContext context, List<CrmBranchModel> branches, {CrmCustomerModel? customer}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CustomerFormDialog(
        branches: branches,
        customer: customer,
        onSave: (data) {
          if (customer == null) {
            context.read<CrmBloc>().add(CrmCustomerCreateRequested(
              firstName: data['firstName'],
              lastName: data['lastName'],
              email: data['email'],
              phone: data['phone'],
              company: data['company'],
              branchId: data['branchId'],
              orderDetails: data['orderDetails'],
              notes: data['notes'],
            ));
          } else {
            context.read<CrmBloc>().add(CrmCustomerUpdateRequested(id: customer.id, data: data));
          }
        },
      ),
    );
  }
}

class _CustomerFormDialog extends StatefulWidget {
  final List<CrmBranchModel> branches;
  final CrmCustomerModel? customer;
  final void Function(Map<String, dynamic>) onSave;

  const _CustomerFormDialog({
    required this.branches,
    required this.onSave,
    this.customer,
  });

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _company;
  late final TextEditingController _orderDetails;
  late final TextEditingController _notes;
  String? _selectedBranchId;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _firstName = TextEditingController(text: c?.firstName ?? '');
    _lastName = TextEditingController(text: c?.lastName ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _company = TextEditingController(text: c?.company ?? '');
    _orderDetails = TextEditingController(text: c?.orderDetails ?? '');
    _notes = TextEditingController(text: c?.notes ?? '');
    _selectedBranchId = c?.branchId;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _company.dispose();
    _orderDetails.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.customer != null;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 680),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.25),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Text(
                    isEdit ? 'Edit Customer' : 'New Customer',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _field('First Name *', _firstName, required: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _field('Last Name *', _lastName, required: true)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _field('Email', _email)),
                          const SizedBox(width: 12),
                          Expanded(child: _field('Phone', _phone)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _field('Company / Business', _company),
                      const SizedBox(height: 12),
                      _buildBranchDropdown(),
                      const SizedBox(height: 12),
                      _field('Order / Request Details', _orderDetails, maxLines: 3),
                      const SizedBox(height: 12),
                      _field('Notes', _notes, maxLines: 2),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        isEdit ? 'Save Changes' : 'Add Customer',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
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

  Widget _field(String label, TextEditingController controller, {bool required = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
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
              borderSide: const BorderSide(color: Color(0xFF7C3AED)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildBranchDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nearest Branch', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String?>(
          value: _selectedBranchId,
          dropdownColor: const Color(0xFF1E1B4B),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          hint: Text('Select a branch', style: TextStyle(color: Colors.white.withOpacity(0.4))),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
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
              borderSide: const BorderSide(color: Color(0xFF7C3AED)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('No branch', style: TextStyle(color: Colors.white.withOpacity(0.4))),
            ),
            ...widget.branches.map((b) => DropdownMenuItem<String?>(
              value: b.id,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(b.name),
                  if (b.location != null)
                    Text(b.location!, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
                ],
              ),
            )),
          ],
          onChanged: (v) => setState(() => _selectedBranchId = v),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context);
    widget.onSave({
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
      'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'company': _company.text.trim().isEmpty ? null : _company.text.trim(),
      'branchId': _selectedBranchId,
      'orderDetails': _orderDetails.text.trim().isEmpty ? null : _orderDetails.text.trim(),
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    });
  }
}
