import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A single shimmer "bone" block — use to build skeleton screens.
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E5EE),
      highlightColor: const Color(0xFFF4F6FA),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Shimmer skeleton for a stat/summary card (dashboard grid)
class ShimmerStatCard extends StatelessWidget {
  const ShimmerStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E5EE),
      highlightColor: const Color(0xFFF4F6FA),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                height: 12,
                width: 60,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 10),
            Container(
                height: 28,
                width: 40,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 6),
            Container(
                height: 10,
                width: 80,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5))),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton for a list card (bilty / trip rows)
class ShimmerListCard extends StatelessWidget {
  const ShimmerListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E5EE),
      highlightColor: const Color(0xFFF4F6FA),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 8),
                  Container(
                      height: 14,
                      width: 160,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6))),
                ])),
            Container(
                height: 24,
                width: 72,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12))),
          ]),
          const SizedBox(height: 16),
          Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(5))),
          const SizedBox(height: 6),
          Container(
              height: 10,
              width: 200,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(5))),
        ]),
      ),
    );
  }
}

/// Full-screen shimmer for dashboard loading state
class ShimmerDashboard extends StatelessWidget {
  const ShimmerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // 2x2 stat grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: List.generate(4, (_) => const ShimmerStatCard()),
        ),
        const SizedBox(height: 24),
        // Section label
        const ShimmerBox(height: 14, width: 120),
        const SizedBox(height: 12),
        ...List.generate(
            3,
            (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: ShimmerListCard(),
                )),
      ]),
    );
  }
}

/// Shimmer for the Bilty/Challan list screens
class ShimmerList extends StatelessWidget {
  final int itemCount;
  const ShimmerList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (_, __) => const ShimmerListCard(),
    );
  }
}

/// Wrap any content with a shimmer overlay while loading
class ShimmerWrapper extends StatelessWidget {
  final bool isLoading;
  final Widget shimmer;
  final Widget child;

  const ShimmerWrapper({
    super.key,
    required this.isLoading,
    required this.shimmer,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLoading ? shimmer : child,
    );
  }
}

/// Shimmer skeleton for the Master Data tabs (truck/driver/route rows)
class ShimmerMasterRow extends StatelessWidget {
  const ShimmerMasterRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E5EE),
      highlightColor: const Color(0xFFF4F6FA),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Container(
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Container(
                    height: 13,
                    width: 120,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 7),
                Container(
                    height: 11,
                    width: 180,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5))),
              ])),
          Container(
              height: 28,
              width: 60,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14))),
        ]),
      ),
    );
  }
}
