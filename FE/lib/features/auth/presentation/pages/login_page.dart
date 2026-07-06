import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/providers/remote_config_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../shared/auth_routes.dart';
import '../providers/auth_view_state.dart';
import '../providers/auth_viewmodel.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool get _googleSignInEnabled {
    final flags = ref.watch(remoteConfigProvider);
    return flags.googleSignInEnabled;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authViewModelProvider.notifier).loginWithPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      final credential = await FirebaseAuth.instance.signInWithPopup(provider);
      final idToken = await credential.user?.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-id-token',
          message: 'Google sign-in did not return an ID token.',
        );
      }
      await ref.read(authViewModelProvider.notifier).loginWithGoogle(idToken);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng nhập Google thất bại: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    final l10n = AppLocalizations.of(context)!;

    // On successful login, navigate to role-specific home
    ref.listen(authViewModelProvider, (previous, next) {
      if (next is AuthViewStateData && next.user != null) {
        final role = next.user!.role;
        final method = next.loginMethod;
        if (method != null) {
          AnalyticsService.logEvent('login', {'method': method});
        }
        context.go(landingPathForRole(role));
      }
    });

    final isLoading = state is AuthViewStateLoading;
    final errorMessage = state is AuthViewStateError ? state.message : null;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.appTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.signInToContinue,
                      textAlign: TextAlign.center,
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: l10n.email),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      validator: (v) =>
                          v?.trim().isEmpty == true ? l10n.required : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: l10n.password),
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) {
                        if (!isLoading) _submit();
                      },
                      validator: (v) =>
                          v?.trim().isEmpty == true ? l10n.required : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isLoading ? null : _submit,
                        child: Text(
                            isLoading ? l10n.signingIn : l10n.loginButton),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_googleSignInEnabled) ...[
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'hoặc',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : _handleGoogleSignIn,
                          icon: const Icon(Icons.g_mobiledata, size: 24),
                          label: const Text('Đăng nhập với Google'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

