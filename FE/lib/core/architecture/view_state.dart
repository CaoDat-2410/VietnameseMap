/// Base ViewState class for the VN Map Campaign app.
///
/// `AuthViewState` is the sealed subtype used in the app.
/// This base exists for documentation and to establish the naming convention.
class ViewState<T> {
  const ViewState();
}

/// Loading state — widget shows a loading indicator.
class ViewStateLoading<T> extends ViewState<T> {
  const ViewStateLoading();
}

/// Error state — widget shows an error message with optional retry.
class ViewStateError<T> extends ViewState<T> {
  const ViewStateError(this.message, [this.error]);
  final String message;
  final Object? error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewStateError<T> &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          error.toString() == other.error.toString();

  @override
  int get hashCode => message.hashCode ^ error.hashCode;
}

/// Data state — widget shows the data.
class ViewStateData<T> extends ViewState<T> {
  const ViewStateData(this.data);
  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewStateData<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}
