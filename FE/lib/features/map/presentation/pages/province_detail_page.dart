import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/administrative_unit.dart';
import '../providers/map_provider.dart';

final _unitByCodeFamily =
    FutureProvider.family<AdministrativeUnit?, String>((ref, code) async {
  final result = await ref.watch(geoRepositoryProvider).getUnitByCode(code);
  return result.when(ok: (u) => u, err: (_) => null);
});

class ProvinceDetailPage extends ConsumerWidget {
  const ProvinceDetailPage({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitAsync = ref.watch(_unitByCodeFamily(code));
    final asyncDistricts = ref.watch(districtsProvider(code));
    final colorScheme = Theme.of(context).colorScheme;

    final provinceName = unitAsync.when(
      data: (u) => u?.name ?? code,
      loading: () => code,
      error: (_, __) => code,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: colorScheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 60, bottom: 16, right: 20),
              title: Text(
                provinceName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      Icons.location_city,
                      size: 160,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Info card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: unitAsync.when(
                loading: () => const Card(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: LoadingWidget())),
                error: (_, __) => const SizedBox.shrink(),
                data: (unit) => unit == null
                    ? const SizedBox.shrink()
                    : Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(
                                  icon: Icons.info_outline,
                                  title: 'Thông tin chung'),
                              const SizedBox(height: 12),
                              _InfoRow(label: 'Tên', value: unit.name),
                              _InfoRow(label: 'Mã', value: unit.code),
                              _InfoRow(
                                  label: 'Cấp',
                                  value: unit.level.name.toUpperCase()),
                              if (unit.centroidLat != null)
                                _InfoRow(
                                  label: 'Tọa độ',
                                  value:
                                      '${unit.centroidLat!.toStringAsFixed(4)}°N, '
                                      '${unit.centroidLng!.toStringAsFixed(4)}°E',
                                ),
                              if (unit.childCount != null)
                                _InfoRow(
                                    label: 'Số huyện',
                                    value: '${unit.childCount}'),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // Districts card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                          icon: Icons.location_on_outlined,
                          title: 'Quận / Huyện'),
                      const SizedBox(height: 12),
                      asyncDistricts.when(
                        loading: () => const LoadingWidget(),
                        error: (_, __) =>
                            _hint('Không thể tải dữ liệu quận/huyện'),
                        data: (result) => result.when(
                          ok: (districts) => districts.isEmpty
                              ? _hint('Không có dữ liệu')
                              : Column(
                                  children: districts
                                      .map((d) => ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                            leading: CircleAvatar(
                                              radius: 16,
                                              backgroundColor:
                                                  Colors.blue.shade50,
                                              child: Icon(Icons.location_on,
                                                  size: 15,
                                                  color:
                                                      Colors.blue.shade700),
                                            ),
                                            title: Text(d.name,
                                                style: const TextStyle(
                                                    fontSize: 13)),
                                            trailing: Text(d.code,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors
                                                        .grey.shade500)),
                                          ))
                                      .toList(),
                                ),
                          err: (_) =>
                              _hint('Cần mã số tỉnh để tải quận/huyện'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hint(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 15, color: Colors.grey.shade400),
            const SizedBox(width: 6),
            Text(msg,
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
