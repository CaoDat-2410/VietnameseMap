import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/current_weather.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({
    super.key,
    required this.weather,
    this.displayName,
  });

  final CurrentWeather weather;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MainWeatherCard(weather: weather, displayName: displayName),
          const SizedBox(height: 16),
          _DetailsGrid(weather: weather),
          if (weather.cached) ...[
            const SizedBox(height: 8),
            _CachedBadge(),
          ],
        ],
      ),
    );
  }
}

class _MainWeatherCard extends StatelessWidget {
  const _MainWeatherCard({required this.weather, this.displayName});
  final CurrentWeather weather;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location + icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            displayName?.trim().isNotEmpty == true
                                ? displayName!
                                : weather.locationName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weather.description,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Image.network(
                weather.iconUrl,
                width: 72,
                height: 72,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.cloud,
                  size: 64,
                  color: Colors.white54,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Temperature
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${weather.temperature.toStringAsFixed(1)}°',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'C',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 24,
                      fontWeight: FontWeight.w300),
                ),
              ),
            ],
          ),

          Text(
            l10n.feelsLike(weather.feelsLike.toStringAsFixed(1)),
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),

          if (weather.tempMin != null && weather.tempMax != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _TempBadge(
                    label: '↓',
                    value: '${weather.tempMin!.toStringAsFixed(0)}°'),
                const SizedBox(width: 8),
                _TempBadge(
                    label: '↑',
                    value: '${weather.tempMax!.toStringAsFixed(0)}°'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TempBadge extends StatelessWidget {
  const _TempBadge({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.weather});
  final CurrentWeather weather;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final items = [
      _Detail(
          icon: Icons.water_drop_outlined,
          label: l10n.humidity,
          value: '${weather.humidity}%',
          color: const Color(0xFF29B6F6)),
      _Detail(
          icon: Icons.air,
          label: l10n.wind,
          value: '${weather.windSpeed.toStringAsFixed(1)} m/s',
          color: const Color(0xFF66BB6A)),
      if (weather.pressure != null)
        _Detail(
            icon: Icons.compress,
            label: l10n.pressure,
            value: '${weather.pressure} hPa',
            color: const Color(0xFFFF7043)),
      if (weather.visibility != null)
        _Detail(
            icon: Icons.visibility_outlined,
            label: l10n.visibility,
            value: '${(weather.visibility! / 1000).toStringAsFixed(1)} km',
            color: const Color(0xFFAB47BC)),
    ];

    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      rows.add(Row(
        children: [
          Expanded(child: _DetailCard(detail: items[i])),
          const SizedBox(width: 10),
          Expanded(
            child: i + 1 < items.length
                ? _DetailCard(detail: items[i + 1])
                : const SizedBox(),
          ),
        ],
      ));
      if (i + 2 < items.length) rows.add(const SizedBox(height: 10));
    }

    return Column(children: rows);
  }
}

class _Detail {
  const _Detail(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.detail});
  final _Detail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: detail.color.withValues(alpha: 0.12),
            child: Icon(detail.icon, size: 15, color: detail.color),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(detail.label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              const SizedBox(height: 2),
              Text(detail.value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CachedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cached, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(l10n.cachedData,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
