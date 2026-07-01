import '../../../../core/architecture/view_state.dart';
import '../../shared/models/auth_models.dart';

/// Typed ViewState for the Auth feature.
///
/// Extends [ViewState] with a `loginMethod` field that tracks how the
/// user authenticated (password | google).
///
/// Consumers use `switch` or `is` checks to narrow the type.
sealed class AuthViewState extends ViewState<AuthUserModel?> {
  const AuthViewState._();
}

final class AuthViewStateLoading extends AuthViewState {
  const AuthViewStateLoading() : super._();
}

final class AuthViewStateError extends AuthViewState {
  const AuthViewStateError(this.message) : super._();
  final String message;
}

final class AuthViewStateData extends AuthViewState {
  const AuthViewStateData(this.user, {this.loginMethod}) : super._();
  final AuthUserModel? user;
  final String? loginMethod;
}
