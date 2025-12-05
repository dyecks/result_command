import 'package:flutter_test/flutter_test.dart';

import 'package:result_dart/result_dart.dart';

import 'package:result_command/src/command.dart';

void main() {
  group('Command tests', () {
    test('User getters', () async {
      int value = 0;

      AsyncResult<String> action() async {
        await Future.delayed(const Duration(milliseconds: 100));
        value++;

        if (value >= 2) {
          return Failure(Exception('error'));
        }

        return Success('success $value');
      }

      final command = Command0<String>(action);
      await command.execute();

      expect(command.getCachedSuccess(), 'success 1');

      await command.execute();
      expect(command.getCachedFailure(), isA<Exception>());
    });

    test('Command0 executes successfully', () async {
      AsyncResult<String> action() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return const Success('success');
      }

      final command = Command0<String>(action);
      final states = <CommandState<String>>[];

      command.addListener(() {
        states.add(command.state);
      });

      await command.execute();
      expect(states, [
        isA<RunningCommand<String>>(),
        isA<SuccessCommand<String>>(),
      ]);

      expect(command.state, isA<SuccessCommand<String>>());

      // Verify history
      final history = command.stateHistory;
      expect(history.length, 3);
      expect(history[0].state, isA<IdleCommand<String>>());
      expect(history[1].state, isA<RunningCommand<String>>());
      expect(history[2].state, isA<SuccessCommand<String>>());

      // Verify toString()
      final historyString = history.map((e) => e.toString()).toList();
      expect(historyString[0], contains('IdleCommand'));
      expect(historyString[1], contains('RunningCommand'));
      expect(historyString[2], contains('SuccessCommand'));
    });

    test('Command1 executes successfully with argument', () async {
      AsyncResult<String> action(String value) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return Success(value);
      }

      final command = Command1<String, String>(action);
      final states = <CommandState<String>>[];

      command.addListener(() {
        states.add(command.state);
      });

      await command.execute('Test');
      expect(states, [
        isA<RunningCommand<String>>(),
        isA<SuccessCommand<String>>(),
      ]);

      expect(command.state, isA<SuccessCommand<String>>());
      expect((command.state as SuccessCommand<String>).data, 'Test');

      // Verify history
      final history = command.stateHistory;
      expect(history.length, 3);
      expect(history[0].state, isA<IdleCommand<String>>());
      expect(history[1].state, isA<RunningCommand<String>>());
      expect(history[2].state, isA<SuccessCommand<String>>());

      // Verify toString()
      final historyString = history.map((e) => e.toString()).toList();
      expect(historyString[0], contains('IdleCommand'));
      expect(historyString[1], contains('RunningCommand'));
      expect(historyString[2], contains('SuccessCommand'));
    });

    test('Command cancels execution and catches exception', () async {
      AsyncResult<String> action() async {
        await Future.delayed(const Duration(seconds: 1));
        return const Success('success');
      }

      final command = Command0<String>(action, onCancel: () {
        throw Exception('Cancel exception');
      });
      final states = <CommandState<String>>[];

      command.addListener(() {
        states.add(command.state);
      });

      Future.delayed(const Duration(milliseconds: 100), () => command.cancel());

      await command.execute();
      expect(states, [
        isA<RunningCommand<String>>(),
        isA<FailureCommand<String>>(),
      ]);

      expect(command.state, isA<FailureCommand<String>>());

      // Verify history
      final history = command.stateHistory;
      expect(history.length, 3);
      expect(history[0].state, isA<IdleCommand<String>>());
      expect(history[1].state, isA<RunningCommand<String>>());
      expect(history[2].state, isA<FailureCommand<String>>());
    });

    test('Command fails gracefully', () async {
      AsyncResult<String> action() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return Failure(Exception('failure'));
      }

      final command = Command0<String>(action);
      final states = <CommandState<String>>[];

      command.addListener(() {
        states.add(command.state);
      });

      await command.execute();
      expect(states, [
        isA<RunningCommand<String>>(),
        isA<FailureCommand<String>>(),
      ]);

      expect(command.state, isA<FailureCommand<String>>());
      expect((command.state as FailureCommand<String>).error.toString(),
          contains('failure'));

      // Verify history
      final history = command.stateHistory;
      expect(history.length, 3);
      expect(history[0].state, isA<IdleCommand<String>>());
      expect(history[1].state, isA<RunningCommand<String>>());
      expect(history[2].state, isA<FailureCommand<String>>());

      // Verify toString()
      final historyString = history.map((e) => e.toString()).toList();
      expect(historyString[2], contains('FailureCommand'));
    });

    test('Command throws exception', () async {
      AsyncResult<String> action() async {
        await Future.delayed(const Duration(milliseconds: 100));
        throw Exception('Unexpected exception');
      }

      final command = Command0<String>(action);
      final states = <CommandState<String>>[];

      command.addListener(() {
        states.add(command.state);
      });

      await command.execute();
      expect(states, [
        isA<RunningCommand<String>>(),
        isA<FailureCommand<String>>(),
      ]);
      expect(command.state, isA<FailureCommand<String>>());
      expect((command.state as FailureCommand<String>).error.toString(),
          contains('Unexpected exception'));

      // Verify history
      final history = command.stateHistory;
      expect(history.length, 3);
      expect(history[0].state, isA<IdleCommand<String>>());
      expect(history[1].state, isA<RunningCommand<String>>());
      expect(history[2].state, isA<FailureCommand<String>>());

      // Verify toString()
      final historyString = history.map((e) => e.toString()).toList();
      expect(historyString[2], contains('FailureCommand'));
      expect(historyString[2], contains('Unexpected exception'));
    });

    test('Command sets state to CancelledCommand with metadata', () async {
      AsyncResult<String> action() async {
        await Future.delayed(const Duration(seconds: 2));
        return const Success('cancelled with metadata');
      }

      final command = Command0<String>(action);

      command.execute();

      command.cancel(metadata: {'customKey': 'customValue'});
      expect(command.state, isA<CancelledCommand<String>>());
      expect(command.stateHistory.last.metadata,
          containsPair('customKey', 'customValue'));
    });

    test('Command cancels manually and updates state to CancelledCommand',
        () async {
      AsyncResult<String> action() async {
        await Future.delayed(const Duration(seconds: 2));
        return const Success('manual cancellation');
      }

      final command = Command0<String>(action);

      command.execute();
      command.cancel();
      expect(command.state, isA<CancelledCommand<String>>());
      expect(command.stateHistory.last.state, isA<CancelledCommand<String>>());
    });

    test('Command with timeout in _execute', () async {
      AsyncResult<String> action() async {
        await Future.delayed(const Duration(seconds: 2));
        return const Success('success');
      }

      final command = Command0<String>(action);
      final states = <CommandState<String>>[];

      command.addListener(() {
        states.add(command.state);
      });

      await command.execute(timeout: const Duration(milliseconds: 500));
      expect(states.last, isA<CancelledCommand<String>>());
    });

    test('Command resets state', () async {
      AsyncResult<String> action() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return const Success('success');
      }

      final command = Command0<String>(action);
      final states = <CommandState<String>>[];

      command.addListener(() {
        states.add(command.state);
      });

      await command.execute();
      expect(command.state, isA<SuccessCommand<String>>());

      command.reset();
      expect(command.state, isA<IdleCommand<String>>());

      // Verify history after reset
      final history = command.stateHistory;
      expect(history.length,
          4); // Includes initial idle, running, success, and reset idle
      expect(history[3].state, isA<IdleCommand<String>>());

      // Verify toString()
      final historyString = history.map((e) => e.toString()).toList();
      expect(historyString[3], contains('IdleCommand'));
    });

    test('Command1 handles arguments correctly', () async {
      AsyncResult<String> action(String value) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return Success(value.toUpperCase());
      }

      final command = Command1<String, String>(action);
      final states = <CommandState<String>>[];

      command.addListener(() {
        states.add(command.state);
      });

      await command.execute('input');
      expect(command.state, isA<SuccessCommand<String>>());
      expect((command.state as SuccessCommand<String>).data, 'INPUT');

      // Verify history
      final history = command.stateHistory;
      expect(history.length, 3);
      expect(history[0].state, isA<IdleCommand<String>>());
      expect(history[1].state, isA<RunningCommand<String>>());
      expect(history[2].state, isA<SuccessCommand<String>>());

      // Verify toString()
      final historyString = history.map((e) => e.toString()).toList();
      expect(historyString[2], contains('SuccessCommand'));
    });

    test('Command2 executes successfully with two arguments', () async {
      AsyncResult<String> action(String value1, int value2) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return Success('$value1 $value2');
      }

      final command = Command2<String, String, int>(action);
      final states = <CommandState<String>>[];

      command.addListener(() {
        states.add(command.state);
      });

      await command.execute('Value', 42);
      expect(command.state, isA<SuccessCommand<String>>());
      expect((command.state as SuccessCommand<String>).data, 'Value 42');

      // Verify history
      final history = command.stateHistory;
      expect(history.length, 3);
      expect(history[0].state, isA<IdleCommand<String>>());
      expect(history[1].state, isA<RunningCommand<String>>());
      expect(history[2].state, isA<SuccessCommand<String>>());

      // Verify toString()
      final historyString = history.map((e) => e.toString()).toList();
      expect(historyString[2], contains('SuccessCommand'));
    });

    test('Command does not add duplicate states to history', () async {
      final command =
          Command0<String>(() async => const Success('duplicate state'));

      command.reset();
      command.reset();

      expect(command.stateHistory.length, 1);
      expect(command.stateHistory.first.state, isA<IdleCommand<String>>());
    });

    test('Command history respects maxHistoryLength', () async {
      AsyncResult<String> action() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return const Success('success');
      }

      final command = Command0<String>(action, maxHistoryLength: 2);
      final states = <CommandState<String>>[];

      command.addListener(() {
        states.add(command.state);
      });

      await command.execute();
      command.reset();
      await command.execute();

      // Verify history respects max length
      final history = command.stateHistory;
      expect(history.length, 2);
      expect(history[0].state, isA<RunningCommand<String>>());
      expect(history[1].state, isA<SuccessCommand<String>>());

      // Verify toString()
      final historyString = history.map((e) => e.toString()).toList();
      expect(historyString[0], contains('RunningCommand'));
      expect(historyString[1], contains('SuccessCommand'));
    });

    test('CommandStateNotifier dispose is called', () {
      final notifier = Command0<String>(() async => const Success('disposed'));

      // Dispose the notifier and verify no exceptions occur
      expect(() => notifier.dispose(), returnsNormally);
    });

    test('Command isIdle returns true when state is IdleCommand', () {
      final command = Command0<String>(() async => const Success('idle'));
      expect(command.state.isIdle, isTrue);
      expect(command.state.isCancelled, isFalse);
      expect(command.state.isSuccess, isFalse);
      expect(command.state.isFailure, isFalse);
    });

    test('Command isCancelled returns true when state is CancelledCommand',
        () async {
      AsyncResult<String> action() async {
        await Future.delayed(const Duration(seconds: 2));
        return const Success('CancelledCommand');
      }

      final command = Command0<String>(action);

      command.execute();
      command.cancel();
      expect(command.state.isIdle, isFalse);
      expect(command.state.isCancelled, isTrue);
      expect(command.state.isSuccess, isFalse);
      expect(command.state.isFailure, isFalse);
    });

    test('Command isSuccess returns true when state is SuccessCommand',
        () async {
      final command = Command0<String>(() async => const Success('success'));

      await command.execute();
      expect(command.state.isIdle, isFalse);
      expect(command.state.isCancelled, isFalse);
      expect(command.state.isSuccess, isTrue);
      expect(command.state.isFailure, isFalse);
    });

    test('Command isFailure returns true when state is FailureCommand',
        () async {
      final command =
          Command0<String>(() async => Failure(Exception('failure')));

      await command.execute();
      expect(command.state.isIdle, isFalse);
      expect(command.state.isCancelled, isFalse);
      expect(command.state.isSuccess, isFalse);
      expect(command.state.isFailure, isTrue);
    });

    test(
        'map() handles failure state correctly, returning the exception message',
        () async {
      final command =
          Command0<String>(() async => Failure(Exception('failure')));

      await command.execute();

      final result = command.state.maybeWhen(
        success: (_) => 'none',
        failure: (exception) => exception.toString(),
        running: () => 'running',
        orElse: () => 'default value',
      );

      expect(result, 'Exception: failure');
    });

    test('map() correctly handles success state, returning the success value',
        () async {
      final command = Command0<String>(() async => const Success('some'));

      await command.execute();

      final result = command.state.maybeWhen(
        success: (value) => value,
        failure: (exception) => exception.toString(),
        running: () => 'running',
        orElse: () => 'default value',
      );

      expect(result, 'some');
    });

    test(
        'map() correctly handles success state with input parameter, returning the success value',
        () async {
      final command = Command1<String, String>(
        (String text) async => const Success('some'),
      );

      await command.execute('param');

      final result = command.state.maybeWhen(
        running: () => 'running',
        success: (value) => value,
        failure: (exception) => exception.toString(),
        orElse: () => 'default value',
      );

      expect(result, 'some');
    });

    test(
        'map() returns the default value when no state matches and orElse is provided',
        () async {
      final command = Command0<String>(() async => Failure(Exception('none')));

      await command.execute();

      final result = command.state.maybeWhen<String>(
        success: (value) => 'otherValue',
        orElse: () => 'default value',
      );

      expect(result, 'default value');
    });

    test('Global Observable', () {
      final command1 = Command0<String>(() async => const Success('success 1'));
      final command2 = Command0<String>(
          () async => const Failure(AppException('success 2')));

      final expectedValues = [
        isA<RunningCommand<String>>(),
        isA<SuccessCommand<String>>(),
        isA<RunningCommand<String>>(),
        isA<FailureCommand<String>>(),
      ];
      var index = 0;

      Command.setObserverListener(expectAsync1(
        max: expectedValues.length,
        (value) {
          expect(value, expectedValues[index++]);
        },
      ));

      command1.execute().then((_) => command2.execute());
    });

    group('.when() method tests', () {
      setUp(() {
        // Reset the global observer to avoid interference with other tests
        Command.setObserverListener((state) {});
      });

      test('when() handles success state correctly', () async {
        final command = Command0<String>(() async => const Success('success value'));

        await command.execute();

        final result = command.state.when<String>(
          success: (value) => 'Success: $value',
          failure: (e) => 'Failure: $e',
          idle: () => 'Idle',
          running: () => 'Running',
          cancelled: () => 'Cancelled',
          orElse: () => 'Unknown',
        );

        expect(result, 'Success: success value');
      });

      test('when() handles failure state correctly', () async {
        final command = Command0<String>(() async => Failure(Exception('error')));

        await command.execute();

        final result = command.state.when<String>(
          success: (value) => 'Success: $value',
          failure: (e) => 'Failure: $e',
          idle: () => 'Idle',
          running: () => 'Running',
          cancelled: () => 'Cancelled',
          orElse: () => 'Unknown',
        );

        expect(result, 'Failure: Exception: error');
      });

      test('when() handles idle state correctly', () async {
        final command = Command0<String>(() async => const Success('success'));

        final result = command.state.when<String>(
          success: (value) => 'Success: $value',
          failure: (e) => 'Failure: $e',
          idle: () => 'Idle',
          running: () => 'Running',
          cancelled: () => 'Cancelled',
          orElse: () => 'Unknown',
        );

        expect(result, 'Idle');
      });

      test('when() handles running state correctly', () async {
        final command = Command0<String>(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          return const Success('success');
        });

        final executeFuture = command.execute();

        // Check state during execution
        await Future.delayed(const Duration(milliseconds: 10));

        final result = command.state.when<String>(
          success: (value) => 'Success: $value',
          failure: (e) => 'Failure: $e',
          idle: () => 'Idle',
          running: () => 'Running',
          cancelled: () => 'Cancelled',
          orElse: () => 'Unknown',
        );

        expect(result, 'Running');

        await executeFuture;
      });

      test('when() handles cancelled state correctly', () async {
        final command = Command0<String>(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          return const Success('success');
        });

        final executeFuture = command.execute();
        await Future.delayed(const Duration(milliseconds: 10));
        command.cancel();

        await executeFuture;

        final result = command.state.when<String>(
          success: (value) => 'Success: $value',
          failure: (e) => 'Failure: $e',
          idle: () => 'Idle',
          running: () => 'Running',
          cancelled: () => 'Cancelled',
          orElse: () => 'Unknown',
        );

        expect(result, 'Cancelled');
      });

      test('when() calls orElse when success handler is not provided', () async {
        final command = Command0<String>(() async => const Success('success'));

        await command.execute();

        final result = command.state.when<String>(
          failure: (e) => 'Failure: $e',
          idle: () => 'Idle',
          running: () => 'Running',
          cancelled: () => 'Cancelled',
          orElse: () => 'Default from orElse',
        );

        expect(result, 'Default from orElse');
      });

      test('when() calls orElse when failure handler is not provided', () async {
        final command = Command0<String>(() async => Failure(Exception('error')));

        await command.execute();

        final result = command.state.when<String>(
          success: (value) => 'Success: $value',
          idle: () => 'Idle',
          running: () => 'Running',
          cancelled: () => 'Cancelled',
          orElse: () => 'Default from orElse',
        );

        expect(result, 'Default from orElse');
      });

      test('when() calls orElse when idle handler is not provided', () async {
        final command = Command0<String>(() async => const Success('success'));

        final result = command.state.when<String>(
          success: (value) => 'Success: $value',
          failure: (e) => 'Failure: $e',
          running: () => 'Running',
          cancelled: () => 'Cancelled',
          orElse: () => 'Default from orElse',
        );

        expect(result, 'Default from orElse');
      });

      test('when() calls orElse when running handler is not provided', () async {
        final command = Command0<String>(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          return const Success('success');
        });

        final executeFuture = command.execute();
        await Future.delayed(const Duration(milliseconds: 10));

        final result = command.state.when<String>(
          success: (value) => 'Success: $value',
          failure: (e) => 'Failure: $e',
          idle: () => 'Idle',
          cancelled: () => 'Cancelled',
          orElse: () => 'Default from orElse',
        );

        expect(result, 'Default from orElse');

        await executeFuture;
      });

      test('when() calls orElse when cancelled handler is not provided', () async {
        final command = Command0<String>(() async {
          await Future.delayed(const Duration(milliseconds: 100));
          return const Success('success');
        });

        final executeFuture = command.execute();
        await Future.delayed(const Duration(milliseconds: 10));
        command.cancel();

        await executeFuture;

        final result = command.state.when<String>(
          success: (value) => 'Success: $value',
          failure: (e) => 'Failure: $e',
          idle: () => 'Idle',
          running: () => 'Running',
          orElse: () => 'Default from orElse',
        );

        expect(result, 'Default from orElse');
      });

      test('when() returns non-nullable value', () async {
        final command = Command0<String>(() async => const Success('success'));

        await command.execute();

        // This should compile without ! operator
        final String result = command.state.when<String>(
          success: (value) => 'Success: $value',
          failure: (e) => 'Failure: $e',
          idle: () => 'Idle',
          running: () => 'Running',
          cancelled: () => 'Cancelled',
          orElse: () => 'Default',
        );

        expect(result, isA<String>());
        expect(result, 'Success: success');
      });

      test('when() works with different return types (Widget example)', () async {
        final command = Command0<String>(() async => const Success('data'));

        await command.execute();

        final result = command.state.when<int>(
          success: (value) => value.length,
          failure: (e) => 0,
          idle: () => -1,
          running: () => -2,
          cancelled: () => -3,
          orElse: () => -4,
        );

        expect(result, 4); // 'data'.length = 4
      });

      test('when() with only orElse always returns orElse value', () async {
        final command = Command0<String>(() async => const Success('success'));

        await command.execute();

        final result = command.state.when<String>(
          orElse: () => 'Only orElse',
        );

        expect(result, 'Only orElse');
      });

      test('when() with Command1 handles success with value', () async {
        final command = Command1<String, int>(
          (int value) async => Success('Number: $value'),
        );

        await command.execute(42);

        final result = command.state.when<String>(
          success: (value) => 'Got: $value',
          failure: (e) => 'Error: $e',
          idle: () => 'Idle',
          running: () => 'Running',
          cancelled: () => 'Cancelled',
          orElse: () => 'Default',
        );

        expect(result, 'Got: Number: 42');
      });

      test('when() with Command2 handles success with multiple parameters', () async {
        final command = Command2<String, int, String>(
          (int a, String b) async => Success('$a-$b'),
        );

        await command.execute(10, 'test');

        final result = command.state.when<String>(
          success: (value) => 'Result: $value',
          failure: (e) => 'Error: $e',
          idle: () => 'Idle',
          running: () => 'Running',
          cancelled: () => 'Cancelled',
          orElse: () => 'Default',
        );

        expect(result, 'Result: 10-test');
      });
    });
  });

  group('Command addWhenListener tests', () {
    setUp(() {
      // Reset the global observer to avoid interference with other tests
      Command.setObserverListener((state) {});
    });

    test('addWhenListener executes immediately with current state', () {
      final command = Command0<String>(() async => const Success('test'));
      var idleCalled = false;

      command.addWhenListener(onIdle: () => idleCalled = true);

      expect(idleCalled, isTrue);
    });

    test('addWhenListener calls onSuccess when command succeeds', () async {
      final command = Command0<String>(() async => const Success('test value'));
      var successCalled = false;
      String? receivedValue;

      command.addWhenListener(
        onSuccess: (value) {
          successCalled = true;
          receivedValue = value;
        },
      );

      await command.execute();

      expect(successCalled, isTrue);
      expect(receivedValue, equals('test value'));
    });

    test('addWhenListener calls onFailure when command fails', () async {
      final testException = Exception('test error');
      final command = Command0<String>(() async => Failure(testException));
      var failureCalled = false;
      Exception? receivedException;

      command.addWhenListener(
        onFailure: (exception) {
          failureCalled = true;
          receivedException = exception;
        },
      );

      await command.execute();

      expect(failureCalled, isTrue);
      expect(receivedException, equals(testException));
    });

    test('addWhenListener calls onRunning during command execution', () async {
      final command = Command0<String>(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return const Success('test');
      });
      var runningSeen = false;

      command.addWhenListener(onRunning: () => runningSeen = true);

      await command.execute();

      expect(runningSeen, isTrue);
    });

    test('addWhenListener calls onCancelled when command is cancelled', () async {
      final command = Command0<String>(() async {
        await Future.delayed(const Duration(seconds: 2));
        return const Success('test');
      });
      var cancelledCalled = false;

      command.addWhenListener(onCancelled: () => cancelledCalled = true);

      command.execute();
      command.cancel();

      expect(cancelledCalled, isTrue);
    });

    test('addWhenListener calls orElse as fallback', () async {
      final command = Command0<String>(() async => const Success('test'));
      var elseCalled = false;

      command.addWhenListener(
        onFailure: (error) => {},
        orElse: () => elseCalled = true,
      );

      await command.execute();

      expect(elseCalled, isTrue);
    });

    test('addWhenListener removes listener correctly', () async {
      final command = Command0<String>(() async => const Success('test'));
      var callCount = 0;

      final removeListener = command.addWhenListener(
        onSuccess: (value) => callCount++,
      );

      await command.execute();
      expect(callCount, equals(1));

      removeListener();
      command.reset();
      await command.execute();

      expect(callCount, equals(1)); // Should still be 1 because listener was removed
    });

    test('addWhenListener supports multiple independent listeners', () async {
      final command = Command0<String>(() async => const Success('test'));
      var listener1Called = false;
      var listener2Called = false;

      command.addWhenListener(onSuccess: (value) => listener1Called = true);
      final removeListener2 = command.addWhenListener(onSuccess: (value) => listener2Called = true);

      await command.execute();

      expect(listener1Called, isTrue);
      expect(listener2Called, isTrue);

      // Reset and remove one listener
      command.reset();
      removeListener2();
      listener1Called = false;
      listener2Called = false;

      await command.execute();

      expect(listener1Called, isTrue);
      expect(listener2Called, isFalse);
    });

    test('addWhenListener works with Command1', () async {
      final command = Command1<String, int>((value) async => Success('Result: $value'));
      var successCalled = false;
      String? receivedValue;

      command.addWhenListener(
        onSuccess: (value) {
          successCalled = true;
          receivedValue = value;
        },
      );

      await command.execute(42);

      expect(successCalled, isTrue);
      expect(receivedValue, equals('Result: 42'));
    });

    test('addWhenListener handles listener exceptions gracefully', () async {
      final command = Command0<String>(() async => const Success('test'));
      var commandCompleted = false;

      command.addWhenListener(
        onSuccess: (value) => throw Exception('Listener error'),
      );

      // Command should complete normally despite listener exception
      await command.execute();
      commandCompleted = true;

      expect(commandCompleted, isTrue);
      expect(command.state, isA<SuccessCommand<String>>());
    });
  });

  group('ifState methods', () {
    test('ifIdle executes action when state is IdleCommand', () {
      final command = Command0<String>(() async => const Success('test'));
      var idleCalled = false;

      command.state.ifIdle(() => idleCalled = true);

      expect(idleCalled, isTrue);
    });

    test('ifIdle does not execute action when state is not IdleCommand',
        () async {
      final command = Command0<String>(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return const Success('test');
      });
      var idleCalled = false;

      await command.execute();
      command.state.ifIdle(() => idleCalled = true);

      expect(idleCalled, isFalse);
    });

    test('ifRunning executes action when state is RunningCommand', () async {
      final command = Command0<String>(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return const Success('test');
      });
      var runningCalled = false;

      command.addListener(() {
        command.state.ifRunning(() => runningCalled = true);
      });

      await command.execute();

      expect(runningCalled, isTrue);
    });

    test('ifRunning does not execute action when state is not RunningCommand',
        () {
      final command = Command0<String>(() async => const Success('test'));
      var runningCalled = false;

      command.state.ifRunning(() => runningCalled = true);

      expect(runningCalled, isFalse);
    });

    test('ifSuccess executes action with data when state is SuccessCommand',
        () async {
      final command = Command0<String>(() async => const Success('success'));
      String? receivedData;

      await command.execute();
      command.state.ifSuccess((data) => receivedData = data);

      expect(receivedData, 'success');
    });

    test(
        'ifSuccess does not execute action when state is not SuccessCommand',
        () {
      final command = Command0<String>(() async => const Success('test'));
      String? receivedData;

      command.state.ifSuccess((data) => receivedData = data);

      expect(receivedData, isNull);
    });

    test('ifFailure executes action with error when state is FailureCommand',
        () async {
      final command = Command0<String>(
          () async => Failure(Exception('test error')));
      Exception? receivedError;

      await command.execute();
      command.state.ifFailure((error) => receivedError = error);

      expect(receivedError, isA<Exception>());
      expect(receivedError.toString(), contains('test error'));
    });

    test(
        'ifFailure does not execute action when state is not FailureCommand',
        () async {
      final command = Command0<String>(() async => const Success('test'));
      Exception? receivedError;

      await command.execute();
      command.state.ifFailure((error) => receivedError = error);

      expect(receivedError, isNull);
    });

    test('ifCancelled executes action when state is CancelledCommand',
        () async {
      final command = Command0<String>(() async {
        await Future.delayed(const Duration(seconds: 1));
        return const Success('test');
      });
      var cancelledCalled = false;

      Future.delayed(
          const Duration(milliseconds: 50), () => command.cancel());

      await command.execute();
      command.state.ifCancelled(() => cancelledCalled = true);

      expect(cancelledCalled, isTrue);
    });

    test(
        'ifCancelled does not execute action when state is not CancelledCommand',
        () async {
      final command = Command0<String>(() async => const Success('test'));
      var cancelledCalled = false;

      await command.execute();
      command.state.ifCancelled(() => cancelledCalled = true);

      expect(cancelledCalled, isFalse);
    });

    test('multiple ifState methods can be chained', () async {
      final command = Command0<String>(() async => const Success('data'));
      var successCalled = false;
      var failureCalled = false;

      await command.execute();

      command.state
        ..ifSuccess((data) => successCalled = true)
        ..ifFailure((error) => failureCalled = true);

      expect(successCalled, isTrue);
      expect(failureCalled, isFalse);
    });

    test('ifState methods work with Command1', () async {
      final command =
          Command1<int, int>((value) async => Success(value * 2));
      int? receivedData;

      await command.execute(5);
      command.state.ifSuccess((data) => receivedData = data);

      expect(receivedData, 10);
    });

    test('ifState methods work with Command2', () async {
      final command = Command2<String, String, int>(
          (a, b) async => Success('$a: $b'));
      String? receivedData;

      await command.execute('Count', 42);
      command.state.ifSuccess((data) => receivedData = data);

      expect(receivedData, 'Count: 42');
    });
  });
}

class AppException implements Exception {
  final String message;

  const AppException(this.message);
}
