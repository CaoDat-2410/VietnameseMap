import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/schools_provider.dart';
import '../../shared/repositories/schools_repository.dart';

class SchoolsTempPage extends ConsumerStatefulWidget {
  const SchoolsTempPage({super.key});

  @override
  ConsumerState<SchoolsTempPage> createState() => _SchoolsTempPageState();
}

class _SchoolsTempPageState extends ConsumerState<SchoolsTempPage> {
  final _searchController = TextEditingController();
  SchoolSearchParams _params = const SchoolSearchParams();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    setState(() {
      _params = SchoolSearchParams(query: _searchController.text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(schoolsSearchProvider(_params));

    return Scaffold(
      appBar: AppBar(title: const Text('Schools Temp')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search school name or address',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _search,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: result.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (page) => ListView(
                  children: [
                    Text(
                      'Showing ${page.items.length}/${page.totalItems} schools',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final school in page.items)
                      Card(
                        child: ListTile(
                          title: Text(school.schoolName),
                          subtitle: Text(
                            '${school.provinceName} | ${school.communeName}\n${school.address}',
                          ),
                          trailing: Text(school.schoolUid),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
