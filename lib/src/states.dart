part of 'command.dart';

/// Base class representing the state of a command.
sealed class CommandState<T extends Object> {
  const CommandState();
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
