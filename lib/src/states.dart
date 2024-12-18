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
  /// - [data]: Called when the state represents success, receiving a value of type [T] (the successful result).
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
  ///   data: (value) => 'Success: $value',
  ///   failure: (e) => 'Error: ${e?.message}',
  ///   cancelled: () => 'Cancelled',
  ///   running: () => 'Running',
  ///   orElse: () => 'Unknown state', // Required fallback function
  /// );
  /// ```
  ///
  /// If any of the optional parameters (`failure`, `cancelled`, `running`) are missing, you must provide [orElse]
  /// to ensure a valid fallback is available.
  R when<R>({
    required R Function(T value) data,
    R Function(Exception? exception)? failure,
    R Function()? cancelled,
    R Function()? running,
    required Function() orElse,
  }) {
    return switch (this) {
      IdleCommand<T>() => orElse.call(),
      CancelledCommand<T>() => cancelled?.call() ?? orElse(),
      RunningCommand<T>() => running?.call() ?? orElse(),
      FailureCommand<T>(:final error) => failure?.call(error) ?? orElse(),
      SuccessCommand<T>(:final value) => data.call(value) ?? orElse(),
    };
  }
}

/// Represents the idle state of a command (not running).
final class IdleCommand<T extends Object> extends CommandState<T> {
  const IdleCommand();
}

/// Represents the cancelled state of a command.
final class CancelledCommand<T extends Object> extends CommandState<T> {
  const CancelledCommand();
}

/// Represents the running state of a command.
final class RunningCommand<T extends Object> extends CommandState<T> {
  const RunningCommand();
}

/// Represents a command that failed to execute successfully.
final class FailureCommand<T extends Object> extends CommandState<T> {
  /// Creates a [FailureCommand] with the given [error].
  const FailureCommand(this.error);

  /// The error that occurred during execution.
  final Exception error;
}

/// Represents a command that executed successfully.
final class SuccessCommand<T extends Object> extends CommandState<T> {
  /// Creates a [SuccessCommand] with the given [value].
  const SuccessCommand(this.value);

  /// The result of the successful execution.
  final T value;
}
