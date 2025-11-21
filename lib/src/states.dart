part of 'command.dart';

/// Base class representing the state of a command.
sealed class CommandState<T extends Object> {
  const CommandState();

  /// Maps the current state to a value of type [R] based on the object's state.
  ///
  /// This method allows you to handle only specific states, with a required fallback [orElse]
  /// function for unhandled states. Returns a non-nullable value of type [R].
  ///
  /// - [success]: Called when the state represents success, receiving a value of type [T] (the successful result). Optional.
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
  ///   success: (value) => Text('Success: $value'),
  ///   failure: (e) => Text('Error: ${e?.message}'),
  ///   running: () => CircularProgressIndicator(),
  ///   orElse: () => Button(
  ///     onPressed: () => command.execute(),
  ///     child: Text('Execute'),
  ///   ),
  /// );
  /// ```
  R when<R>({
    R Function(T value)? success,
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
      SuccessCommand<T>(:final value) => success?.call(value) ?? orElse(),
    };
  }

  /// Maps the current state to a value of type [R] based on the object's state.
  ///
  /// This method allows you to handle only specific states. All parameters are optional,
  /// and returns a nullable value of type [R?]. If no handler matches the current state,
  /// returns null (or the result of [orElse] if provided).
  ///
  /// - [success]: Called when the state represents success, receiving a value of type [T] (the successful result). Optional.
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
  ///   success: (value) => context.go('/success'),
  ///   failure: (e) => showErrorSnackBar(e),
  /// );
  /// ```
  R? maybeWhen<R>({
    R Function(T value)? success,
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
      SuccessCommand<T>(:final value) => success?.call(value) ?? orElse?.call(),
    };
  }

  /// Returns the current state as a string representation.
  /// This is useful for debugging and logging purposes.
  String get instanceName;

  bool get isIdle => this is IdleCommand<T>;
  bool get isRunning => this is RunningCommand<T>;
  bool get isSuccess => this is SuccessCommand<T>;
  bool get isFailure => this is FailureCommand<T>;
  bool get isCancelled => this is CancelledCommand<T>;
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
  /// Creates a [SuccessCommand] with the given [value].
  const SuccessCommand(this.value);

  /// The result of the successful execution.
  final T value;

  @override
  final String instanceName = 'SuccessCommand';
}
