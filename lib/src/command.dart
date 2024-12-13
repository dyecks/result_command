import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:result_dart/functions.dart';
import 'package:result_dart/result_dart.dart';

/// Represents a command history entry with timestamp and metadata.
class CommandHistoryEntry<T extends Object> {
  /// The state of the command at this point in time.
  final CommandState<T> state;

  /// The timestamp when the state change occurred.
  final DateTime timestamp;

  /// Optional additional metadata about the state change.
  final Map<String, dynamic>? metadata;

  CommandHistoryEntry({
    required this.state,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'CommandHistoryEntry(state: $state, timestamp: $timestamp, metadata: $metadata)';
  }
}

/// Manages the history of command states.
mixin CommandHistoryManager<T extends Object> {
  /// The maximum length of the state history.
  late int maxHistoryLength;

  /// A list to maintain the history of state changes.
  final List<CommandHistoryEntry<T>> _stateHistory = [];

  /// Initializes the history manager with a maximum length.
  void initializeHistoryManager(int maxHistoryLength) {
    this.maxHistoryLength = maxHistoryLength;
  }

  /// Provides read-only access to the state change history.
  List<CommandHistoryEntry<T>> get stateHistory =>
      List.unmodifiable(_stateHistory);

  /// Adds a new entry to the history and ensures the history length limit.
  void addHistoryEntry(CommandHistoryEntry<T> entry) {
    _stateHistory.add(entry);
    if (_stateHistory.length > maxHistoryLength) {
      _stateHistory.removeAt(0);
    }
  }
}

/// Notifies state changes of the command.
mixin CommandStateNotifier<T extends Object> on ChangeNotifier {
  /// A [StreamController] that broadcasts state changes to external observers.
  final StreamController<CommandState<T>> _stateController =
      StreamController<CommandState<T>>.broadcast();

  /// Provides a stream of [CommandState] changes, allowing external listeners
  /// to react to state updates in real-time.
  Stream<CommandState<T>> get stateStream => _stateController.stream;

  /// Notifies listeners and external observers of a state change.
  void notifyStateChange(CommandState<T> state) {
    if (!_stateController.isClosed) {
      _stateController.add(state);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stateController.close(); // Close the stream when the object is disposed.
    super.dispose();
  }
}

/// Represents a generic command with lifecycle and execution.
///
/// This class supports state management, notifications, and execution
/// with optional cancellation and history tracking.
abstract class Command<T extends Object> extends ChangeNotifier
    with CommandHistoryManager<T>, CommandStateNotifier<T>
    implements ValueListenable<CommandState<T>> {
  /// Callback executed when the command is cancelled.
  final void Function()? onCancel;

  Command([this.onCancel, int maxHistoryLength = 10]) : super() {
    initializeHistoryManager(maxHistoryLength);
    _setValue(IdleCommand<T>(), metadata: {'reason': 'Command created'});
  }

  /// The current state of the command.
  CommandState<T> _value = IdleCommand<T>();

  @override
  CommandState<T> get value => _value;

  /// Cancels the execution of the command.
  ///
  /// If the command is in the [RunningCommand] state, the [onCancel] callback is invoked,
  /// and the state transitions to [CancelledCommand].
  void cancel({Map<String, dynamic>? metadata}) {
    if (value is RunningCommand<T>) {
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
    if (value is RunningCommand<T>) {
      return;
    } // Prevent multiple concurrent executions.
    _setValue(RunningCommand<T>(), metadata: {'status': 'Execution started'});
    bool hasError = false;

    Result<T>? result;
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
      if ((result == null) && !hasError) {
        _setValue(IdleCommand<T>());
      } else {
        if (!hasError) {
          final newValue = result!
              .map(SuccessCommand<T>.new)
              .mapError(FailureCommand<T>.new)
              .fold(identity, identity);
          if (value is RunningCommand<T>) {
            _setValue(newValue);
          }
        }
      }
    }
  }

  /// Sets the current state of the command and notifies listeners.
  ///
  /// Additionally, emits the new state to the [stateStream] for external observers
  /// and records the change in the state history with optional metadata.
  void _setValue(CommandState<T> newValue, {Map<String, dynamic>? metadata}) {
    if ((newValue == _value) && stateHistory.isNotEmpty) return;
    _value = newValue;
    addHistoryEntry(CommandHistoryEntry(state: newValue, metadata: metadata));
    notifyStateChange(newValue);
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

/// A function that defines a command action with no arguments.
/// The action returns an [AsyncResult] of type [T].
typedef CommandAction0<T extends Object> = AsyncResult<T> Function();

/// A function that defines a command action with one argument of type [A].
/// The action returns an [AsyncResult] of type [T].
typedef CommandAction1<T extends Object, A> = AsyncResult<T> Function(A);

/// A function that defines a command action with two arguments of types [A] and [B].
/// The action returns an [AsyncResult] of type [T].
typedef CommandAction2<T extends Object, A, B> = AsyncResult<T> Function(A, B);
