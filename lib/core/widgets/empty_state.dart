import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Polished illustrated empty-state widget with branded icon, title, body, and optional CTA.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  // ── Named constructors for each screen ────────────────────────────────────
  const EmptyState.bilties({super.key, VoidCallback? onAdd})
      : icon = Icons.receipt_long_outlined,
        title = 'No Bilties Yet',
        subtitle = 'Create your first consignment note to start\ntracking freight movements.',
        actionLabel = 'Create Bilty',
        onAction = onAdd,
        iconColor = AppColors.primary;

  const EmptyState.challans({super.key, VoidCallback? onAdd})
      : icon = Icons.assignment_outlined,
        title = 'No Challans Created',
        subtitle = 'Group pending bilties into a challan\nonce your truck reaches 90% capacity.',
        actionLabel = 'Create Challan',
        onAction = onAdd,
        iconColor = AppColors.accent;

  const EmptyState.trips({super.key, VoidCallback? onAdd})
      : icon = Icons.route_outlined,
        title = 'No Active Trips',
        subtitle = 'Assign a challan to a truck and driver\nto start your first trip.',
        actionLabel = 'New Trip',
        onAction = onAdd,
        iconColor = AppColors.primary;

  const EmptyState.trucks({super.key})
      : icon = Icons.local_shipping_outlined,
        title = 'No Trucks Added',
        subtitle = 'Add your fleet vehicles to begin\nassigning trips and challans.',
        actionLabel = null,
        onAction = null,
        iconColor = AppColors.textMuted;

  const EmptyState.drivers({super.key})
      : icon = Icons.person_pin_outlined,
        title = 'No Drivers Added',
        subtitle = 'Register your drivers to assign them\nto active trips.',
        actionLabel = null,
        onAction = null,
        iconColor = AppColors.textMuted;

  const EmptyState.routes({super.key})
      : icon = Icons.map_outlined,
        title = 'No Routes Configured',
        subtitle = 'Add origin-destination routes with\ndistance and base freight rates.',
        actionLabel = null,
        onAction = null,
        iconColor = AppColors.textMuted;

  const EmptyState.search({super.key})
      : icon = Icons.search_off_rounded,
        title = 'No Results Found',
        subtitle = 'Try adjusting your filters or\nsearch term.',
        actionLabel = null,
        onAction = null,
        iconColor = AppColors.textMuted;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Illustrated icon in gradient circle ──────────────────────
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.12),
                    color.withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: Center(
                child: Icon(icon, size: 46, color: color.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(height: 20),

            // ── Decorative dots ──────────────────────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == 1 ? 10 : 6,
                height: i == 1 ? 10 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: i == 1 ? 0.4 : 0.2),
                ),
              )),
            ),
            const SizedBox(height: 16),

            // ── Title ────────────────────────────────────────────────────
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // ── Subtitle ─────────────────────────────────────────────────
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),

            // ── Optional CTA button ──────────────────────────────────────
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
