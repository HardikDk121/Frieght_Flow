import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/bilty.dart';
import '../../../core/models/trip.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/bilty_provider.dart';
import '../../../providers/challan_provider.dart';
import '../../../providers/master_data_provider.dart';
import '../../../providers/trip_management_provider.dart';
import '../../bilty_new/view/new_bilty_screen.dart';
import '../../challan/view/new_challan_screen.dart';
import '../../master_data/view/master_data_screen.dart';
import '../../trip_mgmt/view/trip_management_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final biltyP = context.watch<BiltyProvider>();
    context.watch<ChallanProvider>();
    final tripP = context.watch<TripManagementProvider>();
    final masterP = context.watch<MasterDataProvider>();

    final totalBilties = biltyP.bilties.length;
    final pendingBilties = biltyP.pendingBilties.length;
    final activeTrips = tripP.activeTrips.length;
    final availTrucks = masterP.availableTrucks.length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      // ── Use a regular AppBar — no SliverAppBar to avoid title duplication ──
      body: SafeArea(
        child: Column(children: [
          // ── Header ──────────────────────────────────────────────────────────
          _DashboardHeader(userName: auth.userName),
          // ── Scrollable content ───────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _SummaryGrid(
                  totalBilties: totalBilties,
                  pendingBilties: pendingBilties,
                  activeTrips: activeTrips,
                  availTrucks: availTrucks,
                ),
                const SizedBox(height: 24),
                _QuickActions(),
                const SizedBox(height: 24),
                _ActiveTripsSection(trips: tripP.activeTrips),
                const SizedBox(height: 24),
                _RecentBiltiesSection(bilties: biltyP.bilties.take(3).toList()),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Header — gradient banner, NO duplication ─────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final String userName;
  const _DashboardHeader({required this.userName});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = userName.split(' ').first;
    final greeting = _greeting();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.gradBlue,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Row 1: Avatar + greeting  |  Logout right ──────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar circle with user initial
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.10)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Greeting + name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$greeting 👋',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                            fontWeight: FontWeight.w400)),
                    const SizedBox(height: 2),
                    Text(firstName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3)),
                  ],
                ),
              ),
              // Logout
              IconButton(
                onPressed: () => _confirmLogout(context),
                tooltip: 'Sign out',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),

        // ── Row 2: Dashboard title ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.dashboard_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Operations Dashboard',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  void _confirmLogout(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctx.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

// ── Live stat cards ───────────────────────────────────────────────────────────

class _SummaryGrid extends StatelessWidget {
  final int totalBilties, pendingBilties, activeTrips, availTrucks;
  const _SummaryGrid({
    required this.totalBilties,
    required this.pendingBilties,
    required this.activeTrips,
    required this.availTrucks,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(
            child: _StatCard(
          label: 'Total Bilties',
          value: '$totalBilties',
          icon: Icons.receipt_long_rounded,
          gradColors: AppColors.gradBlue,
          ringValue: totalBilties > 0 ? pendingBilties / totalBilties : 0,
          ringColor: AppColors.accent,
          onTap: () =>
              _push(context, const _BiltyListPage(filterPending: false)),
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
          label: 'Pending',
          value: '$pendingBilties',
          icon: Icons.pending_actions_rounded,
          gradColors: AppColors.gradBlue,
          badge: pendingBilties > 0 ? '$pendingBilties' : null,
          ringValue: totalBilties > 0 ? pendingBilties / totalBilties : 0,
          ringColor: AppColors.accent,
          onTap: () =>
              _push(context, const _BiltyListPage(filterPending: true)),
        )),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: _StatCard(
          label: 'Active Trips',
          value: '$activeTrips',
          icon: Icons.local_shipping_rounded,
          gradColors: AppColors.gradBlue,
          ringValue: activeTrips > 0 ? (activeTrips / 5).clamp(0.05, 1.0) : 0,
          ringColor: AppColors.accent,
          onTap: () => _push(context, const TripManagementScreen()),
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
          label: 'Avail. Trucks',
          value: '$availTrucks',
          icon: Icons.fire_truck_rounded,
          gradColors: AppColors.gradBlue,
          ringValue: availTrucks > 0 ? (availTrucks / 4).clamp(0.05, 1.0) : 0,
          ringColor: AppColors.accent,
          onTap: () => _push(context, const MasterDataScreen()),
        )),
      ]),
    ]);
  }

  void _push(BuildContext ctx, Widget page) =>
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => page));
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final List<Color> gradColors;
  final String? badge;
  final VoidCallback onTap;
  final double ringValue; // 0.0 → 1.0
  final Color ringColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradColors,
    required this.onTap,
    this.badge,
    this.ringValue = 0,
    this.ringColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 115,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradColors.first.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Stack(children: [
          // ── Animated progress ring using CustomPainter ──────────────────
          Positioned(
            right: -8,
            top: -8,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: ringValue.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => SizedBox(
                width: 72,
                height: 72,
                child: CustomPaint(
                  painter: _RingPainter(progress: v, color: ringColor),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Material icon ──────────────────────────────────────────────
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              // ── Number + label ─────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        height: 1,
                      )),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(label,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Badge
          if (badge != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge!,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: gradColors.last)),
              ),
            ),
        ]),
      ),
    );
  }
}

// ── Quick action tiles ────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionTitle('Quick Actions'),
      const SizedBox(height: 12),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
              child: _ActionTile(
            icon: Icons.receipt_long_rounded,
            label: 'New Bilty',
            iconColor: AppColors.info,
            bgColor: AppColors.infoLight,
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NewBiltyScreen()));
              if (context.mounted) _refreshAll(context);
            },
          )),
          const SizedBox(width: 10),
          Expanded(
              child: _ActionTile(
            icon: Icons.description_rounded,
            label: 'New Challan',
            iconColor: AppColors.warning,
            bgColor: AppColors.warningLight,
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NewChallanScreen()));
              if (context.mounted) _refreshAll(context);
            },
          )),
          const SizedBox(width: 10),
          Expanded(
              child: _ActionTile(
            icon: Icons.local_shipping_rounded,
            label: 'New Trip',
            iconColor: AppColors.success,
            bgColor: AppColors.successLight,
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NewTripScreen()));
              if (context.mounted) _refreshAll(context);
            },
          )),
          const SizedBox(width: 10),
          Expanded(
              child: _ActionTile(
            icon: Icons.dataset_rounded,
            label: 'Master Data',
            iconColor: AppColors.primary,
            bgColor: AppColors.surface,
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MasterDataScreen()));
              if (context.mounted) _refreshAll(context);
            },
          )),
        ]),
      ),
    ]);
  }

  void _refreshAll(BuildContext context) {
    context.read<BiltyProvider>().refresh();
    context.read<ChallanProvider>().refresh();
    context.read<TripManagementProvider>().refresh();
    context.read<MasterDataProvider>().load();
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(children: [
          // ── Material icon — uniform size for all quick actions
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 7),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ── Active trips ──────────────────────────────────────────────────────────────

class _ActiveTripsSection extends StatelessWidget {
  final List<Trip> trips;
  const _ActiveTripsSection({required this.trips});

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const _SectionTitle('Active Trips'),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TripManagementScreen())),
          child: const Text('View all', style: TextStyle(fontSize: 12)),
        ),
      ]),
      const SizedBox(height: 8),
      ...trips.take(2).map((t) => _ActiveTripRow(trip: t)),
    ]);
  }
}

class _ActiveTripRow extends StatelessWidget {
  final Trip trip;
  const _ActiveTripRow({required this.trip});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TripManagementProvider>();
    final route = vm.routeForTrip(trip);
    final truck = vm.truckForTrip(trip);
    final state = TripStateHelper.label(trip.state);

    final stateColor = trip.state == TripState.inTransit
        ? AppColors.info
        : trip.state == TripState.dispatched
            ? AppColors.warning
            : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(10),
          // ── PNG icon rendered natively ────────────────────────────────────
          child: Image.asset('assets/delivery.png', fit: BoxFit.contain),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(trip.tripNo,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(route?.displayName ?? '—',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(truck?.vehicleNo ?? '—',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: stateColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20)),
          child: Text(state,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: stateColor)),
        ),
      ]),
    );
  }
}

// ── Recent bilties ────────────────────────────────────────────────────────────

class _RecentBiltiesSection extends StatelessWidget {
  final List<Bilty> bilties;
  const _RecentBiltiesSection({required this.bilties});

  @override
  Widget build(BuildContext context) {
    if (bilties.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const _SectionTitle('Recent Bilties'),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const _BiltyListPage(filterPending: false))),
          child: const Text('View all', style: TextStyle(fontSize: 12)),
        ),
      ]),
      const SizedBox(height: 8),
      ...bilties.map((b) => _BiltyRow(bilty: b)),
    ]);
  }
}

class _BiltyRow extends StatelessWidget {
  final Bilty bilty;
  const _BiltyRow({required this.bilty});

  @override
  Widget build(BuildContext context) {
    final isPending = bilty.isPending;
    final statusColor = isPending ? AppColors.warning : AppColors.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.all(7),
          child: Image.asset('assets/bill.png', fit: BoxFit.contain),
        ),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(bilty.biltyNo,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          Text('${bilty.consignorName} → ${bilty.consigneeCity}',
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(CurrencyFormatter.format(bilty.totalFreight),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4)),
            child: Text(
              isPending ? 'Pending' : BiltyStatusHelper.label(bilty.status),
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w700, color: statusColor),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Bilty list page (tappable from stat cards) ────────────────────────────────

class _BiltyListPage extends StatelessWidget {
  final bool filterPending;
  const _BiltyListPage({required this.filterPending});

  @override
  Widget build(BuildContext context) {
    final biltyP = context.watch<BiltyProvider>();
    final list = filterPending ? biltyP.pendingBilties : biltyP.bilties;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(filterPending ? 'Pending Bilties' : 'All Bilties'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NewBiltyScreen()));
              if (context.mounted) context.read<BiltyProvider>().refresh();
            },
          ),
        ],
      ),
      body: list.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.all(16),
                child: Image.asset('assets/bill.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 16),
              Text(filterPending ? 'No pending bilties' : 'No bilties yet',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 15)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => _DetailedBiltyCard(bilty: list[i]),
            ),
    );
  }
}

class _DetailedBiltyCard extends StatelessWidget {
  final Bilty bilty;
  const _DetailedBiltyCard({required this.bilty});

  @override
  Widget build(BuildContext context) {
    final statusColor = bilty.isPending ? AppColors.warning : AppColors.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(bilty.biltyNo,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text(BiltyStatusHelper.label(bilty.status),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor)),
          ),
        ]),
        const SizedBox(height: 6),
        const Divider(height: 1),
        const SizedBox(height: 8),
        _row('From', bilty.consignorName),
        _row('To', '${bilty.consigneeName}, ${bilty.consigneeCity}'),
        _row('Weight', CurrencyFormatter.formatWeight(bilty.weightKg)),
        _row('Freight', CurrencyFormatter.format(bilty.totalFreight)),
        _row('Payment', PaymentTypeHelper.label(bilty.paymentType)),
      ]),
    );
  }

  Widget _row(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(
              width: 68,
              child: Text(l,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted))),
          Expanded(
              child: Text(v,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis)),
        ]),
      );
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3));
  }
}

// ── Ring painter ─────────────────────────────────────────────────────────────
/// Draws a thin arc progress ring. Used on dashboard stat cards.
class _RingPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width / 2) - 6;

    // Track (background arc)
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = color.withValues(alpha: 0.15),
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        -1.5708, // start at top (-π/2)
        progress * 6.2832, // sweep (progress × 2π)
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.65),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
