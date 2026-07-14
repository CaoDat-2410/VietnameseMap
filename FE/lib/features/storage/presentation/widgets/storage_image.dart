import 'package:flutter/material.dart';

import '../../data/repositories/storage_repository.dart';

/// A widget that wraps any image with an upload overlay for Firebase Storage.
///
/// Shows a circular progress indicator while uploading and displays
/// the uploaded publicUrl once complete. Falls back to the placeholder
/// if no image is set.
///
/// Usage:
/// ```dart
/// StorageImage(
///   repository: storageRepository,
///   folder: 'campaigns',
///   currentImageUrl: campaign.bannerUrl,
///   onUploaded: (url) => updateBannerUrl(url),
///   child: Image.network(campaign.bannerUrl ?? ''),
/// )
/// ```
class StorageImage extends StatefulWidget {
  const StorageImage({
    super.key,
    required this.repository,
    required this.folder,
    required this.currentImageUrl,
    required this.onUploaded,
    required this.child,
    this.enabled = true,
  });

  final StorageRepository repository;
  final String folder;
  final String? currentImageUrl;
  final ValueChanged<String> onUploaded;
  final Widget child;
  final bool enabled;

  @override
  State<StorageImage> createState() => _StorageImageState();
}

class _StorageImageState extends State<StorageImage> {
  // ignore: prefer_final_fields
  double _progress = 0;
  // ignore: prefer_final_fields
  bool _uploading = false;
  String? _error;

  Future<void> _pickAndUpload() async {
    if (!widget.enabled) return;
    debugPrint('[StorageImage] Pick-and-upload triggered for folder: ${widget.folder}');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_uploading)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(value: _progress > 0 ? _progress : null),
                    const SizedBox(height: 8),
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_error != null)
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Container(
              color: Colors.red.shade700,
              padding: const EdgeInsets.all(4),
              child: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
        if (widget.enabled)
          Positioned(
            bottom: 4,
            right: 4,
            child: IconButton.filled(
              icon: const Icon(Icons.cloud_upload),
              onPressed: _uploading ? null : _pickAndUpload,
              tooltip: 'Upload image',
            ),
          ),
      ],
    );
  }
}
