import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:result_dart/functions.dart';
import 'package:result_dart/result_dart.dart';

part 'history.dart';
part 'implementations.dart';
part 'states.dart';
part 'types.dart';

/// Represents a generic command with lifecycle and execution.
///
/// This class supports state management, notifications, and execution
/// with optional cancellation and history tracking.
abstract class Command<T extends Object> extends ChangeNotifier
    with CommandHistoryManager<T>
    implements ValueListenable<CommandState<T>> {
  /// Callback executed when the command is cancelled.
  final void Function()? onCancel;

  Command([this.onCancel, int maxHistoryLength = 10]) : super() {
    initializeHistoryManager(maxHistoryLength);
    _setValue(IdleCommand<T>(), metadata: {'reason': 'Command created'});
  }

  /// The current state of the command.
  CommandState<T> _value = IdleCommand<T>();

  ///[isIdle]: Checks if the command is in the idle state.
  bool get isIdle => value is IdleCommand<T>;

  ///[isRunning]: Checks if the command is currently running.
  bool get isRunning => value is RunningCommand<T>;

  ///[isCancelled]: Checks if the command has been cancelled.
  bool get isCancelled => value is CancelledCommand<T>;

  ///[isSuccess]:Checks if the command execution was successful.
  bool get isSuccess => value is SuccessCommand<T>;

  ///[isFailure]: Checks if the command execution failed.
  bool get isFailure => value is FailureCommand<T>;

  @override
  CommandState<T> get value => _value;

  /// Cancels the execution of the command.
  ///
  /// If the command is in the [RunningCommand] state, the [onCancel] callback is invoked,
  /// and the state transitions to [CancelledCommand].
  void cancel({Map<String, dynamic>? metadata}) {
    if (isRunning) {
      try {
        onCancel?.call();
      } catch (e) {
        _setValue(FailureCommand<T>(e is Exception ? e : Exception('$e')),
            metadata: metadata);
        return;
      }
      _setValue(CancelledCommand<T>(),
          metadata: metadata ?? {'reason': 'Manually cancelled'});
    }
  }

  /// Resets the command state to [IdleCommand].
  ///
  /// This clears the current state, allowing the command to be reused.
  void reset({Map<String, dynamic>? metadata}) {
    _setValue(IdleCommand<T>(),
        metadata: metadata ?? {'reason': 'Command reset'});
  }

  /// Executes the given [action] and updates the command state accordingly.
  ///
  /// The state transitions to [RunningCommand] during execution,
  /// and to either [SuccessCommand] or [FailureCommand] upon completion.
  ///
  /// Optionally accepts a [timeout] duration to limit the execution time of the action.
  /// If the action times out, the command is cancelled and transitions to [FailureCommand].
  Future<void> _execute(CommandAction0<T> action, {Duration? timeout}) async {
    if (isRunning) {
      return;
    } // Prevent multiple concurrent executions.
    _setValue(RunningCommand<T>(), metadata: {'status': 'Execution started'});
    bool hasError = false;

    late Result<T> result;
    try {
      if (timeout != null) {
        result = await action().timeout(timeout, onTimeout: () {
          cancel(metadata: {'reason': 'Execution timed out'});
          return Failure<T, Exception>(Exception("Command timed out"));
        });
      } else {
        result = await action();
      }
    } catch (e, stackTrace) {
      hasError = true;
      _setValue(FailureCommand<T>(Exception('Unexpected error: $e')),
          metadata: {'error': '$e', 'stackTrace': stackTrace.toString()});
      return;
    } finally {
      if (!hasError) {
        final newValue = result
            .map(SuccessCommand<T>.new)
            .mapError(FailureCommand<T>.new)
            .fold(identity, identity);
        if (isRunning) {
          _setValue(newValue);
        }
      }
    }
  }

  /// Sets the current state of the command and notifies listeners.
  ///
  /// Additionally, records the change in the state history with optional metadata.
  void _setValue(CommandState<T> newValue, {Map<String, dynamic>? metadata}) {
    if (newValue.runtimeType == _value.runtimeType && stateHistory.isNotEmpty) {
      return;
    }
    _value = newValue;
    addHistoryEntry(CommandHistoryEntry(state: newValue, metadata: metadata));
    notifyListeners(); // Notify listeners using ChangeNotifier.
  }
}

/// A command that executes an action without any arguments.
final class Command0<T extends Object> extends Command<T> {
  /// The action to be executed.
  final CommandAction0<T> _action;

  /// Creates a [Command0] with the specified [action] and optional [onCancel] callback.
  Command0(this._action, {void Function()? onCancel, int maxHistoryLength = 10})
      : super(onCancel, maxHistoryLength);

  /// Executes the action and updates the command state.
  Future<void> execute({Duration? timeout}) async {
    await _execute(() => _action(), timeout: timeout);
  }
}

/// A command that executes an action with one argument.
final class Command1<T extends Object, A> extends Command<T> {
  /// The action to be executed.
  final CommandAction1<T, A> _action;

  /// Creates a [Command1] with the specified [action] and optional [onCancel] callback.
  Command1(this._action, {void Function()? onCancel, int maxHistoryLength = 10})
      : super(onCancel, maxHistoryLength);

  /// Executes the action with the given [argument] and updates the command state.
  Future<void> execute(A argument, {Duration? timeout}) async {
    await _execute(() => _action(argument), timeout: timeout);
  }
}

/// A command that executes an action with two arguments.
final class Command2<T extends Object, A, B> extends Command<T> {
  /// The action to be executed.
  final CommandAction2<T, A, B> _action;

  /// Creates a [Command2] with the specified [action] and optional [onCancel] callback.
  Command2(this._action, {void Function()? onCancel, int maxHistoryLength = 10})
      : super(onCancel, maxHistoryLength);

  /// Executes the action with the given [argument1] and [argument2],
  /// and updates the command state.
  Future<void> execute(A argument1, B argument2, {Duration? timeout}) async {
    await _execute(() => _action(argument1, argument2), timeout: timeout);
  }
}
