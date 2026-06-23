import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/weather_provider.dart';
import '../widgets/weather_card.dart';

class WeatherPage extends ConsumerWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(selectedWeatherProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    void refreshWeather() {
      ref.invalidate(selectedWeatherProvider);
      ref.invalidate(activeWeatherLocationProvider);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: colorScheme.primary,
            title: Text(l10n.weatherTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: l10n.refresh,
                onPressed: refreshWeather,
              ),
              const SizedBox(width: 4),
            ],
          ),
          weatherAsync.when(
            loading: () => SliverFillRemaining(
              child: LoadingWidget(message: l10n.loadingWeather),
            ),
            error: (e, _) => SliverFillRemaining(
              child: AppErrorWidget(
                failure: UnknownFailure(e.toString()),
                onRetry: refreshWeather,
              ),
            ),
            data: (result) => result.when(
              ok: (snapshot) => _WeatherSliver(
                snapshot: snapshot,
                onRefresh: refreshWeather,
              ),
              err: (failure) => SliverFillRemaining(
                child: AppErrorWidget(
                  failure: failure,
                  onRetry: refreshWeather,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherSliver extends StatelessWidget {
  const _WeatherSliver({
    required this.snapshot,
    required this.onRefresh,
  });

  final SelectedWeatherSnapshot snapshot;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final weather = snapshot.weather;
    final location = snapshot.location;
    final l10n = AppLocalizations.of(context)!;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WeatherCard(
              weather: weather,
              displayName: location.displayName,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Text(
                l10n.weatherUpdatedAt(_formatTime(weather.timestamp)),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.refresh),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')} '
        '${local.day}/${local.month}/${local.year}';
  }
}
