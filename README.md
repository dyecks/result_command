# Result Command

**Result Command** is a lightweight package that implements the **Command Pattern** in Flutter, enabling encapsulation of actions, state tracking, and result management.

---

## Installation

Add the package to your `pubspec.yaml`:
```yaml
dependencies:
  result_command: x.x.x
  result_dart: 2.x.x
```

---

## How to Use

### 1. Creating a Command
Commands encapsulate actions and manage their lifecycle. Depending on the number of parameters your action requires, you can use:
- **Command0**: For actions with no parameters.
- **Command1**: For actions with one parameter.
- **Command2**: For actions with two parameters.

Example:
```dart
final fetchGreetingCommand = Command0<String>(
  () async {
    await Future.delayed(Duration(seconds: 2));
    return Success('Hello, World!');
  },
);

final calculateSquareCommand = Command1<int, int>(
  (number) async {
    if (number < 0) {
      return Failure(Exception('Negative numbers are not allowed.'));
    }
    return Success(number * number);
  },
);
```

---

### 2. Listening to a Command
Commands are `Listenable`, meaning you can react to their state changes:

#### Using `addListener`
```dart
fetchGreetingCommand.addListener(() {
  final state = fetchGreetingCommand.state;
  if (state is SuccessCommand<String>) {
    print('Success: ${state.value}');
  } else if (state is FailureCommand<String>) {
    print('Failure: ${state.error}');
  }
});
```

#### Using `ValueListenableBuilder`
```dart
Widget build(BuildContext context) {
  return ListenableBuilder(
    listenable: fetchGreetingCommand,
    builder: (context, _) {
      return switch (state) {
        RunningCommand<String>() => CircularProgressIndicator(),
        SuccessCommand<String>(:final value) => Text('Success: $value'),
        FailureCommand<String>(:final error) => Text('Failure: $error'),
        _ => ElevatedButton(
          onPressed: () => fetchGreetingCommand.execute(),
          child: Text('Fetch Greeting'),
        ),
      };
    },
  );
}
```

#### Using `when` for Simplified State Handling
The `when` method simplifies state management by mapping each state to a specific action or value:
```dart
fetchGreetingCommand.addListener(() {
  final message = fetchGreetingCommand.state.when(
    success: (value) => 'Success: $value',
    failure: (exception) => 'Error: ${exception?.message}',
    idle: () => 'Idle',
    running: () => 'Running...',
    cancelled: () => 'Cancelled',
    orElse: () => 'Not provided state',
  );

  print(message);
});
```
This approach ensures type safety and provides a clean way to handle all possible states of a command.

---

### 3. Executing a Command
The `execute()` method triggers the action encapsulated by the command. During execution, the command transitions through the following states:

1. **Idle**: The initial state, indicating the command is ready to execute.
2. **Running**: The state while the action is being executed.
3. **Success**: The state when the action completes successfully.
4. **Failure**: The state when the action fails.
5. **Cancelled**: The state when the action is cancelled.

Each command can only be executed one at a time. If another call to `execute()` is made while the command is already running, it will be ignored until the current execution finishes or is cancelled.

Example:
```dart
fetchGreetingCommand.execute();
```

---

### 4. Cancelling a Command
Commands can be cancelled if they are in the `Running` state. When cancelled, the command transitions to the `Cancelled` state and invokes the optional `onCancel` callback.

Example:
```dart
final uploadCommand = Command0<void>(
  () async {
    await Future.delayed(Duration(seconds: 5));
  },
  onCancel: () {
    print('Upload cancelled');
  },
);

uploadCommand.execute();

Future.delayed(Duration(seconds: 2), () {
  uploadCommand.cancel();
});
```

---

### 5. Facilitators

To simplify interaction with commands, several helper methods and getters are available:

#### State Check Getters
These getters allow you to easily check the current state of a command:
```dart
  if (command.state.isRunning) {
    print('Command is idle and ready to execute.');
  }
```

#### Cached Values
To avoid flickering or unnecessary updates in the UI, commands cache their last success and failure states:
- **`getCachedSuccess()`**: Retrieves the cached value of the last successful execution, or `null` if no success is cached.
  ```dart
  final successValue = command.getCachedSuccess();
  if (successValue != null) {
    print('Last successful value: $successValue');
  }
  ```
- **`getCachedFailure()`**: Retrieves the cached exception of the last failed execution, or `null` if no failure is cached.
  ```dart
  final failureException = command.getCachedFailure();
  if (failureException != null) {
    print('Last failure exception: $failureException');
  }
  ```

These facilitators improve code readability and make it easier to manage command states and results efficiently.

---

### 6. Filtering Command State

The `filter` method allows you to derive a new value from the command's state using a transformation function. This is useful for creating filtered or transformed views of the command's state.

#### Example:
```dart
final filteredValue = command.filter<String>(
  'Default Value',
  (state) {
    if (state is SuccessCommand<String>) {
      return 'Success: ${state.value}';
    } else if (state is FailureCommand<String>) {
      return 'Error: ${state.error}';
    }
    return null; // Ignore other states.
  },
);

filteredValue.addListener(() {
  print('Filtered Value: ${filteredValue.value}');
});
```

This method simplifies state management by allowing you to focus on specific aspects of the command's state.

---

### 7. CommandRef

The `CommandRef` class allows you to create commands that listen to changes in one or more `ValueListenables` and execute actions based on derived values.

#### Example:
```dart
final listenable = ValueNotifier<int>(0);

final commandRef = CommandRef<int, int>(
  (ref) => ref(listenable),
  (value) async => Success(value * 2),
);

commandRef.addListener(() {
  final status = commandRef.value;
  if (status is SuccessCommand<int>) {
    print('Result: ${status.value}');
  }
});

listenable.value = 5; // Executes the command with the value 5.
```

#### Features:
- Automatically listens to changes in `ValueListenables`.
- Executes the action whenever the derived value changes.
- Cleans up listeners when disposed.

This class is ideal for scenarios where commands need to react dynamically to external state changes.


## Documentation

For advanced examples and detailed documentation, visit:
- [Examples](example/)
- [GitHub Wiki](https://github.com/seu-repo/result_command/wiki)

---

## Contribute

We welcome contributions! Feel free to report issues, suggest features, or submit pull requests.