import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/weather_provider.dart';
import '../repositories/weather_repository.dart';
import '../utils/weather_date_time_formatter.dart';

class WeatherApiCard extends ConsumerWidget {
  const WeatherApiCard({
    super.key,
    required this.point,
    required this.title,
    this.subtitle,
  });

  final WeatherLatLng point;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(currentWeatherByLatLngProvider(point));

    return weatherAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Đang tải thời tiết...'),
          ],
        ),
      ),
      error: (error, _) {
        final isConfigurationError = error is WeatherConfigurationException;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isConfigurationError
                    ? error.toString()
                    : 'Không tải được thời tiết.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.invalidate(currentWeatherByLatLngProvider(point)),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        );
      },
      data: (weather) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (subtitle?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (weather.conditionIcon.isNotEmpty)
                    Image.network(
                      weather.conditionIcon,
                      width: 52,
                      height: 52,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.cloud, size: 42),
                    )
                  else
                    const Icon(Icons.cloud, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weather.tempC.toStringAsFixed(0)}°C',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(weather.conditionText),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Cảm giác như: ${weather.feelslikeC.toStringAsFixed(0)}°C',
              ),
              Text('💧 Độ ẩm: ${weather.humidity}%'),
              Text('🌬 Gió: ${weather.windKph.toStringAsFixed(1)} km/h'),
              Text('☁ Mây: ${weather.cloud}%'),
              Text('☀ UV: ${weather.uv.toStringAsFixed(1)}'),
              const SizedBox(height: 8),
              Text(
                'Cập nhật: ${formatWeatherDateTime(weather.lastUpdated)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
