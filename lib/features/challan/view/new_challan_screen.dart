import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/bilty.dart';
import '../../../core/models/truck.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/freight_app_bar.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/bilty_provider.dart';
import '../../../providers/challan_provider.dart';
import '../../../providers/master_data_provider.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/shimmer_loader.dart';

// ── Create Challan Screen ─────────────────────────────────────────────────────

class NewChallanScreen extends StatefulWidget {
  const NewChallanScreen({super.key});

  @override
  State<NewChallanScreen> createState() => _NewChallanScreenState();
}

class _NewChallanScreenState extends State<NewChallanScreen> {
  Truck? _selectedTruck;
  final Set<String> _selectedBiltyIds = {};

  static const double _minCapacityPercent = 0.90; // 90% rule

  List<Bilty> _getPendingBilties(BuildContext context) =>
      context.read<BiltyProvider>().pendingBilties;

  double get _totalSelectedWeight {
    final bilties = _selectedBiltyIds
        .map((id) => context.read<BiltyProvider>().getBiltyById(id))
        .whereType<Bilty>()
        .toList();
    return bilties.fold(0.0, (s, b) => s + b.weightKg);
  }

  double get _capacityPercent {
    if (_selectedTruck == null || _selectedTruck!.capacityKg <= 0) return 0;
    return _totalSelectedWeight / _selectedTruck!.capacityKg;
  }

  bool get _canCreate =>
      _selectedTruck != null &&
      _selectedBiltyIds.isNotEmpty &&
      _capacityPercent >= _minCapacityPercent;

  String get _capacityHint {
    if (_selectedTruck == null) return 'Select a truck first';
    final pct = (_capacityPercent * 100).toStringAsFixed(1);
    final needed = (_selectedTruck!.capacityKg * _minCapacityPercent / 1000).toStringAsFixed(1);
    if (_capacityPercent < _minCapacityPercent) {
      return '$pct% filled — need ≥90% (${needed}T) to dispatch';
    }
    return '$pct% filled ✓ Ready to create';
  }

  Color get _capacityColor {
    if (_capacityPercent < 0.5)  return AppColors.danger;
    if (_capacityPercent < 0.90) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final pending = _getPendingBilties(context);
    final trucks  = context.watch<MasterDataProvider>().availableTrucks;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const FreightAppBar(title: 'New Challan', subtitle: 'Group bilties into a freight manifest'),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Step 1: Select Truck ──────────────────────────────────────
              _StepHeader(step: '1', title: 'Select Truck', subtitle: 'Pick an available vehicle'),
              const SizedBox(height: 12),

              trucks.isEmpty
                  ? _noItemsBanner('No available trucks. Add trucks in Master Data.')
                  : Column(children: trucks.map((t) => _TruckTile(
                      truck: t,
                      isSelected: _selectedTruck?.id == t.id,
                      onTap: () => setState(() {
                        _selectedTruck = _selectedTruck?.id == t.id ? null : t;
                        _selectedBiltyIds.clear(); // reset bilty selection on truck change
                      }),
                    )).toList()),

              // ── Step 2: Select Bilties ────────────────────────────────────
              const SizedBox(height: 20),
              _StepHeader(step: '2', title: 'Select Bilties', subtitle: 'Choose pending consignments to load'),
              const SizedBox(height: 12),

              if (_selectedTruck == null)
                _infoHint('Select a truck above to see pending bilties')
              else if (pending.isEmpty)
                _noItemsBanner('No pending bilties. Create a Bilty first.')
              else
                Column(children: pending.map((b) {
                  final isSelected = _selectedBiltyIds.contains(b.id);
                  // Hard cap: would adding this bilty exceed 100% capacity?
                  final wouldExceed = !isSelected &&
                      _selectedTruck != null &&
                      (_totalSelectedWeight + b.weightKg) > _selectedTruck!.capacityKg;

                  return _BiltySelectionTile(
                    bilty: b,
                    isSelected: isSelected,
                    isDisabled: wouldExceed,
                    onTap: () {
                      if (wouldExceed) {
                        // Show hard cap message
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            'Cannot add — would exceed ${_selectedTruck!.vehicleNo} capacity of '
                            '${(_selectedTruck!.capacityKg / 1000).toStringAsFixed(1)} MT',
                          ),
                          backgroundColor: AppColors.danger,
                          duration: const Duration(seconds: 3),
                        ));
                        return;
                      }
                      setState(() {
                        if (_selectedBiltyIds.contains(b.id)) {
                          _selectedBiltyIds.remove(b.id);
                        } else {
                          _selectedBiltyIds.add(b.id);
                        }
                      });
                    },
                  );
                }).toList()),

              // ── Capacity meter ────────────────────────────────────────────
              if (_selectedTruck != null && _selectedBiltyIds.isNotEmpty) ...[
                const SizedBox(height: 20),
                _CapacityMeter(
                  current: _totalSelectedWeight,
                  capacity: _selectedTruck!.capacityKg,
                  percent: _capacityPercent,
                  hint: _capacityHint,
                  color: _capacityColor,
                ),
              ],

              const SizedBox(height: 100), // bottom padding for FAB
            ]),
          ),
        ),
      ]),

      // ── Bottom action bar ─────────────────────────────────────────────────
      bottomNavigationBar: _BottomActionBar(
        selectedCount:  _selectedBiltyIds.length,
        totalWeight:    _totalSelectedWeight,
        canCreate:      _canCreate,
        capacityPercent:_capacityPercent,
        onCreateTap:    _canCreate ? () => _createChallan(context) : () => _showBlockedReason(context),
      ),
    );
  }

  Future<void> _createChallan(BuildContext context) async {
    final cp     = context.read<ChallanProvider>();
    cp.setRouteFilter(_selectedTruck!.id); // use truck id as proxy — replaced by route
    for (final id in _selectedBiltyIds) { cp.toggleBiltySelection(id); }

    // Find the route from first bilty
    final firstBilty = context.read<BiltyProvider>().getBiltyById(_selectedBiltyIds.first);
    if (firstBilty == null) return;

    final userId = context.read<AuthProvider>().userId;

    // Manually build the challan call with truck info
    final challan = await context.read<ChallanProvider>().createChallanWithTruck(
      biltyIds:  _selectedBiltyIds.toList(),
      routeId:   firstBilty.routeId,
      truckId:   _selectedTruck!.id,
      createdBy: userId,
    );

    if (!mounted) return;
    if (challan != null) {
      context.read<BiltyProvider>().refresh();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Challan ${challan.challanNo} created successfully!'),
        backgroundColor: AppColors.success,
      ));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to create challan. Try again.'),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  void _showBlockedReason(BuildContext context) {
    String msg;
    if (_selectedTruck == null) {
      msg = 'Please select a truck before creating a challan.';
    } else if (_selectedBiltyIds.isEmpty) {
      msg = 'Please select at least one bilty.';
    } else {
      final needed   = (_selectedTruck!.capacityKg * _minCapacityPercent / 1000).toStringAsFixed(2);
      final current  = (_totalSelectedWeight / 1000).toStringAsFixed(2);
      msg = '90% Rule: Truck must be at least 90% loaded.\n\nRequired: ${needed}T  |  Current: ${current}T\n\nAdd more bilties to meet the minimum load requirement.';
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          SizedBox(width: 8),
          Text('Cannot Create Challan'),
        ]),
        content: Text(msg),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        ],
      ),
    );
  }

  Widget _infoHint(String msg) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, color: AppColors.info))),
    ]),
  );

  Widget _noItemsBanner(String msg) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, color: AppColors.warning))),
    ]),
  );
}

// ── Step header ───────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final String step, title, subtitle;
  const _StepHeader({required this.step, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: Center(child: Text(step,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    ]);
  }
}

// ── Truck selection tile ──────────────────────────────────────────────────────

class _TruckTile extends StatelessWidget {
  final Truck truck;
  final bool isSelected;
  final VoidCallback onTap;
  const _TruckTile({required this.truck, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(9),
            child: Image.asset('assets/delivery.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(truck.vehicleNo,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary)),
            Text('${truck.make} ${truck.model}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(CurrencyFormatter.formatWeight(truck.capacityKg),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary)),
            const Text('Capacity', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ]),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primary : Colors.transparent,
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider, width: 1.5),
            ),
            child: isSelected ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
          ),
        ]),
      ),
    );
  }
}

// ── Bilty selection tile ──────────────────────────────────────────────────────

class _BiltySelectionTile extends StatelessWidget {
  final Bilty bilty;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;
  const _BiltySelectionTile({
    required this.bilty, required this.isSelected,
    required this.onTap, this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDisabled
              ? AppColors.surface
              : isSelected ? AppColors.success.withValues(alpha: 0.06) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled
                ? AppColors.divider
                : isSelected ? AppColors.success : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDisabled
                  ? AppColors.divider
                  : isSelected ? AppColors.success : Colors.transparent,
              border: Border.all(
                color: isDisabled ? AppColors.divider
                    : isSelected ? AppColors.success : AppColors.divider,
                width: 1.5,
              ),
            ),
            child: isDisabled
                ? const Icon(Icons.block, size: 12, color: AppColors.textMuted)
                : isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(bilty.biltyNo,
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: isDisabled ? AppColors.textMuted
                      : isSelected ? AppColors.success : AppColors.primary,
                )),
            Text('${bilty.consignorName} → ${bilty.consigneeCity}',
                style: TextStyle(fontSize: 11,
                    color: isDisabled ? AppColors.textMuted : AppColors.textSecondary),
                overflow: TextOverflow.ellipsis),
            if (isDisabled)
              Text('Exceeds truck capacity',
                  style: const TextStyle(fontSize: 10, color: AppColors.danger,
                      fontWeight: FontWeight.w500)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(CurrencyFormatter.formatWeight(bilty.weightKg),
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: isDisabled ? AppColors.textMuted : AppColors.textPrimary,
                )),
            Text(CurrencyFormatter.format(bilty.totalFreight),
                style: TextStyle(
                  fontSize: 11,
                  color: isDisabled ? AppColors.textMuted : AppColors.textSecondary,
                )),
          ]),
        ]),
      ),
    );
  }
}

// ── Capacity meter ────────────────────────────────────────────────────────────

/// Animated capacity meter — progress bar smoothly tweens to new value
/// whenever bilties are toggled. Color transitions: red→orange→green.
class _CapacityMeter extends StatelessWidget {
  final double current, capacity, percent;
  final String hint;
  final Color color;
  const _CapacityMeter({
    required this.current, required this.capacity,
    required this.percent, required this.hint, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              percent >= 0.9
                  ? Icons.check_circle_outline
                  : Icons.info_outline_rounded,
              color: color, size: 18,
              key: ValueKey(percent >= 0.9),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(hint,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color))),
          // Animated percentage counter
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percent),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              '${(v * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        // Animated progress bar
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: percent.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, animatedValue, __) {
            // Colour transition: red → orange → green, driven by actual percent
            final barColor = percent < 0.5
                ? AppColors.danger
                : percent < 0.9
                    ? AppColors.warning
                    : AppColors.success;
            return Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: animatedValue,
                  minHeight: 10,
                  backgroundColor: barColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
              // Pulsing glow when exactly at threshold
              if (percent >= 0.9 && percent < 1.0)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _GlowPulse(color: AppColors.success),
                  ),
                ),
            ]);
          },
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Loaded: ${CurrencyFormatter.formatWeight(current)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Text('Capacity: ${CurrencyFormatter.formatWeight(capacity)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]),
        // 90% marker tick
        const SizedBox(height: 8),
        Stack(children: [
          Container(height: 2,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          FractionallySizedBox(
            widthFactor: 0.9,
            child: Container(height: 2, color: Colors.transparent,
              alignment: Alignment.centerRight,
              child: Container(width: 2, height: 12, color: AppColors.textMuted),
            ),
          ),
        ]),
        const SizedBox(height: 2),
        const Align(
          alignment: Alignment(0.8, 0),
          child: Text('90% min', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
        ),
      ]),
    );
  }
}

/// Subtle looping glow overlay — signals "ready to dispatch"
class _GlowPulse extends StatefulWidget {
  final Color color;
  const _GlowPulse({required this.color});

  @override
  State<_GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<_GlowPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.color.withValues(alpha: 0),
              widget.color.withValues(alpha: 0.18),
              widget.color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom action bar ─────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final int selectedCount;
  final double totalWeight;
  final bool canCreate;
  final double capacityPercent;
  final VoidCallback onCreateTap;

  const _BottomActionBar({
    required this.selectedCount, required this.totalWeight,
    required this.canCreate, required this.capacityPercent,
    required this.onCreateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Summary row
        if (selectedCount > 0) ...[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _summaryChip(Icons.receipt_long_outlined, '$selectedCount bilties selected'),
            _summaryChip(Icons.scale_outlined, CurrencyFormatter.formatWeight(totalWeight)),
            _summaryChip(Icons.percent_rounded, '${(capacityPercent * 100).toStringAsFixed(0)}% filled'),
          ]),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onCreateTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: canCreate ? AppColors.success : AppColors.textMuted,
              disabledBackgroundColor: AppColors.textMuted,
            ),
            icon: Icon(canCreate ? Icons.check_circle_outline : Icons.lock_outline, size: 18),
            label: Text(canCreate ? 'Create Challan' : 'Cannot Create — 90% Rule Not Met'),
          ),
        ),
      ]),
    );
  }

  Widget _summaryChip(IconData icon, String label) => Row(children: [
    Icon(icon, size: 13, color: AppColors.textSecondary),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
  ]);
}
