import 'package:flutter/material.dart';

/// A calm, non-distracting skeleton loader that mirrors the actual geometry of
/// cards, data rows, and metrics without spinning wheels or blank screens.
class SkeletonLoader extends StatefulWidget {
  final Widget child;

  const SkeletonLoader({Key? key, required this.child}) : super(key: key);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.45, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// A single skeleton line with intentional, subtle rounded corners.
class SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLine({
    Key? key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3848) : const Color(0xFFE5E5DF),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A structured skeleton card matching the exact height and layout of experiment list cards.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2632) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3B4E) : const Color(0xFFE2E4E8),
          width: 1.0,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: SkeletonLine(height: 16)),
              SizedBox(width: 12),
              SkeletonLine(width: 68, height: 18, borderRadius: 3),
            ],
          ),
          SizedBox(height: 12),
          SkeletonLine(width: 160, height: 12),
          SizedBox(height: 14),
          SkeletonLine(width: double.infinity, height: 4, borderRadius: 2),
          SizedBox(height: 8),
          SkeletonLine(width: 120, height: 10),
        ],
      ),
    );
  }
}

/// Skeleton representation of the dashboard screen during initial loading.
class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2632) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E3B4E) : const Color(0xFFE2E4E8);

    return SkeletonLoader(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Backend Status Placeholder
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: const Row(
              children: [
                SkeletonLine(width: 10, height: 10, borderRadius: 5),
                SizedBox(width: 10),
                Expanded(child: SkeletonLine(height: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Toolbar placeholder
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 140, height: 13),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SkeletonLine(width: 110, height: 28, borderRadius: 4),
                    SkeletonLine(width: 120, height: 28, borderRadius: 4),
                    SkeletonLine(width: 100, height: 28, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLine(width: 140, height: 18),
              SkeletonLine(width: 50, height: 14),
            ],
          ),
          const SizedBox(height: 12),
          const SkeletonCard(),
          const SkeletonCard(),
          const SkeletonCard(),
        ],
      ),
    );
  }
}
