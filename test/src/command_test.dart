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

    command.addListener(() {
      print(command.value);
    });

    command.execute();

    await Future.delayed(const Duration(seconds: 5));
  });
}
