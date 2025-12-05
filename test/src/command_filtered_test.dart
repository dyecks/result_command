import 'package:flutter_test/flutter_test.dart';

import 'package:result_dart/result_dart.dart';

import 'package:result_command/src/command.dart';

void main() {
  test(
    'Filter Ok',
    () async {
      final command = Command1<int, int>((int value) async {
        await Future.delayed(const Duration(milliseconds: 100));

        if (value < 0) {
          return Failure(Exception('Negative value'));
        }

        return Success(value);
      });

      final fiteredSuccess = command.filter(
        0,
        (value) => value is SuccessCommand<int> ? value.data : null,
      );

      fiteredSuccess.addListener(expectAsync0(() {
        expect(fiteredSuccess.value, 2);
      }));
      await command.execute(-1);
      await command.execute(-2);
      await command.execute(2);
    },
  );
}
