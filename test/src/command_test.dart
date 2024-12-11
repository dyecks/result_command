import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_command/src/command.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  test('command ...', () async {
    AsyncResult<String> action() async {
      await Future.delayed(const Duration(seconds: 2));
      return const Success('success');
    }

    final command = Command0<String>(action);
    expect(
        command.toStream(),
        emitsInOrder([
          isA<IdleCommand>(),
          isA<RuningCommand>(),
          isA<SuccessCommand>(),
        ]));

    command.execute();
  });
  test('command1 ...', () async {
    AsyncResult<String> action(String value) async {
      await Future.delayed(const Duration(seconds: 2));
      return Success(value);
    }

    final command = Command1<String, String>(action);
    expect(
        command.toStream(),
        emitsInOrder([
          isA<IdleCommand>(),
          isA<RuningCommand>(),
          isA<SuccessCommand>(),
        ]));

    command.execute('Test');
  });
}

// convert ValueListenable in Stream extension

extension ValueListenableStream<T> on ValueListenable<T> {
  Stream<T> toStream() {
    late final StreamController<T> controller;
    void listener() {
      controller.add(value);
    }

    controller = StreamController<T>.broadcast(
      onListen: () {
        controller.add(value);
        addListener(listener);
      },
      onCancel: () {
        removeListener(listener);
        controller.close();
      },
    );

    return controller.stream;
  }
}
