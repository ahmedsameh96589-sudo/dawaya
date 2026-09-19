import 'package:flutter/material.dart';

/// Compact star + average rating, optionally with review count.
class DoctorRatingBadge extends StatelessWidget {
  const DoctorRatingBadge({
    super.key,
    required this.average,
    required this.count,
    this.showWhenEmpty = false,
    this.compact = false,
  });

  final double average;
  final int count;
  final bool showWhenEmpty;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      if (!showWhenEmpty) return const SizedBox.shrink();
      return Text(
        'No ratings',
        style: TextStyle(
          fontSize: compact ? 12 : 13,
          color: Colors.black38,
        ),
      );
    }

    final avgText = average.toStringAsFixed(1);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: compact ? 14 : 16,
          color: Colors.amber,
        ),
        const SizedBox(width: 2),
        Text(
          compact ? avgText : '$avgText ($count)',
          style: TextStyle(
            fontSize: compact ? 13 : 14,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Doctor name with optional rating on the same row.
class DoctorNameWithRating extends StatelessWidget {
  const DoctorNameWithRating({
    super.key,
    required this.name,
    required this.ratingAverage,
    required this.ratingCount,
    this.nameStyle,
    this.showWhenEmpty = false,
  });

  final String name;
  final double ratingAverage;
  final int ratingCount;
  final TextStyle? nameStyle;
  final bool showWhenEmpty;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: nameStyle ??
                const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        DoctorRatingBadge(
          average: ratingAverage,
          count: ratingCount,
          showWhenEmpty: showWhenEmpty,
        ),
      ],
    );
  }
}
