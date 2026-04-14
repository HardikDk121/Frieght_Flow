import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/models/driver.dart';
import '../../../core/models/freight_route.dart';
import '../../../core/models/truck.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/freight_app_bar.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/master_data_provider.dart';

class MasterDataScreen extends StatefulWidget {
  const MasterDataScreen({super.key});

  @override
  State<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends State<MasterDataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FreightAppBar(
        title: 'Master Data',
        subtitle: 'Manage trucks, drivers & routes',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add new',
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: Column(children: [
        Container(
          color: AppColors.cardBg,
          child: TabBar(
            controller: _tabs,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: const [
              Tab(text: 'Trucks'),
              Tab(text: 'Drivers'),
              Tab(text: 'Routes'),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              _TrucksTab(),
              _DriversTab(),
              _RoutesTab(),
            ],
          ),
        ),
      ]),
    );
  }

  void _showAddDialog(BuildContext context) {
    final idx = _tabs.index;
    if (idx == 0) _showAddTruckDialog(context);
    if (idx == 1) _showAddDriverDialog(context);
    if (idx == 2) _showAddRouteDialog(context);
  }
}

// ── Trucks Tab ────────────────────────────────────────────────────────────────

class _TrucksTab extends StatelessWidget {
  const _TrucksTab();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MasterDataProvider>();
    if (vm.isLoading && vm.trucks.isEmpty) {
      return ListView(padding: const EdgeInsets.all(16),
          children: List.generate(4, (_) => const ShimmerMasterRow()));
    }
    final trucks = vm.trucks;
    if (trucks.isEmpty) return _empty('No trucks added yet.');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trucks.length,
      itemBuilder: (_, i) => _TruckTile(truck: trucks[i]),
    );
  }
}

class _TruckTile extends StatelessWidget {
  final Truck truck;
  const _TruckTile({required this.truck});

  Color get _statusColor {
    switch (truck.status) {
      case TruckStatus.available:   return AppColors.success;
      case TruckStatus.onTrip:      return AppColors.info;
      case TruckStatus.maintenance: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.local_shipping_outlined, color: _statusColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(truck.vehicleNo,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text('${truck.make} ${truck.model}  ·  ${CurrencyFormatter.formatWeight(truck.capacityKg)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _pill(TruckStatusHelper.label(truck.status), _statusColor),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _showStatusMenu(context),
            child: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
          ),
        ]),
      ]),
    );
  }

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
  );

  void _showStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetCtx) => _TruckStatusSheet(truck: truck),
    );
  }
}

// Stateful sheet so selection updates in place without deprecated Radio groupValue
class _TruckStatusSheet extends StatefulWidget {
  final Truck truck;
  const _TruckStatusSheet({required this.truck});

  @override
  State<_TruckStatusSheet> createState() => _TruckStatusSheetState();
}

class _TruckStatusSheetState extends State<_TruckStatusSheet> {
  late TruckStatus _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.truck.status;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Update Status: ${widget.truck.vehicleNo}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        ...TruckStatus.values.map((s) => RadioListTile<TruckStatus>(
          contentPadding: EdgeInsets.zero,
          title: Text(TruckStatusHelper.label(s)),
          value: s,
          groupValue: _selected,
          activeColor: AppColors.primary,
          onChanged: (v) => setState(() => _selected = v ?? _selected),
        )),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              context.read<MasterDataProvider>().updateTruckStatus(widget.truck.id, _selected);
              Navigator.pop(context);
            },
            child: const Text('Update Status'),
          ),
        ),
        const Divider(height: 24),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.delete_outline, color: AppColors.danger),
          title: const Text('Delete Truck', style: TextStyle(color: AppColors.danger)),
          onTap: () {
            Navigator.pop(context);
            context.read<MasterDataProvider>().deleteTruck(widget.truck.id);
          },
        ),
      ]),
    );
  }
}

// ── Drivers Tab ───────────────────────────────────────────────────────────────

class _DriversTab extends StatelessWidget {
  const _DriversTab();

  @override
  Widget build(BuildContext context) {
    final drivers = context.watch<MasterDataProvider>().drivers;
    if (drivers.isEmpty) return _empty('No drivers added yet.');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: drivers.length,
      itemBuilder: (_, i) => _DriverTile(driver: drivers[i]),
    );
  }
}

class _DriverTile extends StatelessWidget {
  final Driver driver;
  const _DriverTile({required this.driver});

  @override
  Widget build(BuildContext context) {
    final color = driver.isAvailable ? AppColors.success : AppColors.info;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Text(
            driver.name.split(' ').map((w) => w[0]).take(2).join(),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(driver.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text('${driver.phone}  ·  ${driver.licenseNo}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(driver.isAvailable ? 'Available' : 'On Trip',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Driver'),
                  content: Text('Remove ${driver.name} from the system?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        context.read<MasterDataProvider>().deleteDriver(driver.id);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            child: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
          ),
        ]),
      ]),
    );
  }
}

// ── Routes Tab ────────────────────────────────────────────────────────────────

class _RoutesTab extends StatelessWidget {
  const _RoutesTab();

  @override
  Widget build(BuildContext context) {
    final routes = context.watch<MasterDataProvider>().routes;
    if (routes.isEmpty) return _empty('No routes added yet.');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: routes.length,
      itemBuilder: (_, i) => _RouteTile(route: routes[i]),
    );
  }
}

class _RouteTile extends StatelessWidget {
  final FreightRoute route;
  const _RouteTile({required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.route_outlined, color: AppColors.info, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(route.displayName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text('${route.distanceKm.toStringAsFixed(0)} km  ·  ₹${route.baseRatePerKg.toStringAsFixed(2)}/kg',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: route.isActive ? AppColors.successLight : AppColors.dangerLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            route.isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: route.isActive ? AppColors.success : AppColors.danger,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Shared empty state ────────────────────────────────────────────────────────

Widget _empty(String msg) {
  if (msg.contains('truck')) return const EmptyState.trucks();
  if (msg.contains('river'))  return const EmptyState.drivers();
  if (msg.contains('route'))  return const EmptyState.routes();
  return EmptyState(icon: Icons.inbox_outlined, title: 'Nothing here yet', subtitle: msg);
}

// ── Add Truck Dialog ──────────────────────────────────────────────────────────

void _showAddTruckDialog(BuildContext context) {
  final formKey     = GlobalKey<FormState>();
  final vehicleCtrl = TextEditingController();
  final makeCtrl    = TextEditingController();
  final modelCtrl   = TextEditingController();
  final capCtrl     = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Add Truck'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _dialogField(vehicleCtrl, 'Vehicle Number *', hint: 'GJ-03-XX-0000',
                formatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')), LengthLimitingTextInputFormatter(13)], // Allows GJ-03-XX-0000
                validator: AppValidators.vehicleNumber),
            const SizedBox(height: 12),
            _dialogField(makeCtrl, 'Make *', hint: 'Tata, Ashok Leyland…',
                validator: AppValidators.companyName),
            const SizedBox(height: 12),
            _dialogField(modelCtrl, 'Model *', hint: '407, 1109…'),
            const SizedBox(height: 12),
            _dialogField(capCtrl, 'Capacity (kg) *', hint: '4000',
                keyboardType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                validator: AppValidators.weightKg),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            await context.read<MasterDataProvider>().addTruck(
              vehicleNo:  vehicleCtrl.text.trim().toUpperCase(),
              make:       makeCtrl.text.trim(),
              model:      modelCtrl.text.trim(),
              capacityKg: double.parse(capCtrl.text),
              userId:     context.read<AuthProvider>().userId,
            );
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

// ── Add Driver Dialog ─────────────────────────────────────────────────────────

void _showAddDriverDialog(BuildContext context) {
  final formKey     = GlobalKey<FormState>();
  final nameCtrl    = TextEditingController();
  final licenseCtrl = TextEditingController();
  final phoneCtrl   = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Add Driver'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _dialogField(nameCtrl, 'Full Name *',
                validator: AppValidators.personName),
            const SizedBox(height: 12),
            _dialogField(licenseCtrl, 'License Number *', hint: 'GJ03-20180023412',
                validator: AppValidators.licenseNumber),
            const SizedBox(height: 12),
            _dialogField(phoneCtrl, 'Phone *',
                keyboardType: TextInputType.phone,
                formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                validator: AppValidators.indianPhone),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            await context.read<MasterDataProvider>().addDriver(
              name:       nameCtrl.text.trim(),
              licenseNo:  licenseCtrl.text.trim(),
              phone:      phoneCtrl.text.trim(),
              userId:     context.read<AuthProvider>().userId,
            );
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

// ── Add Route Dialog ──────────────────────────────────────────────────────────

void _showAddRouteDialog(BuildContext context) {
  final formKey    = GlobalKey<FormState>();
  final originCtrl = TextEditingController();
  final destCtrl   = TextEditingController();
  final distCtrl   = TextEditingController();
  final rateCtrl   = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Add Route'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _dialogField(originCtrl, 'Origin City *', hint: 'Rajkot'),
            const SizedBox(height: 12),
            _dialogField(destCtrl,   'Destination City *', hint: 'Mumbai'),
            const SizedBox(height: 12),
            _dialogField(distCtrl, 'Distance (km) *',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter valid distance' : null),
            const SizedBox(height: 12),
            _dialogField(rateCtrl, 'Base Rate (₹/kg) *',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter valid rate' : null),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            await context.read<MasterDataProvider>().addRoute(
              origin:       originCtrl.text.trim(),
              destination:  destCtrl.text.trim(),
              distanceKm:   double.parse(distCtrl.text),
              baseRatePerKg:double.parse(rateCtrl.text),
              userId:       context.read<AuthProvider>().userId,
            );
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

// ── Shared dialog field ───────────────────────────────────────────────────────

Widget _dialogField(
  TextEditingController ctrl,
  String label, {
  String? hint,
  TextInputType? keyboardType,
  List<TextInputFormatter>? formatters,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: ctrl,
    keyboardType: keyboardType,
    inputFormatters: formatters,
    decoration: InputDecoration(labelText: label, hintText: hint),
    validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
  );
}
