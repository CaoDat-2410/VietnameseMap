import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../shared/models/auth_models.dart';
import '../../shared/repositories/auth_repository.dart';
import '../../../storage/data/repositories/storage_repository.dart';

final profileProvider = StateNotifierProvider<ProfileViewModel, ProfileState>(
  (ref) => ProfileViewModel(
    authRepository: ref.watch(authRepositoryProvider),
    storageRepository: ref.watch(storageRepositoryProvider),
  ),
);

final storageRepositoryProvider = Provider<StorageRepository>(
  (ref) => StorageRepository(Dio(), ref.watch(authRepositoryProvider)),
);

final dioClientProvider = Provider<DioClient>((_) => DioClient());

class ProfileState {
  const ProfileState({
    this.isUploading = false,
    this.isUpdatingPassword = false,
    this.isUpdatingInfo = false,
    this.errorMessage,
    this.successMessage,
  });

  final bool isUploading;
  final bool isUpdatingPassword;
  final bool isUpdatingInfo;
  final String? errorMessage;
  final String? successMessage;

  ProfileState copyWith({
    bool? isUploading,
    bool? isUpdatingPassword,
    bool? isUpdatingInfo,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProfileState(
      isUploading: isUploading ?? this.isUploading,
      isUpdatingPassword: isUpdatingPassword ?? this.isUpdatingPassword,
      isUpdatingInfo: isUpdatingInfo ?? this.isUpdatingInfo,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ProfileViewModel extends StateNotifier<ProfileState> {
  ProfileViewModel({
    required AuthRepository authRepository,
    required StorageRepository storageRepository,
  })  : _auth = authRepository,
        _storage = storageRepository,
        super(const ProfileState());

  final AuthRepository _auth;
  final StorageRepository _storage;

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  /// Uploads the avatar to MinIO via the backend's pre-signed URL helper and
  /// persists the returned storage path on the user record.
  Future<AuthUserModel?> uploadAvatarBytes({
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) async {
    if (state.isUploading) return null;
    state = state.copyWith(isUploading: true, clearError: true, clearSuccess: true);
    try {
      final urls = await _storage.generateUploadUrl(
        fileName: fileName,
        contentType: contentType,
        folder: 'avatars',
      );
      await _storage.uploadFile(
        uploadUrl: urls.uploadUrl,
        bytes: bytes,
        contentType: contentType,
      );
      final updated = await _auth.updateProfile(avatarObjectKey: urls.storagePath);
      state = state.copyWith(
        isUploading: false,
        successMessage: 'Cập nhật ảnh đại diện thành công',
      );
      return updated;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Không thể tải ảnh lên: ${friendlyError(e)}',
      );
      return null;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state.isUpdatingPassword) return false;
    state = state.copyWith(
      isUpdatingPassword: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _auth.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(
        isUpdatingPassword: false,
        successMessage: 'Đổi mật khẩu thành công',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdatingPassword: false,
        errorMessage: 'Đổi mật khẩu thất bại: ${friendlyError(e)}',
      );
      return false;
    }
  }

  /// Updates editable profile fields (fullName, phone). The backend stores
  /// fullName on the linked employees/students row and phone only on students.
  Future<AuthUserModel?> updateInfo({
    String? fullName,
    String? phone,
  }) async {
    if (state.isUpdatingInfo) return null;
    state = state.copyWith(
      isUpdatingInfo: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final updated = await _auth.updateProfile(
        fullName: fullName,
        phone: phone,
      );
      state = state.copyWith(
        isUpdatingInfo: false,
        successMessage: 'Cập nhật thông tin thành công',
      );
      return updated;
    } catch (e) {
      state = state.copyWith(
        isUpdatingInfo: false,
        errorMessage: 'Cập nhật thông tin thất bại: ${friendlyError(e)}',
      );
      return null;
    }
  }
}

String friendlyError(Object e) {
  final msg = e.toString();
  if (msg.contains('401') || msg.contains('UNAUTHORIZED')) {
    return 'mật khẩu hiện tại không đúng';
  }
  if (msg.contains('400') || msg.contains('BAD_REQUEST')) {
    if (msg.contains('Google')) {
      return 'tài khoản này dùng Google Sign-In, không đổi được mật khẩu';
    }
    if (msg.contains('fullName')) {
      return 'họ tên không hợp lệ';
    }
    if (msg.contains('phone')) {
      return 'số điện thoại không hợp lệ';
    }
    return 'yêu cầu không hợp lệ';
  }
  if (msg.contains('SocketException') || msg.contains('Failed host lookup')) {
    return 'mất kết nối mạng';
  }
  return 'lỗi không xác định';
}