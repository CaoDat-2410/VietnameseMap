import 'package:dio/dio.dart';

import '../../../auth/shared/repositories/auth_repository.dart';

/// Pre-signed upload URL from the backend.
class StorageUploadUrl {
  const StorageUploadUrl({
    required this.uploadUrl,
    required this.publicUrl,
    required this.storagePath,
    required this.expiresAtSeconds,
  });

  final String uploadUrl;
  final String publicUrl;
  final String storagePath;
  final int expiresAtSeconds;
}

/// Repository for Firebase Storage operations via the backend proxy.
class StorageRepository {
  StorageRepository(this._client, this._authRepository);

  final Dio _client;
  final AuthRepository _authRepository;

  /// Generates a pre-signed upload URL for the given folder and file name.
  Future<StorageUploadUrl> generateUploadUrl({
    required String fileName,
    required String contentType,
    required String folder,
  }) async {
    final userId = (await _authRepository.me()).id;
    final res = await _client.post<Map<String, dynamic>>(
      '/api/v1/storage/upload-url',
      data: {
        'fileName': fileName,
        'contentType': contentType,
        'folder': folder,
        'userId': userId,
      },
    );
    final data = res.data!['data'] as Map<String, dynamic>;
    return StorageUploadUrl(
      uploadUrl: data['uploadUrl'] as String,
      publicUrl: data['publicUrl'] as String,
      storagePath: data['storagePath'] as String,
      expiresAtSeconds: data['expiresAtSeconds'] as int,
    );
  }

  /// Uploads a file directly to Firebase Storage using the pre-signed URL.
  Future<void> uploadFile({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
    void Function(int sent, int total)? onProgress,
  }) async {
    await Dio().put(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': bytes.length,
        },
      ),
      onSendProgress: onProgress,
    );
  }
}
