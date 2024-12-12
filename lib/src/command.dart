import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:result_dart/functions.dart';
import 'package:result_dart/result_dart.dart';

/// A function that defines a command action with no arguments.
/// The action returns an [AsyncResult] of type [T].
typedef CommandAction0<T extends Object> = AsyncResult<T> Function();

/// A function that defines a command action with one argument of type [A].
/// The action returns an [AsyncResult] of type [T].
typedef CommandAction1<T extends Object, A> = AsyncResult<T> Function(A);

/// A function that defines a command action with two arguments of types [A] and [B].
/// The action returns an [AsyncResult] of type [T].
typedef CommandAction2<T extends Object, A, B> = AsyncResult<T> Function(A, B);

/// Represents a command that encapsulates a specific action to be executed.
///
/// A [Command] maintains state transitions during its lifecycle, such as:
/// - Idle: The command is not running.
/// - Running: The command is currently executing an action.
/// - Success: The action completed successfully with a result.
/// - Failure: The action failed with an error.
/// - Cancelled: The action was explicitly cancelled.
///
/// Commands can notify listeners about state changes and handle cancellations.
///
/// Use [Command0] for actions with no arguments,
/// [Command1] for actions with one argument, and [Command2] for actions with two arguments.
///
/// The generic parameter [T] defines the type of result returned by the command.
abstract class Command<T extends Object> extends ChangeNotifier //
    implements
        ValueListenable<CommandState<T>> {
  /// Creates a new [Command] with an optional [onCancel] callback.
  ///
  /// The [onCancel] callback is invoked when the command is explicitly cancelled.
  Command([this.onCancel]);

  /// Callback executed when the command is cancelled.
  final void Function()? onCancel;

  /// The current state of the command.
  CommandState<T> _value = IdleCommand<T>();

  bool get isIdle => value is IdleCommand<T>;

  bool get isRunning => value is RuningCommand<T>;

  bool get isCancelled => value is CancelledCommand<T>;

  bool get isSuccess => value is SuccessCommand<T>;

  bool get isFailure => value is FailureCommand<T>;

  @override
  CommandState<T> get value => _value;

  /// Cancels the execution of the command.
  ///
  /// If the command is in the [RuningCommand] state, the [onCancel] callback is invoked,
  /// and the state transitions to [CancelledCommand].
  void cancel() {
    if (isRunning) {
      onCancel?.call();
      _setValue(CancelledCommand<T>());
    }
  }

  /// Sets the current state of the command and notifies listeners.
  void _setValue(CommandState<T> newValue) {
    if (newValue == _value) return;
    _value = newValue;
    notifyListeners();
  }

  /// Resets the command state to [IdleCommand].
  ///
  /// This clears the current state, allowing the command to be reused.
  void reset() {
    _setValue(IdleCommand<T>());
  }

  /// Executes the given [action] and updates the command state accordingly.
  ///
  /// The state transitions to [RuningCommand] during execution,
  /// and to either [SuccessCommand] or [FailureCommand] upon completion.
  ///
  /// If the command is cancelled during execution, the result is ignored.
  Future<void> _execute(CommandAction0<T> action) async {
    if (isRunning) return; // Prevent multiple concurrent executions.
    _setValue(RuningCommand<T>());

    Result<T>? result;
    try {
      result = await action();
    } finally {
      if (result == null) {
        _setValue(IdleCommand<T>());
      } else {
        final newValue = result //
            .map(SuccessCommand<T>.new)
            .mapError(FailureCommand<T>.new)
            .fold(identity, identity);
        if (isRunning) {
          _setValue(newValue);
        }
      }
    }
  }
}

/// A command that executes an action without any arguments.
///
/// The generic parameter [T] defines the type of result returned by the action.
final class Command0<T extends Object> extends Command<T> {
  /// Creates a [Command0] with the specified [action] and optional [onCancel] callback.
  Command0(this._action, {void Function()? onCancel}) : super(onCancel);

  /// The action to be executed.
  final CommandAction0<T> _action;

  /// Executes the action and updates the command state.
  Future<void> execute() async {
    await _execute(() => _action());
  }
}

/// A command that executes an action with one argument.
///
/// The generic parameters [T] and [A] define the result type and the argument type, respectively.
final class Command1<T extends Object, A> extends Command<T> {
  /// Creates a [Command1] with the specified [action] and optional [onCancel] callback.
  Command1(this._action, {void Function()? onCancel}) : super(onCancel);

  /// The action to be executed.
  final CommandAction1<T, A> _action;

  /// Executes the action with the given [argument] and updates the command state.
  Future<void> execute(A argument) async {
    await _execute(() => _action(argument));
  }
}

/// A command that executes an action with two arguments.
///
/// The generic parameters [T], [A], and [B] define the result type and the types of the two arguments.
final class Command2<T extends Object, A, B> extends Command<T> {
  /// Creates a [Command2] with the specified [action] and optional [onCancel] callback.
  Command2(this._action, {void Function()? onCancel}) : super(onCancel);

  /// The action to be executed.
  final CommandAction2<T, A, B> _action;

  /// Executes the action with the given [argument1] and [argument2],
  /// and updates the command state.
  Future<void> execute(A argument1, B argument2) async {
    await _execute(() => _action(argument1, argument2));
  }
}

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
final class RuningCommand<T extends Object> extends CommandState<T> {
  const RuningCommand();
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
