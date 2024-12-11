// Copyright 2024 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:result_dart/result_dart.dart';

/// Defines a command action that returns a [Result] of type [T].
/// Used by [Command0] for actions without arguments.
typedef CommandAction0<T extends Object> = AsyncResult<T> Function();

/// Defines a command action that returns a [Result] of type [T].
/// Takes an argument of type [A].
/// Used by [Command1] for actions with one argument.
typedef CommandAction1<T extends Object, A> = AsyncResult<T> Function(A);

/// Facilitates interaction with a view model.
///
/// Encapsulates an action,
/// exposes its running and error states,
/// and ensures that it can't be launched again until it finishes.
///
/// Use [Command0] for actions without arguments.
/// Use [Command1] for actions with one argument.
///
/// Actions must return a [Result] of type [T].
///
/// Consume the action result by listening to changes,
/// then call to [clearResult] when the state is consumed.
abstract class Command<T extends Object> extends ChangeNotifier implements ValueListenable<CommandSnapshot<T>> {
  CommandSnapshot<T> _value = IdleCommand<T>();

  @override
  CommandSnapshot<T> get value => _value;

  void _setValue(CommandSnapshot<T> newValue) {
    if (newValue == _value) return;
    _value = newValue;
    notifyListeners();
  }

  Result<T>? _result;

  /// Clears the most recent action's result.
  void clearResult() {
    _result = null;
    notifyListeners();
  }

  /// Execute the provided [action], notifying listeners and
  /// setting the running and result states as necessary.
  Future<void> _execute(CommandAction0<T> action) async {
    // Ensure the action can't launch multiple times.
    // e.g. avoid multiple taps on button
    if (value is RuningCommand<T>) return;
    _result = null;
    _setValue(RuningCommand<T>());

    _result = await action();
    _result! //
        .map(SuccessCommand.new)
        .mapError(FailureCommand.new)
        .fold(_setValue, (e) => _setValue(e as FailureCommand<T>));
  }
}

/// A [Command] that accepts no arguments.
final class Command0<T extends Object> extends Command<T> {
  /// Creates a [Command0] with the provided [CommandAction0].
  Command0(this._action);

  final CommandAction0<T> _action;

  /// Executes the action.
  Future<void> execute() async {
    await _execute(() => _action());
  }
}

/// A [Command] that accepts one argument.
final class Command1<T extends Object, A> extends Command<T> {
  /// Creates a [Command1] with the provided [CommandAction1].
  Command1(this._action);

  final CommandAction1<T, A> _action;

  /// Executes the action with the specified [argument].
  Future<void> execute(A argument) async {
    await _execute(() => _action(argument));
  }
}

sealed class CommandSnapshot<T extends Object> {
  const CommandSnapshot();
}

final class IdleCommand<T extends Object> extends CommandSnapshot<T> {
  const IdleCommand();
}

final class RuningCommand<T extends Object> extends CommandSnapshot<T> {
  const RuningCommand();
}

final class FailureCommand<T extends Object> extends CommandSnapshot<T> {
  const FailureCommand(this.error);

  final dynamic error;
}

final class SuccessCommand<T extends Object> extends CommandSnapshot<T> {
  const SuccessCommand(this.value);

  final T value;
}
