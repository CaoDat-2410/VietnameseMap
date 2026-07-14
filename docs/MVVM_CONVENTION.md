# MVVM Architecture Convention — VN Map Campaign

## Overview

This document defines the **Model-View-ViewModel** pattern used throughout the VN Map Campaign Flutter app.

## Layers

| Layer | Location | Responsibility |
|-------|----------|---------------|
| **Model** | `features/*/shared/models/` | Immutable data classes (freezed) representing domain entities and API DTOs |
| **Repository** | `features/*/data/repositories/` | Data access layer — one repository per feature domain. Makes API calls, handles caching. **No business logic here.** |
| **ViewModel** | `features/*/presentation/providers/` | Business logic + state management. Calls repository, transforms data, logs analytics, owns `ViewState` |
| **View (Widget)** | `features/*/presentation/pages/` | Pure UI — reads `ref.watch(xxxViewModelProvider)`, dispatches user intents. **No direct API calls.** |

## State Management Pattern

Every screen ViewModel extends [ViewModel] and manages a `ViewState`:

```dart
// 1. Define the typed ViewState for this feature
sealed class AuthViewState extends ViewState<AuthUserModel?> {
  const AuthViewState._(super.state, {this.loginMethod});
  factory AuthViewState.loading() => const AuthViewState._(ViewStateLoading());
  factory AuthViewState.data(AuthUserModel? user, {String? loginMethod}) =>
      AuthViewState._(ViewStateData(user), loginMethod: loginMethod);
  factory AuthViewState.error(String msg, Object e) =>
      AuthViewState._(ViewStateError(msg, e));
  final String? loginMethod;
}

// 2. Define the ViewModel Notifier
class AuthViewModel extends StateNotifier<AuthViewState> {
  AuthViewModel(this._repository) : super(AuthViewState.loading()) {
    _loadCurrentUser();
  }
  final AuthRepository _repository;

  Future<void> login(String email, String password) async {
    state = AuthViewState.loading();
    try {
      final user = await _repository.login(email: email, password: password);
      state = AuthViewState.data(user, loginMethod: 'password');
    } catch (e, s) {
      state = AuthViewState.error('Email hoặc mật khẩu không đúng', e);
    }
  }
}

// 3. Provide it
final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthViewState>((ref) {
  return AuthViewModel(ref.watch(authRepositoryProvider));
});

// 4. Consume in the View
class LoginPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authViewModelProvider);
    return switch (state) {
      ViewStateLoading() => const CircularProgressIndicator(),
      ViewStateError(:final message) => Text(message),
      ViewStateData(:final data) => HomePage(user: data),
      AuthViewState(:final loginMethod) => Text('Logged in via $loginMethod'),
    };
  }
}
```

## ViewState Contract

- **`ViewStateLoading`** — widget shows a loading indicator (Spinner, Shimmer, etc.)
- **`ViewStateError`** — widget shows an error message with an optional retry action
- **`ViewStateData`** — widget shows the data; for nullable types, handle `null` as the "not logged in" state

## Analytics Integration

ViewModels are the **only** place where `AnalyticsService.logEvent()` calls belong. Never call analytics from widgets.

```dart
// In ViewModel:
AnalyticsService.logEvent('campaign_view', {'campaign_id': campaignId});
```

## Remote Config Integration

Remote config flags are accessed via `RemoteConfigProvider`. ViewModels check flags before enabling features:

```dart
final flags = ref.watch(remoteConfigProvider).valueOrNull;
final googleSigninEnabled = flags?.googleSigninEnabled ?? true;
```

## Naming Conventions

| Pattern | Example |
|---------|---------|
| ViewModel class | `AuthViewModel`, `CampaignListViewModel` |
| Provider | `authViewModelProvider`, `campaignListViewModelProvider` |
| State file | `auth_view_state.dart`, `campaign_list_view_state.dart` |
| ViewModel file | `auth_viewmodel.dart`, `campaign_list_viewmodel.dart` |
| Repository | `auth_repository.dart`, `campaign_repository.dart` |
| Model | `auth_models.dart`, `campaign_models.dart` |
