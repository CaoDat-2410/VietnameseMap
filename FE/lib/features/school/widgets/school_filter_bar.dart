import 'package:flutter/material.dart';

class SchoolFilterBar extends StatelessWidget {
  const SchoolFilterBar({
    super.key,
    required this.onSearchChanged,
    required this.onProvinceChanged,
    required this.onCommuneChanged,
    required this.onAreaChanged,
    this.provinceCode,
    this.communeCode,
    this.area,
  });

  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onProvinceChanged;
  final ValueChanged<String> onCommuneChanged;
  final ValueChanged<String?> onAreaChanged;
  final String? provinceCode;
  final String? communeCode;
  final String? area;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 330,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search school name or address',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          SizedBox(
            width: 170,
            child: TextFormField(
              initialValue: provinceCode,
              decoration: const InputDecoration(labelText: 'Province code'),
              onChanged: onProvinceChanged,
            ),
          ),
          SizedBox(
            width: 170,
            child: TextFormField(
              initialValue: communeCode,
              decoration: const InputDecoration(labelText: 'Commune code'),
              onChanged: onCommuneChanged,
            ),
          ),
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<String?>(
              initialValue: area,
              decoration: const InputDecoration(labelText: 'Area'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'KV1', child: Text('KV1')),
                DropdownMenuItem(value: 'KV2', child: Text('KV2')),
                DropdownMenuItem(value: 'KV2_NT', child: Text('KV2_NT')),
                DropdownMenuItem(value: 'KV3', child: Text('KV3')),
              ],
              onChanged: onAreaChanged,
            ),
          ),
        ],
      ),
    );
  }
}
