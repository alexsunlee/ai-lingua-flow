import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable shimmer loading skeleton.
class ShimmerLoading extends StatelessWidget {
  final int itemCount;
  final ShimmerStyle style;

  const ShimmerLoading({
    super.key,
    this.itemCount = 3,
    this.style = ShimmerStyle.list,
  });

  const ShimmerLoading.card({super.key, this.itemCount = 3})
      : style = ShimmerStyle.card;

  const ShimmerLoading.text({super.key, this.itemCount = 5})
      : style = ShimmerStyle.text;

  const ShimmerLoading.detail({super.key, this.itemCount = 1})
      : style = ShimmerStyle.detail;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            itemCount,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildItem(style),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(ShimmerStyle style) {
    switch (style) {
      case ShimmerStyle.list:
        return _ShimmerListItem();
      case ShimmerStyle.card:
        return _ShimmerCardItem();
      case ShimmerStyle.text:
        return _ShimmerTextLine();
      case ShimmerStyle.detail:
        return _ShimmerDetailItem();
    }
  }
}

enum ShimmerStyle { list, card, text, detail }

class _ShimmerListItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShimmerCardItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _ShimmerTextLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _ShimmerDetailItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 20,
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }
}
