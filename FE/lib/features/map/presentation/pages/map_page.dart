import 'package:flutter/material.dart';

import '../widgets/province_list_body.dart';
import '../widgets/vietnam_map_view.dart';

class MapPage extends StatelessWidget {
  const MapPage({
    super.key,
    this.focusLat,
    this.focusLng,
    this.focusLabel,
    this.schoolUids,
  });

  final double? focusLat;
  final double? focusLng;
  final String? focusLabel;
  final List<String>? schoolUids;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            // Wide Screen: Vietnam map on left + province list on right
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: VietnamMapView(
                    focusLat: focusLat,
                    focusLng: focusLng,
                    focusLabel: focusLabel,
                    schoolUids: schoolUids,
                  ),
                ),
                Container(width: 1, color: Theme.of(context).dividerColor),
                Expanded(
                  flex: 2,
                  child: Container(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    child: const ProvinceListBody(),
                  ),
                ),
              ],
            );
          } else {
            // Mobile Screen
            return Stack(
              children: [
                VietnamMapView(
                  focusLat: focusLat,
                  focusLng: focusLng,
                  focusLabel: focusLabel,
                  schoolUids: schoolUids,
                ),
                DraggableScrollableSheet(
                  initialChildSize: 0.4,
                  minChildSize: 0.1,
                  maxChildSize: 0.8,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1E1E1E)
                            : Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Expanded(
                            child: ProvinceListBody(
                              scrollController: scrollController,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
