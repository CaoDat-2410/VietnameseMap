import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/administrative_unit_summary.dart';
import '../providers/map_provider.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final asyncProvinces = ref.watch(provincesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 20, bottom: 14, right: 20),
              title: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bản đồ hành chính',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    '63 tỉnh · thành phố',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFDA291C),
                          Color(0xFFC0392B),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Align(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.map_outlined,
                        size: 90,
                        color: Color(0x14FFFFFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm tỉnh thành...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => setState(() => _query = ''),
                        )
                      : null,
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
            ),
          ),

          // Province list
          asyncProvinces.when(
            loading: () => const SliverFillRemaining(
              child: LoadingWidget(message: 'Đang tải danh sách tỉnh...'),
            ),
            error: (e, _) => SliverFillRemaining(
              child: AppErrorWidget(
                failure: UnknownFailure(e.toString()),
                onRetry: () => ref.invalidate(provincesProvider),
              ),
            ),
            data: (result) => result.when(
              ok: (provinces) {
                final filtered = _query.isEmpty
                    ? provinces
                    : provinces
                        .where((p) =>
                            p.name.toLowerCase().contains(_query) ||
                            p.code.toLowerCase().contains(_query))
                        .toList();

                if (filtered.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Không tìm thấy tỉnh nào',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 360,
                      mainAxisExtent: 88,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ProvinceCard(
                        province: filtered[index],
                        index: index,
                        onTap: () =>
                            context.push('/province/${filtered[index].code}'),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
              err: (failure) => SliverFillRemaining(
                child: AppErrorWidget(
                  failure: failure,
                  onRetry: () => ref.invalidate(provincesProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProvinceCard extends StatelessWidget {
  const _ProvinceCard({
    required this.province,
    required this.index,
    required this.onTap,
  });

  final AdministrativeUnitSummary province;
  final int index;
  final VoidCallback onTap;

  static const _avatarColors = [
    Color(0xFFDA291C),
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFE65100),
    Color(0xFF00695C),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _avatarColors[index % _avatarColors.length];
    final initial = province.name.isNotEmpty ? province.name[0] : '?';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.12),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      province.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        province.code,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
