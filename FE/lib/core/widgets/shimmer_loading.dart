import 'package:flutter/material.dart';

class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
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
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ShimmerLoading(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLoading(width: 150, height: 16),
                      SizedBox(height: 8),
                      ShimmerLoading(width: 100, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const ShimmerLoading(height: 12),
            const SizedBox(height: 8),
            const ShimmerLoading(width: 200, height: 12),
          ],
        ),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  final int itemCount;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ShimmerCard(),
    );
  }
}

class ShimmerWeatherCard extends StatelessWidget {
  const ShimmerWeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              ),
            ),
            child: Stack(
              children: [
                // Location shimmer
                const Positioned(
                  top: 20,
                  left: 20,
                  child: ShimmerLoading(
                    width: 120,
                    height: 14,
                    borderRadius: BorderRadius.all(Radius.circular(7)),
                  ),
                ),
                // Temperature shimmer
                Positioned(
                  bottom: 30,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerLoading(
                        width: 100,
                        height: 60,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      SizedBox(height: 8),
                      ShimmerLoading(
                        width: 80,
                        height: 12,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                    ],
                  ),
                ),
                // Icon shimmer
                const Positioned(
                  top: 20,
                  right: 20,
                  child: ShimmerLoading(
                    width: 72,
                    height: 72,
                    borderRadius: BorderRadius.all(Radius.circular(36)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Detail cards shimmer
          Row(
            children: const [
              Expanded(child: ShimmerLoading(height: 64)),
              SizedBox(width: 10),
              Expanded(child: ShimmerLoading(height: 64)),
            ],
          ),
        ],
      ),
    );
  }
}
