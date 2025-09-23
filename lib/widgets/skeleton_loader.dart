import 'package:flutter/material.dart';
import '../config/colors.dart';

class SkeletonLoader extends StatefulWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.height,
    required this.width,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(-1.0 - _animation.value, 0.0),
              end: Alignment(1.0 - _animation.value, 0.0),
              colors: [
                AppColors.surface,
                AppColors.surfaceVariant.withOpacity(0.5),
                AppColors.surface,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class TicketCardSkeleton extends StatelessWidget {
  const TicketCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonLoader(height: 12, width: 60),
                const Spacer(),
                SkeletonLoader(
                  height: 24,
                  width: 80,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const SkeletonLoader(height: 16, width: double.infinity),
            const SizedBox(height: 8),
            const SkeletonLoader(height: 14, width: 200),
            const SizedBox(height: 16),
            Row(
              children: [
                const SkeletonLoader(height: 12, width: 100),
                const SizedBox(width: 16),
                const SkeletonLoader(height: 12, width: 80),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TeamMemberSkeleton extends StatelessWidget {
  const TeamMemberSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SkeletonLoader(
              height: 48,
              width: 48,
              borderRadius: BorderRadius.circular(24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLoader(height: 16, width: 120),
                  const SizedBox(height: 8),
                  const SkeletonLoader(height: 12, width: 80),
                ],
              ),
            ),
            const SkeletonLoader(height: 14, width: 60),
          ],
        ),
      ),
    );
  }
}

class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(height: 24, width: 80),
            const SizedBox(height: 8),
            const SkeletonLoader(height: 12, width: 60),
          ],
        ),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const SkeletonLoader(height: 24, width: 200),
            const SizedBox(height: 8),
            const SkeletonLoader(height: 14, width: 150),
            const SizedBox(height: 24),

            // Stats grid skeleton
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: List.generate(4, (index) => const StatCardSkeleton()),
            ),

            const SizedBox(height: 32),
            const SkeletonLoader(height: 20, width: 140),
            const SizedBox(height: 16),

            // Recent tickets skeleton
            Column(
              children: List.generate(3, (index) => const TicketCardSkeleton()),
            ),
          ],
        ),
      ),
    );
  }
}