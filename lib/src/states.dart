part of 'command.dart';

/// Base class representing the state of a command.
sealed class CommandState<T extends Object> {
  const CommandState();

  /// Returns the current state as a string representation.
  /// This is useful for debugging and logging purposes.
  String get instanceName;

  bool get isIdle => this is IdleCommand<T>;
  bool get isRunning => this is RunningCommand<T>;
  bool get isSuccess => this is SuccessCommand<T>;
  bool get isFailure => this is FailureCommand<T>;
  bool get isCancelled => this is CancelledCommand<T>;

  /// Maps the current state to a value of type [R] based on the object's state.
  ///
  /// This method allows you to handle only specific states, with a required fallback [orElse]
  /// function for unhandled states. Returns a non-nullable value of type [R].
  ///
  /// - [success]: Called when the state represents success, receiving the data of type [T] (the successful result). Optional.
  /// - [failure]: Called when the state represents failure, receiving an [Exception?]. Optional.
  /// - [idle]: Called when the state represents idle (not running). Optional.
  /// - [cancelled]: Called when the state represents cancellation. Optional.
  /// - [running]: Called when the state represents a running operation. Optional.
  /// - [orElse]: A required fallback function that is called when the state does not match any of the provided states.
  ///
  /// Returns a non-nullable value of type [R] based on the state of the object.
  ///
  /// Example:
  /// ```dart
  /// return command.state.when<Widget>(
  ///   success: (data) => Text('Success: $data'),
  ///   failure: (e) => Text('Error: ${e?.message}'),
  ///   running: () => CircularProgressIndicator(),
  ///   orElse: () => Button(
  ///     onPressed: () => command.execute(),
  ///     child: Text('Execute'),
  ///   ),
  /// );
  /// ```
  R when<R>({
    R Function(T data)? success,
    R Function(Exception? exception)? failure,
    R Function()? idle,
    R Function()? running,
    R Function()? cancelled,
    required R Function() orElse,
  }) {
    return switch (this) {
      IdleCommand<T>() => idle?.call() ?? orElse(),
      CancelledCommand<T>() => cancelled?.call() ?? orElse(),
      RunningCommand<T>() => running?.call() ?? orElse(),
      FailureCommand<T>(:final error) => failure?.call(error) ?? orElse(),
      SuccessCommand<T>(:final data) => success?.call(data) ?? orElse(),
    };
  }

  /// Maps the current state to a value of type [R] based on the object's state.
  ///
  /// This method allows you to handle only specific states. All parameters are optional,
  /// and returns a nullable value of type [R?]. If no handler matches the current state,
  /// returns null (or the result of [orElse] if provided).
  ///
  /// - [success]: Called when the state represents success, receiving the data of type [T] (the successful result). Optional.
  /// - [failure]: Called when the state represents failure, receiving an [Exception?]. Optional.
  /// - [idle]: Called when the state represents idle (not running). Optional.
  /// - [cancelled]: Called when the state represents cancellation. Optional.
  /// - [running]: Called when the state represents a running operation. Optional.
  /// - [orElse]: A fallback function that is called when the state does not match any of the provided states. Optional.
  ///
  /// Returns a nullable value of type [R?] based on the state of the object.
  ///
  /// Example:
  /// ```dart
  /// await command.execute();
  /// command.state.maybeWhen(
  ///   success: (data) => context.go('/success'),
  ///   failure: (e) => showErrorSnackBar(e),
  /// );
  /// ```
  R? maybeWhen<R>({
    R Function(T data)? success,
    R Function(Exception? exception)? failure,
    R Function()? idle,
    R Function()? running,
    R Function()? cancelled,
    R Function()? orElse,
  }) {
    return switch (this) {
      IdleCommand<T>() => idle?.call() ?? orElse?.call(),
      CancelledCommand<T>() => cancelled?.call() ?? orElse?.call(),
      RunningCommand<T>() => running?.call() ?? orElse?.call(),
      FailureCommand<T>(:final error) => failure?.call(error) ?? orElse?.call(),
      SuccessCommand<T>(:final data) => success?.call(data) ?? orElse?.call(),
    };
  }

  /// Executes [action] if this is an [IdleCommand].
  ///
  /// Example:
  /// ```dart
  /// command.state.ifIdle(() => print('Command is idle'));
  /// ```
  void ifIdle(void Function() action) {
    if (this case IdleCommand<T>()) {
      action();
    }
  }

  /// Executes [action] if this is a [RunningCommand].
  ///
  /// Example:
  /// ```dart
  /// command.state.ifRunning(() => showLoadingIndicator());
  /// ```
  void ifRunning(void Function() action) {
    if (this case RunningCommand<T>()) {
      action();
    }
  }

  /// Executes [action] if this is a [SuccessCommand], passing the [data].
  ///
  /// Example:
  /// ```dart
  /// command.state.ifSuccess((data) => showData(data));
  /// ```
  void ifSuccess(void Function(T data) action) {
    if (this case SuccessCommand<T>(:final data)) {
      action(data);
    }
  }

  /// Executes [action] if this is a [FailureCommand], passing the [error].
  ///
  /// Example:
  /// ```dart
  /// command.state.ifFailure((error) => showError(context, error));
  /// ```
  void ifFailure(void Function(Exception error) action) {
    if (this case FailureCommand<T>(:final error)) {
      action(error);
    }
  }

  /// Executes [action] if this is a [CancelledCommand].
  ///
  /// Example:
  /// ```dart
  /// command.state.ifCancelled(() => showCancelledMessage());
  /// ```
  void ifCancelled(void Function() action) {
    if (this case CancelledCommand<T>()) {
      action();
    }
  }
}

/// Represents the idle state of a command (not running).
final class IdleCommand<T extends Object> extends CommandState<T> {
  const IdleCommand();

  @override
  final String instanceName = 'IdleCommand';
}

/// Represents the cancelled state of a command.
final class CancelledCommand<T extends Object> extends CommandState<T> {
  const CancelledCommand();

  @override
  final String instanceName = 'CancelledCommand';
}

/// Represents the running state of a command.
final class RunningCommand<T extends Object> extends CommandState<T> {
  const RunningCommand();

  @override
  final String instanceName = 'RunningCommand';
}

/// Represents a command that failed to execute successfully.
final class FailureCommand<T extends Object> extends CommandState<T> {
  /// Creates a [FailureCommand] with the given [error].
  const FailureCommand(this.error);

  /// The error that occurred during execution.
  final Exception error;

  @override
  final String instanceName = 'FailureCommand';
}

/// Represents a command that executed successfully.
final class SuccessCommand<T extends Object> extends CommandState<T> {
  /// Creates a [SuccessCommand] with the given [data].
  const SuccessCommand(this.data);

  /// The result of the successful execution.
  final T data;

  @override
  final String instanceName = 'SuccessCommand';
}
