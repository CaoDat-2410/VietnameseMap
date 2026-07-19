import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../shared/auth_routes.dart';
import '../providers/auth_view_state.dart';
import '../providers/auth_viewmodel.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authViewModelProvider.notifier).registerWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    final l10n = AppLocalizations.of(context)!;

    ref.listen(authViewModelProvider, (previous, next) {
      if (next is AuthViewStateData && next.user != null) {
        context.go(landingPathForRole(next.user!.role));
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context.go('/login'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.signUp,
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (errorMessage != null) ...[
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
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.required;
                        if (v.length < 6)
                          return 'Mat khau phai co it nhat 6 ky tu';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration:
                          const InputDecoration(labelText: 'Xac nhan mat khau'),
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (v) {
                        if (v != _passwordController.text) {
                          return 'Mat khau khong khop';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      child: FilledButton(
                        onPressed: isLoading ? null : _submit,
                        child: Text(isLoading ? l10n.signingIn : l10n.signUp),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Da co tai khoan? ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed:
                              isLoading ? null : () => context.go('/login'),
                          child: Text(l10n.loginButton),
                        ),
                      ],
                    ),
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
