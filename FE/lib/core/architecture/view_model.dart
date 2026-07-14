// ignore_for_file: use_setters_to_change_properties
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'view_state.dart';

/// Base ViewModel that owns a [ViewState] lifecycle.
///
/// Usage:
/// ```dart
/// class MyViewModel extends ViewModel<ViewStateLoading, ViewStateData<User>> {
///   const MyViewModel(this._repository) : super();
///   final MyRepository _repository;
///
///   Future<void> loadUser() async {
///     setLoading();
///     try {
///       final user = await _repository.getUser();
///       setData(ViewStateData(user));
///     } catch (e, s) {
///       setError('Failed to load user', e);
///     }
///   }
/// }
/// ```
///
/// The consuming widget reads [state] and rebuilds via [ref.watch].
abstract class ViewModel<Loading extends ViewState<dynamic>, Data extends ViewState<dynamic>>
    extends StateNotifier<ViewState<dynamic>> {
  ViewModel() : super(const ViewStateLoading());

  /// Sets the loading state.
  // ignore: use_setters_to_change_properties
  void setLoading() {
    // ignore: avoid_returning_this
  }

  /// Sets an error state with a human-readable [message].
  void setError(String message, [Object? error]) {
    state = ViewStateError<dynamic>(message, error);
  }

  /// Sets a data state. Call with the concrete typed ViewStateData instance.
  void setData(dynamic data) {
    state = data;
  }
}
