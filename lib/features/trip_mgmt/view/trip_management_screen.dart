import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/models/trip.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/freight_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/shimmer_loader.dart';
import 'widgets/live_map_widget.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/challan_provider.dart';
import '../../../providers/master_data_provider.dart';
import '../../../providers/trip_management_provider.dart';

// ── Trip List Screen ──────────────────────────────────────────────────────────

class TripManagementScreen extends StatelessWidget {
  const TripManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TripManagementProvider>();

    return Scaffold(
      appBar: const FreightAppBar(title: 'Trip Management', subtitle: 'Track and update trip status'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/trip-new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Trip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: vm.trips.isEmpty
          ? _empty(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.trips.length,
              itemBuilder: (_, i) => _TripCard(trip: vm.trips[i]),
            ),
    );
  }

  Widget _empty(BuildContext context) => EmptyState.trips(
    onAdd: () => Navigator.pushNamed(context, '/trip-new'),
  );
}

// ── Trip Card (list item) ─────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final Trip trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final vm     = context.read<TripManagementProvider>();
    final route  = vm.routeForTrip(trip);
    final truck  = vm.truckForTrip(trip);
    final driver = vm.driverForTrip(trip);

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(trip.tripNo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
                const SizedBox(height: 3),
                Text(route?.displayName ?? '—', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              ])),
              _StatePill(state: trip.state),
            ]),
          ),
          // State stepper
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _TripStepper(state: trip.state),
          ),
          // Footer row
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
            ),
            child: Row(children: [
              _chip(Icons.local_shipping_outlined, truck?.vehicleNo ?? '—'),
              const SizedBox(width: 12),
              _chip(Icons.person_outline, driver?.name ?? '—'),
              const Spacer(),
              if (!TripStateHelper.isTerminal(trip.state))
                TextButton(
                  onPressed: () => _openDetail(context),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), minimumSize: Size.zero),
                  child: const Row(children: [
                    Text('Update', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                  ]),
                ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Row(children: [
    Icon(icon, size: 13, color: AppColors.textMuted),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
  ]);

  void _openDetail(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: trip.id)));
  }
}

// ── Trip Detail / State Machine Screen ───────────────────────────────────────

class TripDetailScreen extends StatelessWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    final vm   = context.watch<TripManagementProvider>();
    final trip = vm.trips.firstWhere((t) => t.id == tripId, orElse: () => vm.trips.first);
    final route  = vm.routeForTrip(trip);
    final truck  = vm.truckForTrip(trip);
    final driver = vm.driverForTrip(trip);
    final bilties= vm.biltiesForTrip(trip);

    return Scaffold(
      appBar: FreightAppBar(title: trip.tripNo, subtitle: route?.displayName ?? ''),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // State machine card
          _StateCard(trip: trip),
          const SizedBox(height: 16),
          // Live map (shown when trip is not at godown)
          if (trip.state != TripState.godown && route != null) ...[
            _sectionTitle('Live Tracking'),
            const SizedBox(height: 10),
            LiveMapWidget(trip: trip, route: route),
            const SizedBox(height: 16),
          ],
          // Trip info
          _sectionTitle('Trip Details'),
          const SizedBox(height: 10),
          _infoGrid([
            ('Truck',      truck?.vehicleNo  ?? '—', Icons.local_shipping_outlined),
            ('Driver',     driver?.name      ?? '—', Icons.person_outline),
            ('Capacity',   truck != null ? CurrencyFormatter.formatWeight(truck.capacityKg) : '—', Icons.scale_outlined),
            ('Scheduled',  DateFormat('dd MMM yyyy').format(trip.scheduledDate), Icons.calendar_today_outlined),
            if (trip.actualDispatchDate != null)
              ('Dispatched', DateFormat('dd MMM').format(trip.actualDispatchDate!), Icons.departure_board_outlined),
            if (trip.actualDeliveryDate != null)
              ('Delivered', DateFormat('dd MMM').format(trip.actualDeliveryDate!), Icons.check_circle_outline),
          ]),
          const SizedBox(height: 16),
          // Bilties
          _sectionTitle('Loaded Bilties (${bilties.length})'),
          const SizedBox(height: 10),
          ...bilties.map((b) => _BiltyRow(bilty: b)),
          const SizedBox(height: 16),
          // History
          if (trip.stateHistory.isNotEmpty) ...[
            _sectionTitle('State History'),
            const SizedBox(height: 10),
            _StateHistory(history: trip.stateHistory),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3));

  Widget _infoGrid(List<(String, String, IconData)> items) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: items.map((item) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(children: [
          Icon(item.$3, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(item.$1, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(item.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          ])),
        ]),
      )).toList(),
    );
  }
}

// ── State machine card ─────────────────────────────────────────────────────

class _StateCard extends StatefulWidget {
  final Trip trip;
  const _StateCard({required this.trip});

  @override
  State<_StateCard> createState() => _StateCardState();
}

class _StateCardState extends State<_StateCard> {
  TripState? _selectedNext;

  @override
  Widget build(BuildContext context) {
    final vm          = context.watch<TripManagementProvider>();
    final nextStates  = TripStateHelper.nextStates(widget.trip.state);
    final isTerminal  = TripStateHelper.isTerminal(widget.trip.state);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            const Text('Current Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const Spacer(),
            _StatePill(state: widget.trip.state),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _TripStepper(state: widget.trip.state),
        ),
        if (!isTerminal) ...[
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Advance Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              ...nextStates.map((s) => _nextStateTile(s)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_selectedNext == null || vm.isLoading) ? null : () => _advance(context, vm),
                  icon: vm.isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.update_rounded),
                  label: Text(vm.isLoading ? 'Updating...' : 'Confirm Status Update'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedNext == TripState.cancelled ? AppColors.danger : AppColors.primary,
                  ),
                ),
              ),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(vm.error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                ),
              if (vm.successMsg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(vm.successMsg!, style: const TextStyle(color: AppColors.success, fontSize: 13)),
                ),
            ]),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.trip.state == TripState.delivered ? AppColors.successLight : AppColors.dangerLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Icon(
                  widget.trip.state == TripState.delivered ? Icons.check_circle_outline : Icons.cancel_outlined,
                  color: widget.trip.state == TripState.delivered ? AppColors.success : AppColors.danger,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text('Trip ${TripStateHelper.label(widget.trip.state)}. No further updates possible.',
                    style: TextStyle(fontSize: 13, color: widget.trip.state == TripState.delivered ? AppColors.success : AppColors.danger)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _nextStateTile(TripState s) {
    final isCancel = s == TripState.cancelled;
    final selected = _selectedNext == s;
    final color    = isCancel ? AppColors.danger : AppColors.primary;
    return GestureDetector(
      onTap: () => setState(() => _selectedNext = selected ? null : s),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.07) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : AppColors.divider, width: selected ? 1.5 : 1),
        ),
        child: Row(children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? color : Colors.transparent,
              border: Border.all(color: selected ? color : AppColors.divider, width: 1.5),
            ),
            child: selected ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(TripStateHelper.label(s), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: selected ? color : AppColors.textPrimary))),
          Icon(isCancel ? Icons.cancel_outlined : Icons.arrow_forward_rounded, size: 16, color: color.withValues(alpha: 0.6)),
        ]),
      ),
    );
  }

  Future<void> _advance(BuildContext context, TripManagementProvider vm) async {
    final ok = await vm.advanceState(
      tripId: widget.trip.id,
      newState: _selectedNext!,
      updatedBy: context.read<AuthProvider>().userId,
    );
    if (ok) setState(() => _selectedNext = null);
  }
}

// ── State History timeline ────────────────────────────────────────────────────

class _StateHistory extends StatelessWidget {
  final List<TripStateEvent> history;
  const _StateHistory({required this.history});

  @override
  Widget build(BuildContext context) {
    return Column(children: List.generate(history.length, (i) {
      final e = history[i];
      final isLast = i == history.length - 1;
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary, border: Border.all(color: AppColors.primary)),
          ),
          if (!isLast) Container(width: 1.5, height: 36, color: AppColors.divider),
        ]),
        const SizedBox(width: 12),
        Expanded(child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${TripStateHelper.label(e.from)}  →  ${TripStateHelper.label(e.to)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(DateFormat('dd MMM yyyy, hh:mm a').format(e.timestamp),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ]),
        )),
      ]);
    }));
  }
}

// ── Bilty row inside trip detail ──────────────────────────────────────────────

class _BiltyRow extends StatelessWidget {
  final dynamic bilty;
  const _BiltyRow({required this.bilty});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        const Icon(Icons.receipt_outlined, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(bilty.biltyNo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
          Text('${bilty.consignorName} → ${bilty.consigneeCity}  ·  ${CurrencyFormatter.formatWeight(bilty.weightKg)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Text(CurrencyFormatter.format(bilty.totalFreight),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _StatePill extends StatelessWidget {
  final TripState state;
  const _StatePill({required this.state});

  Color get _bg {
    switch (state) {
      case TripState.godown:     return AppColors.warningLight;
      case TripState.dispatched: return AppColors.infoLight;
      case TripState.inTransit:  return AppColors.infoLight;
      case TripState.delivered:  return AppColors.successLight;
      case TripState.cancelled:  return AppColors.dangerLight;
    }
  }

  Color get _fg {
    switch (state) {
      case TripState.godown:     return AppColors.warning;
      case TripState.dispatched: return AppColors.info;
      case TripState.inTransit:  return AppColors.info;
      case TripState.delivered:  return AppColors.success;
      case TripState.cancelled:  return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
      child: Text(TripStateHelper.label(state), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _fg)),
    );
  }
}

class _TripStepper extends StatelessWidget {
  final TripState state;
  const _TripStepper({required this.state});

  static const _steps = [TripState.godown, TripState.dispatched, TripState.inTransit, TripState.delivered];

  @override
  Widget build(BuildContext context) {
    if (state == TripState.cancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(20)),
        child: const Text('Cancelled', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.danger)),
      );
    }
    final idx = TripStateHelper.stepIndex(state);
    return Row(children: List.generate(_steps.length * 2 - 1, (i) {
      if (i.isOdd) {
        return Expanded(child: Container(height: 2, color: (i ~/ 2) < idx ? AppColors.primary : AppColors.divider));
      }
      final si    = i ~/ 2;
      final done  = si < idx;
      final active= si == idx;
      return Column(children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.primary : active ? AppColors.primaryLight : AppColors.surface,
            border: Border.all(color: done || active ? AppColors.primary : AppColors.divider, width: 1.5),
          ),
          child: Center(child: done
              ? const Icon(Icons.check, size: 13, color: Colors.white)
              : active
                ? const Icon(Icons.circle, size: 8, color: Colors.white)
                : Text('${si + 1}', style: const TextStyle(fontSize: 9, color: AppColors.textMuted))),
        ),
        const SizedBox(height: 3),
        Text(TripStateHelper.label(_steps[si]), style: TextStyle(fontSize: 9, color: done || active ? AppColors.primary : AppColors.textMuted, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
      ]);
    }));
  }
}

// ── New Trip creation screen ──────────────────────────────────────────────────

class NewTripScreen extends StatefulWidget {
  const NewTripScreen({super.key});

  @override
  State<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends State<NewTripScreen> {
  final _formKey = GlobalKey<FormState>();
  String?  _routeId;
  String?  _truckId;
  String?  _driverId;
  String?  _challanId;
  DateTime _scheduledDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final md      = context.watch<MasterDataProvider>();
    final cp      = context.watch<ChallanProvider>();
    final vm      = context.watch<TripManagementProvider>();

    final availTrucks   = md.availableTrucks;
    final availDrivers  = md.availableDrivers;
    final openChallans  = cp.openChallans;

    return Scaffold(
      appBar: const FreightAppBar(title: 'New Trip', subtitle: 'Assign challan, truck & driver'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Route'),
            _dropdown(
              label: 'Route *',
              value: _routeId,
              items: md.routes.map((r) => DropdownMenuItem(value: r.id, child: Text(r.displayName))).toList(),
              onChanged: (v) => setState(() { _routeId = v; _challanId = null; }),
              validator: (v) => v == null ? 'Required' : null,
            ),
            _section('Challan'),
            if (openChallans.isEmpty)
              _noItemsBanner('No open challans available. Create a challan first.', '/challan')
            else
              _dropdown(
                label: 'Select Challan *',
                value: _challanId,
                items: openChallans
                    .where((c) => _routeId == null || c.routeId == _routeId)
                    .map((c) => DropdownMenuItem(value: c.id, child: Text('${c.challanNo}  (${c.totalBilties} bilties)')))
                    .toList(),
                onChanged: (v) => setState(() => _challanId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            if (_challanId != null) _challanPreview(context, _challanId!),
            _section('Vehicle & Driver'),
            if (availTrucks.isEmpty)
              _noItemsBanner('No trucks available. Check master data.', '/master')
            else
              _dropdown(
                label: 'Truck *',
                value: _truckId,
                items: availTrucks.map((t) => DropdownMenuItem(value: t.id, child: Text('${t.vehicleNo}  –  ${t.make} ${t.model}  (${CurrencyFormatter.formatWeight(t.capacityKg)})'))).toList(),
                onChanged: (v) => setState(() => _truckId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            const SizedBox(height: 12),
            if (availDrivers.isEmpty)
              _noItemsBanner('No drivers available.', '/master')
            else
              _dropdown(
                label: 'Driver *',
                value: _driverId,
                items: availDrivers.map((d) => DropdownMenuItem(value: d.id, child: Text('${d.name}  ·  ${d.licenseNo}'))).toList(),
                onChanged: (v) => setState(() => _driverId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            _section('Schedule'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary),
              title: Text(DateFormat('dd MMMM yyyy').format(_scheduledDate),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: const Text('Scheduled dispatch date'),
              trailing: TextButton(
                onPressed: () => _pickDate(context),
                child: const Text('Change'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: vm.isLoading ? null : _submit,
                icon: vm.isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label: Text(vm.isLoading ? 'Creating...' : 'Create Trip'),
              ),
            ),
            if (vm.error != null) ...[
              const SizedBox(height: 8),
              Text(vm.error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Text(label.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.6)),
  );

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _noItemsBanner(String msg, String route) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(fontSize: 12, color: AppColors.warning))),
      TextButton(
        onPressed: () => Navigator.pushNamed(context, route),
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero),
        child: const Text('Go', style: TextStyle(fontSize: 12)),
      ),
    ]),
  );

  Widget _challanPreview(BuildContext context, String cId) {
    final challan = context.read<ChallanProvider>().getChallanById(cId);
    if (challan == null) return const SizedBox.shrink();
    final bilties = context.read<ChallanProvider>().getBiltiesForChallan(challan);
    final totalW  = bilties.fold(0.0, (s, b) => s + b.weightKg);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.info.withValues(alpha: 0.3))),
      child: Row(children: [
        const Icon(Icons.playlist_add_check_rounded, color: AppColors.info, size: 16),
        const SizedBox(width: 8),
        Text('${bilties.length} bilties  ·  ${CurrencyFormatter.formatWeight(totalW)}',
            style: const TextStyle(fontSize: 13, color: AppColors.info, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final d = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _scheduledDate = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().userId;
    final ok = await context.read<TripManagementProvider>().createTrip(
      routeId:       _routeId!,
      truckId:       _truckId!,
      driverId:      _driverId!,
      challanId:     _challanId!,
      scheduledDate: _scheduledDate,
      createdBy:     userId,
    );
    if (!mounted) return;
    if (ok) {
      context.read<ChallanProvider>().refresh();
      context.read<MasterDataProvider>().load();
      Navigator.pop(context);
    }
  }
}
