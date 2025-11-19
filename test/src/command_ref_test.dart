import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_command/src/command.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  test('Command Ref', () {
    final listenable = ValueNotifier<int>(0);

    final commandRef = CommandRef<int, int>(
      (ref) => ref(listenable),
      (value) async => Success(value * 2),
    );

    commandRef.addListener(expectAsync0(() {
      final status = commandRef.state;
      if (status is SuccessCommand<int>) {
        expect(status.value, 10);
      }
    }, count: 2));

    listenable.value = 5;
  });
}
