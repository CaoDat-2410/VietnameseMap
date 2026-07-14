import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/config/app_config.dart';
import '../../shared/models/auth_models.dart';
import '../providers/auth_viewmodel.dart';
import '../providers/profile_viewmodel.dart';
import '../utils/avatar_file_picker.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(activeUserProvider);
    final profileState = ref.watch(profileProvider);

    // Listen for the viewmodel state to surface success/error toasts.
    ref.listen<ProfileState>(profileProvider, (previous, next) {
      if (!mounted) return;
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );
        if (next.successMessage!.contains('mật khẩu')) {
          _currentPasswordCtrl.clear();
          _newPasswordCtrl.clear();
          _confirmPasswordCtrl.clear();
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/map');
            }
          },
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi tải thông tin: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Chưa đăng nhập'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AvatarCard(user: user, profileState: profileState),
                    const SizedBox(height: 16),
                    _InfoCard(user: user),
                    const SizedBox(height: 16),
                    _EditInfoCard(user: user, profileState: profileState),
                    if (user.hasPassword) ...[
                      const SizedBox(height: 16),
                      _PasswordCard(
                        formKey: _passwordFormKey,
                        currentCtrl: _currentPasswordCtrl,
                        newCtrl: _newPasswordCtrl,
                        confirmCtrl: _confirmPasswordCtrl,
                        profileState: profileState,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _SessionCard(user: user),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AvatarCard extends ConsumerWidget {
  const _AvatarCard({required this.user, required this.profileState});

  final AuthUserModel user;
  final ProfileState profileState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 12,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Avatar(user: user, size: 80),
            const SizedBox(width: 20),
            SizedBox(
              width: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.outline)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text(_roleLabel(user.role)),
                        backgroundColor: theme.colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      if (user.firebaseUser)
                        Chip(
                          label: const Text('Google Sign-In'),
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: profileState.isUploading
                  ? null
                  : () => _pickAndUploadAvatar(context, ref),
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(profileState.isUploading
                  ? 'Đang tải...'
                  : (user.avatarObjectKey == null ? 'Thêm ảnh' : 'Đổi ảnh')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context, WidgetRef ref) async {
    if (kIsWeb) {
      final result = await pickAvatarFile();
      if (result == null) return;
      final (fileName, bytes, contentType) = result;
      final updated =
          await ref.read(profileProvider.notifier).uploadAvatarBytes(
                bytes: bytes,
                fileName: fileName,
                contentType: contentType,
              );
      if (updated != null) {
        // Refresh the active user state so the avatar rebuilds everywhere.
        ref.invalidate(authViewModelProvider);
        AnalyticsService.logEvent('profile_avatar_updated');
      }
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Tải ảnh lên từ thiết bị di động sẽ được hỗ trợ sau.')),
      );
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, this.size = 64});
  final AuthUserModel user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = user.avatarObjectKey != null;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: hasImage
          ? ClipOval(
              child: Image.network(
                _avatarUrl(user.avatarObjectKey!),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _InitialsAvatar(user: user, size: size),
              ),
            )
          : _InitialsAvatar(user: user, size: size),
    );
  }

  String _avatarUrl(String objectKey) {
    // The backend's UploadUrlResponse returns a publicUrl; we use the same
    // base as in the existing StorageImage widget by reconstructing the public
    // MinIO URL from the bucket. For now, fall back to the storage path
    // directly served via the campaign bucket public read policy.
    // Object key already includes the folder (e.g. "avatars/1234567_name.jpg").
    final api = Uri.parse(AppConfig.baseUrl);
    return '${api.scheme}://${api.host}:9000/vnmap-campaign/$objectKey';
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.user, required this.size});
  final AuthUserModel user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      user.initials,
      style: TextStyle(
        fontSize: size / 2.6,
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.user});
  final AuthUserModel user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thông tin',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _InfoRow(label: 'Họ tên', value: user.displayName),
            _InfoRow(label: 'Email', value: user.email),
            if (user.canEditPhone)
              _InfoRow(
                label: 'Số điện thoại',
                value: (user.phone == null || user.phone!.isEmpty)
                    ? '—'
                    : user.phone!,
              ),
            _InfoRow(label: 'Vai trò', value: _roleLabel(user.role)),
            _InfoRow(
              label: 'Trạng thái',
              value: user.status == 'ACTIVE' ? 'Hoạt động' : user.status,
            ),
            if (user.firebaseUser)
              const _InfoRow(
                label: 'Đăng nhập',
                value: 'Google Sign-In (Firebase)',
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelText = Text(
      label,
      style: theme.textTheme.bodyMedium
          ?.copyWith(color: theme.colorScheme.outline),
    );
    final valueText = Text(value, style: theme.textTheme.bodyMedium);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 360) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelText, const SizedBox(height: 2), valueText],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 120, child: labelText),
              Expanded(child: valueText),
            ],
          );
        },
      ),
    );
  }
}

class _EditInfoCard extends ConsumerStatefulWidget {
  const _EditInfoCard({required this.user, required this.profileState});

  final AuthUserModel user;
  final ProfileState profileState;

  @override
  ConsumerState<_EditInfoCard> createState() => _EditInfoCardState();
}

class _EditInfoCardState extends ConsumerState<_EditInfoCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
  }

  void _syncFromUser() {
    if (_initialized) return;
    _nameCtrl.text = widget.user.displayName;
    _phoneCtrl.text = widget.user.phone ?? '';
    _initialized = true;
  }

  @override
  void didUpdateWidget(covariant _EditInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_initialized) _syncFromUser();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncFromUser();
    final theme = Theme.of(context);
    final user = widget.user;
    final saving = widget.profileState.isUpdatingInfo;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cập nhật thông tin',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Họ tên',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Vui lòng nhập họ tên';
                  }
                  if (v.trim().length > 255) {
                    return 'Họ tên quá dài';
                  }
                  return null;
                },
              ),
              if (user.canEditPhone) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    helperText: 'Để trống nếu không muốn cung cấp',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    if (v == null) return null;
                    final trimmed = v.trim();
                    if (trimmed.isEmpty) return null;
                    if (trimmed.length > 50) return 'Số điện thoại quá dài';
                    final phoneRegex = RegExp(r'^[0-9+\-\s()]+$');
                    if (!phoneRegex.hasMatch(trimmed)) {
                      return 'Số điện thoại chỉ gồm chữ số và ký tự + - ( )';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: saving ? null : () => _submit(),
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Lưu thông tin'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(profileProvider.notifier);
    final updated = await notifier.updateInfo(
      fullName: _nameCtrl.text.trim(),
      phone: widget.user.canEditPhone ? _phoneCtrl.text.trim() : null,
    );
    if (updated != null && mounted) {
      // Refresh the active user state so the rest of the app sees the new name.
      ref.invalidate(authViewModelProvider);
      AnalyticsService.logEvent('profile_info_updated');
    }
  }
}

class _PasswordCard extends ConsumerWidget {
  const _PasswordCard({
    required this.formKey,
    required this.currentCtrl,
    required this.newCtrl,
    required this.confirmCtrl,
    required this.profileState,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController currentCtrl;
  final TextEditingController newCtrl;
  final TextEditingController confirmCtrl;
  final ProfileState profileState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Đổi mật khẩu',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextFormField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Vui lòng nhập mật khẩu hiện tại'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới (ít nhất 8 ký tự)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'Vui lòng nhập mật khẩu mới';
                  if (v.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
                  if (v == currentCtrl.text) {
                    return 'Mật khẩu mới phải khác mật khẩu hiện tại';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Vui lòng xác nhận mật khẩu mới';
                  }
                  if (v != newCtrl.text) return 'Mật khẩu xác nhận không khớp';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: profileState.isUpdatingPassword
                      ? null
                      : () => _submit(context, ref),
                  icon: profileState.isUpdatingPassword
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Lưu mật khẩu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    if (!formKey.currentState!.validate()) return;
    final ok = await ref.read(profileProvider.notifier).changePassword(
          currentPassword: currentCtrl.text,
          newPassword: newCtrl.text,
        );
    if (ok) {
      AnalyticsService.logEvent('profile_password_changed');
    }
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.user});
  final AuthUserModel user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phiên đăng nhập',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Bạn đang đăng nhập với vai trò ${_roleLabel(user.role)}. '
              'Sử dụng menu đăng xuất trong thanh bên để kết thúc phiên.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

String _roleLabel(String role) {
  switch (role) {
    case 'ADMIN':
      return 'Quản trị viên';
    case 'MANAGER':
      return 'Quản lý';
    case 'STAFF':
      return 'Nhân viên';
    case 'STUDENT':
      return 'Học sinh';
    default:
      return role;
  }
}
