import 'package:flutter_test/flutter_test.dart';
import 'package:result_command/src/command.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  group('Command tests', () {
    test('Command0 executes successfully', () async {
      AsyncResult<String> action() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return const Success('success');
      }

      final command = Command0<String>(action);
      final states = <CommandState<String>>[];

      command.addListener(() {
        states.add(command.value);
      });

      await command.execute();
      expect(states, [
        isA<RunningCommand<String>>(),
        isA<SuccessCommand<String>>(),
      ]);

      expect(command.value, isA<SuccessCommand<String>>());

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
        states.add(command.value);
      });

      await command.execute('Test');
      expect(states, [
        isA<RunningCommand<String>>(),
        isA<SuccessCommand<String>>(),
      ]);

      expect(command.value, isA<SuccessCommand<String>>());
      expect((command.value as SuccessCommand<String>).value, 'Test');

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
        states.add(command.value);
      });

      Future.delayed(const Duration(milliseconds: 100), () => command.cancel());

      await command.execute();
      expect(states, [
        isA<RunningCommand<String>>(),
        isA<FailureCommand<String>>(),
      ]);

      expect(command.value, isA<FailureCommand<String>>());

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
        states.add(command.value);
      });

      await command.execute();
      expect(states, [
        isA<RunningCommand<String>>(),
        isA<FailureCommand<String>>(),
      ]);

      expect(command.value, isA<FailureCommand<String>>());
      expect((command.value as FailureCommand<String>).error.toString(),
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
        states.add(command.value);
      });

      await command.execute();
      expect(states, [
        isA<RunningCommand<String>>(),
        isA<FailureCommand<String>>(),
      ]);
      expect(command.value, isA<FailureCommand<String>>());
      expect((command.value as FailureCommand<String>).error.toString(),
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
      expect(command.value, isA<CancelledCommand<String>>());
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
      expect(command.value, isA<CancelledCommand<String>>());
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
        states.add(command.value);
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
        states.add(command.value);
      });

      await command.execute();
      expect(command.value, isA<SuccessCommand<String>>());

      command.reset();
      expect(command.value, isA<IdleCommand<String>>());

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
        states.add(command.value);
      });

      await command.execute('input');
      expect(command.value, isA<SuccessCommand<String>>());
      expect((command.value as SuccessCommand<String>).value, 'INPUT');

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
        states.add(command.value);
      });

      await command.execute('Value', 42);
      expect(command.value, isA<SuccessCommand<String>>());
      expect((command.value as SuccessCommand<String>).value, 'Value 42');

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
        states.add(command.value);
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
      expect(command.isIdle, isTrue);
      expect(command.isCancelled, isFalse);
      expect(command.isSuccess, isFalse);
      expect(command.isFailure, isFalse);
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
      expect(command.isIdle, isFalse);
      expect(command.isCancelled, isTrue);
      expect(command.isSuccess, isFalse);
      expect(command.isFailure, isFalse);
    });

    test('Command isSuccess returns true when state is SuccessCommand',
        () async {
      final command = Command0<String>(() async => const Success('success'));

      await command.execute();
      expect(command.isIdle, isFalse);
      expect(command.isCancelled, isFalse);
      expect(command.isSuccess, isTrue);
      expect(command.isFailure, isFalse);
    });

    test('Command isFailure returns true when state is FailureCommand',
        () async {
      final command =
          Command0<String>(() async => Failure(Exception('failure')));

      await command.execute();
      expect(command.isIdle, isFalse);
      expect(command.isCancelled, isFalse);
      expect(command.isSuccess, isFalse);
      expect(command.isFailure, isTrue);
    });

    test(
        'map() handles failure state correctly, returning the exception message',
        () async {
      final command =
          Command0<String>(() async => Failure(Exception('failure')));

      await command.execute();

      final result = command.value.when(
        data: (_) => 'none',
        running: () => 'running',
        failure: (exception) => exception.toString(),
        orElse: () => 'default value',
      );

      expect(result, 'Exception: failure');
    });

    test('map() correctly handles success state, returning the success value',
        () async {
      final command = Command0<String>(() async => const Success('some'));

      await command.execute();

      final result = command.value.when(
        data: (value) => value,
        running: () => 'running',
        failure: (exception) => exception.toString(),
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

      final result = command.value.when(
        data: (value) => value,
        running: () => 'running',
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

      final result = command.value.when<String>(
        data: (value) => 'otherValue',
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
  });
}

class AppException implements Exception {
  final String message;

  const AppException(this.message);
}
