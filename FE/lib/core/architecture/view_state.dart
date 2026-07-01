sealed class ViewState<T> {
  const ViewState();
}

final class ViewStateLoading<T> extends ViewState<T> {
  const ViewStateLoading();
}

final class ViewStateError<T> extends ViewState<T> {
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

final class ViewStateData<T> extends ViewState<T> {
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
