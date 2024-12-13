import 'package:flutter/foundation.dart';
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

      expect(
          command.stateStream,
          emitsInOrder([
            isA<RunningCommand<String>>(),
            isA<SuccessCommand<String>>(),
          ]));

      await command.execute();
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

      expect(
          command.stateStream,
          emitsInOrder([
            isA<RunningCommand<String>>(),
            isA<SuccessCommand<String>>(),
          ]));

      await command.execute('Test');
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

      expect(
          command.stateStream,
          emitsInOrder([
            isA<RunningCommand<String>>(),
            isA<FailureCommand<String>>(),
          ]));

      Future.delayed(const Duration(milliseconds: 100), () => command.cancel());

      await command.execute();
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

      expect(
          command.stateStream,
          emitsInOrder([
            isA<RunningCommand<String>>(),
            isA<FailureCommand<String>>(),
          ]));

      await command.execute();
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

      expect(
          command.stateStream,
          emitsInOrder([
            isA<RunningCommand<String>>(),
            isA<FailureCommand<String>>(),
          ]));

      await command.execute();
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

    test('Command with timeout in _execute', () async {
      AsyncResult<String> action() async {
        await Future.delayed(const Duration(seconds: 2));
        return const Success('success');
      }

      final command = Command0<String>(action);

      expect(
          command.stateStream,
          emitsInOrder([
            isA<RunningCommand<String>>(),
            isA<CancelledCommand<String>>(),
          ]));

      await command.execute(timeout: const Duration(milliseconds: 500));
      expect(command.value, isA<CancelledCommand<String>>());
    });

    test('Command resets state', () async {
      AsyncResult<String> action() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return const Success('success');
      }

      final command = Command0<String>(action);

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

    test('Command history respects maxHistoryLength', () async {
      AsyncResult<String> action() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return const Success('success');
      }

      final command = Command0<String>(action, maxHistoryLength: 2);

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
  });
}
