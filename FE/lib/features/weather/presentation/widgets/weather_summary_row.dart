import 'package:flutter/material.dart';

import '../../domain/entities/current_weather.dart';

class WeatherSummaryRow extends StatelessWidget {
  const WeatherSummaryRow({
    super.key,
    required this.weather,
    this.compact = false,
  });

  final CurrentWeather weather;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final textStyle = TextStyle(
      color: Colors.grey.shade700,
      fontSize: compact ? 12 : 13,
      fontWeight: FontWeight.w500,
    );

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(Icons.cloud_outlined, size: compact ? 14 : 16, color: color),
        Text('${weather.temperature.toStringAsFixed(0)}°C', style: textStyle),
        Text('·', style: textStyle),
        Text(
          weather.description,
          style: textStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text('·', style: textStyle),
        Text('Ẩm ${weather.humidity}%', style: textStyle),
        if (!compact) ...[
          Text('·', style: textStyle),
          Text('${weather.windSpeed.toStringAsFixed(1)} m/s', style: textStyle),
        ],
      ],
    );
  }
}
