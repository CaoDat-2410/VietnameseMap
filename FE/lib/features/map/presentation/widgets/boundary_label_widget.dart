import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BoundaryLabelLayer extends StatelessWidget {
  const BoundaryLabelLayer({
    super.key,
    required this.labels,
    this.minZoom = 0,
    this.maxZoom = 18,
  });

  final List<BoundaryLabel> labels;
  final double minZoom;
  final double maxZoom;

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: labels
          .map((label) => Marker(
                point: label.position,
                width: label.maxWidth,
                height: 60,
                alignment: Alignment.topCenter,
                child: label,
              ))
          .toList(),
    );
  }
}

class BoundaryLabel extends StatelessWidget {
  const BoundaryLabel({
    super.key,
    required this.text,
    required this.position,
    this.maxWidth = 120,
    this.fontSize = 11,
    this.fontWeight = FontWeight.w500,
    this.textColor = Colors.white,
    this.backgroundColor = const Color(0xCC1A237E),
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.borderRadius = 6,
    this.textShadow = true,
    this.onTap,
  });

  final String text;
  final LatLng position;
  final double maxWidth;
  final double fontSize;
  final FontWeight fontWeight;
  final Color textColor;
  final Color backgroundColor;
  final EdgeInsets padding;
  final double borderRadius;
  final bool textShadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
            shadows: textShadow
                ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
