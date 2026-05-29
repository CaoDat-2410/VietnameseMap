import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../location/domain/entities/location.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/weather_card.dart';

class WeatherPage extends ConsumerWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(currentLocationProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: colorScheme.primary,
            title: const Text('Thời tiết'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Làm mới',
                onPressed: () => ref.invalidate(currentLocationProvider),
              ),
              const SizedBox(width: 4),
            ],
          ),
          locationAsync.when(
            loading: () => const SliverFillRemaining(
              child: LoadingWidget(message: 'Đang lấy vị trí...'),
            ),
            error: (e, _) => SliverFillRemaining(
              child: AppErrorWidget(
                failure: UnknownFailure(e.toString()),
                onRetry: () => ref.invalidate(currentLocationProvider),
              ),
            ),
            data: (result) => result.when(
              ok: (location) => _WeatherSliver(location: location),
              err: (failure) => SliverFillRemaining(
                child: AppErrorWidget(
                  failure: failure,
                  onRetry: () => ref.invalidate(currentLocationProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherSliver extends ConsumerWidget {
  const _WeatherSliver({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coords = (lat: location.latitude, lng: location.longitude);
    final weatherAsync = ref.watch(weatherByCoordinatesProvider(coords));

    return weatherAsync.when(
      loading: () => const SliverFillRemaining(
        child: LoadingWidget(message: 'Đang tải thời tiết...'),
      ),
      error: (e, _) => SliverFillRemaining(
        child: AppErrorWidget(
          failure: UnknownFailure(e.toString()),
          onRetry: () => ref.invalidate(weatherByCoordinatesProvider(coords)),
        ),
      ),
      data: (weatherResult) => weatherResult.when(
        ok: (weather) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WeatherCard(weather: weather),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Text(
                    'Cập nhật lúc: ${_formatTime(weather.timestamp)}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        err: (failure) => SliverFillRemaining(
          child: AppErrorWidget(
            failure: failure,
            onRetry: () =>
                ref.invalidate(weatherByCoordinatesProvider(coords)),
          ),
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
