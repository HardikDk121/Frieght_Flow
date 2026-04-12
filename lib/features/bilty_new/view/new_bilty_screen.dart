import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/models/bilty.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/bilty_provider.dart';
import '../../../providers/master_data_provider.dart';

class NewBiltyScreen extends StatefulWidget {
  const NewBiltyScreen({super.key});

  @override
  State<NewBiltyScreen> createState() => _NewBiltyScreenState();
}

class _NewBiltyScreenState extends State<NewBiltyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _consignorNameCtrl  = TextEditingController();
  final _consignorPhoneCtrl = TextEditingController();
  final _consignorGstCtrl   = TextEditingController();
  final _consigneeNameCtrl  = TextEditingController();
  final _consigneePhoneCtrl = TextEditingController();
  final _consigneeGstCtrl   = TextEditingController();
  final _goodsDescCtrl      = TextEditingController();
  final _weightCtrl         = TextEditingController();
  final _packagesCtrl       = TextEditingController();
  final _rateCtrl           = TextEditingController();

  String?     _selectedRouteId;
  String?     _selectedCategory;
  PaymentType _paymentType = PaymentType.toPay;
  bool        _submitting  = false;

  static const _categories = [
    'General Cargo', 'Fragile / Glassware', 'Perishable / Cold Chain',
    'Hazardous Material', 'Machinery & Equipment', 'Textiles & Garments',
    'Agricultural Produce',
  ];

  double get _weightPerPkg => double.tryParse(_weightCtrl.text) ?? 0;
  int    get _packages     => int.tryParse(_packagesCtrl.text) ?? 0;
  double get _totalWeightKg=> _weightPerPkg * _packages;
  double get _totalWeightMT=> _totalWeightKg / 1000;
  double get _baseFreight  => _totalWeightKg * (double.tryParse(_rateCtrl.text) ?? 0);
  double get _gst          => _baseFreight * 0.18;
  double get _totalFreight => _baseFreight + _gst;

  @override
  void dispose() {
    for (final c in [_consignorNameCtrl, _consignorPhoneCtrl, _consignorGstCtrl,
        _consigneeNameCtrl, _consigneePhoneCtrl, _consigneeGstCtrl,
        _goodsDescCtrl, _weightCtrl, _packagesCtrl, _rateCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routes = context.watch<MasterDataProvider>().routes;
    // Derive destination city from selected route — no separate field needed
    final selectedRoute = _selectedRouteId != null
        ? context.read<MasterDataProvider>().routeById(_selectedRouteId!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('New Bilty'),
          Text('Create consignment note',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textSecondary)),
        ]),
        titleSpacing: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Route (destination auto-derived) ─────────────────────────
            _section('Route & Destination'),
            _AppDropdown<String>(
              label: 'Select Route *',
              icon: Icons.route_outlined,
              value: _selectedRouteId,
              items: routes.map((r) => DropdownMenuItem(
                value: r.id,
                child: Text(r.displayName),
              )).toList(),
              onChanged: (v) {
                setState(() => _selectedRouteId = v);
                final route = context.read<MasterDataProvider>().routeById(v!);
                if (route != null) _rateCtrl.text = route.baseRatePerKg.toStringAsFixed(2);
              },
              validator: (v) => v == null ? 'Please select a route' : null,
            ),

            // Route-derived info chip — replaces the old "Destination City" field
            if (selectedRoute != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: RichText(text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Poppins'),
                    children: [
                      const TextSpan(text: 'From '),
                      TextSpan(text: selectedRoute.origin, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                      const TextSpan(text: '  →  '),
                      TextSpan(text: selectedRoute.destination, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success)),
                      TextSpan(text: '  (${selectedRoute.distanceKm.toStringAsFixed(0)} km)',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ))),
                ]),
              ),
            ],

            // ── Consignor ─────────────────────────────────────────────────
            _section('Consignor (Sender)'),
            _AppTextField(
              controller: _consignorNameCtrl,
              label: 'Company / Person Name *',
              icon: Icons.business_outlined,
              validator: AppValidators.companyName,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _AppTextField(
                controller: _consignorPhoneCtrl,
                label: 'Phone *',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                validator: AppValidators.indianPhone,
              )),
              const SizedBox(width: 12),
              Expanded(child: _AppTextField(
                controller: _consignorGstCtrl,
                label: 'GST Number *',
                icon: Icons.receipt_outlined,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), LengthLimitingTextInputFormatter(15)],
                validator: AppValidators.gstNumber,
              )),
            ]),

            // ── Consignee ─────────────────────────────────────────────────
            _section('Consignee (Receiver)'),
            _AppTextField(
              controller: _consigneeNameCtrl,
              label: 'Company / Person Name *',
              icon: Icons.person_outline,
              validator: AppValidators.companyName,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _AppTextField(
                controller: _consigneePhoneCtrl,
                label: 'Phone *',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                validator: AppValidators.indianPhone,
              )),
              const SizedBox(width: 12),
              Expanded(child: _AppTextField(
                controller: _consigneeGstCtrl,
                label: 'GST Number *',
                icon: Icons.receipt_outlined,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), LengthLimitingTextInputFormatter(15)],
                validator: AppValidators.gstNumber,
              )),
            ]),
            // NOTE: No "Destination City" field — it's auto-derived from the route above

            // ── Goods ─────────────────────────────────────────────────────
            _section('Goods Details'),
            _AppTextField(
              controller: _goodsDescCtrl,
              label: 'Goods Description *',
              icon: Icons.inventory_2_outlined,
              validator: (v) => AppValidators.required(v, fieldName: 'Goods description'),
            ),
            const SizedBox(height: 12),
            _AppDropdown<String>(
              label: 'Category *',
              icon: Icons.category_outlined,
              value: _selectedCategory,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Select a category' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _AppTextField(
                controller: _weightCtrl,
                label: 'Wt / Package (kg) *',
                icon: Icons.scale_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                onChanged: (_) => setState(() {}),
                validator: AppValidators.weightKg,
              )),
              const SizedBox(width: 12),
              Expanded(child: _AppTextField(
                controller: _packagesCtrl,
                label: 'Packages *',
                icon: Icons.widgets_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                validator: AppValidators.packageCount,
              )),
            ]),
            const SizedBox(height: 12),
            _AppTextField(
              controller: _rateCtrl,
              label: 'Freight Rate (₹/kg) *',
              icon: Icons.currency_rupee,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              onChanged: (_) => setState(() {}),
              validator: AppValidators.freightRate,
            ),

            // ── Freight preview ────────────────────────────────────────────
            if (_baseFreight > 0) ...[
              const SizedBox(height: 12),
              _FreightPreviewCard(
                base: _baseFreight, gst: _gst, total: _totalFreight,
                totalWeightKg: _totalWeightKg, totalWeightMT: _totalWeightMT,
              ),
            ],

            // ── Payment ────────────────────────────────────────────────────
            _section('Payment Type'),
            _PaymentSelector(selected: _paymentType, onChanged: (t) => setState(() => _paymentType = t)),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label: Text(_submitting ? 'Saving...' : 'Create Bilty'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Row(children: [
      Container(width: 3, height: 14, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: AppColors.textSecondary, letterSpacing: 0.6)),
    ]),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    // Derive consignee city from route destination
    final route = context.read<MasterDataProvider>().routeById(_selectedRouteId!);
    final consigneeCity = route?.destination ?? '';

    final ok = await context.read<BiltyProvider>().addBilty(
      routeId:          _selectedRouteId!,
      consignorName:    _consignorNameCtrl.text.trim(),
      consignorPhone:   _consignorPhoneCtrl.text.trim(),
      consignorGst:     _consignorGstCtrl.text.trim().toUpperCase(),
      consigneeName:    _consigneeNameCtrl.text.trim(),
      consigneePhone:   _consigneePhoneCtrl.text.trim(),
      consigneeGst:     _consigneeGstCtrl.text.trim().toUpperCase(),
      consigneeCity:    consigneeCity,
      goodsDescription: _goodsDescCtrl.text.trim(),
      goodsCategory:    _selectedCategory!,
      weightKg:         _totalWeightKg,
      noOfPackages:     int.parse(_packagesCtrl.text),
      freightPerKg:     double.parse(_rateCtrl.text),
      paymentType:      _paymentType,
      createdBy:        context.read<AuthProvider>().userId,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bilty created successfully!'),
        backgroundColor: AppColors.success,
      ));
      Navigator.pop(context);
    }
  }
}

// ── Polished reusable dropdown ────────────────────────────────────────────────

class _AppDropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const _AppDropdown({
    required this.label, required this.icon, required this.value,
    required this.items, required this.onChanged, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
    );
  }
}

// ── Polished text field ───────────────────────────────────────────────────────

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const _AppTextField({
    required this.controller, required this.label, required this.icon,
    this.keyboardType, this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.validator, this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}

// ── Freight preview card ──────────────────────────────────────────────────────

class _FreightPreviewCard extends StatelessWidget {
  final double base, gst, total, totalWeightKg, totalWeightMT;
  const _FreightPreviewCard({
    required this.base, required this.gst, required this.total,
    required this.totalWeightKg, required this.totalWeightMT,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.gradBlue, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        // Row 1: Weight info
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _item('Total Weight', '${totalWeightKg.toStringAsFixed(0)} kg'),
          const SizedBox(width: 16),
          Container(width: 1, height: 24, color: Colors.white30),
          const SizedBox(width: 16),
          _item('Weight (MT)', '${totalWeightMT.toStringAsFixed(3)} MT'),
        ]),
        const SizedBox(height: 10),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
        const SizedBox(height: 10),
        // Row 2: Freight breakdown
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _item('Base Freight', '\u20b9${base.toStringAsFixed(0)}'),
          Container(width: 1, height: 32, color: Colors.white30),
          _item('GST @ 18%', '\u20b9${gst.toStringAsFixed(0)}'),
          Container(width: 1, height: 32, color: Colors.white30),
          _item('Total', '\u20b9${total.toStringAsFixed(0)}', large: true),
        ]),
      ]),
    );
  }

  Widget _item(String l, String v, {bool large = false}) => Column(children: [
    Text(l, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10)),
    const SizedBox(height: 3),
    Text(v, style: TextStyle(color: Colors.white, fontSize: large ? 16 : 13, fontWeight: FontWeight.w700)),
  ]);
}

// ── Payment selector ──────────────────────────────────────────────────────────

class _PaymentSelector extends StatelessWidget {
  final PaymentType selected;
  final ValueChanged<PaymentType> onChanged;
  const _PaymentSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: PaymentType.values.map((t) {
      final isSel = selected == t;
      return Expanded(child: GestureDetector(
        onTap: () => onChanged(t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSel ? AppColors.primary : AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSel ? AppColors.primary : AppColors.divider),
          ),
          child: Text(PaymentTypeHelper.label(t),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isSel ? Colors.white : AppColors.textSecondary)),
        ),
      ));
    }).toList());
  }
}
