part of 'command.dart';

/// Base class representing the state of a command.
sealed class CommandState<T extends Object> {
  const CommandState();

  /// Maps the current state to a value of type [R] based on the object's state.
  ///
  /// This method allows you to handle different states of an object (`Idle`, `Cancelled`, `Running`, `Failure`, and `Success`),
  /// and map each state to a corresponding value of type [R]. If no handler for a specific state is provided, the fallback
  /// function [orElse] will be invoked.
  ///
  /// - [success]: Called when the state represents success, receiving a value of type [T] (the successful result).
  /// - [failure]: Called when the state represents failure, receiving an [Exception?]. Optional.
  /// - [cancelled]: Called when the state represents cancellation. Optional.
  /// - [running]: Called when the state represents a running operation. Optional.
  /// - [orElse]: A fallback function that is called when the state does not match any of the provided states.
  ///   It is required and will be used when any of the other parameters are not provided or when no state matches.
  ///
  /// Returns a value of type [R] based on the state of the object. If no matching state handler is provided, the fallback
  /// function [orElse] will be called.
  ///
  /// Example:
  /// ```dart
  /// final result = command.value.when<String>(
  ///   success: (value) => 'Success: $value',
  ///   failure: (e) => 'Error: ${e?.message}',
  ///   cancelled: () => 'Cancelled',
  ///   running: () => 'Running',
  ///   orElse: () => 'Unknown state',
  /// );
  /// ```
  R? when<R>({
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
