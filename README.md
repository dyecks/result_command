# Result Command

**Result Command** is a lightweight package that brings the **Command Pattern** to Flutter, allowing you to encapsulate actions, track their execution state, and manage results with clarity. Perfect for simplifying complex workflows, ensuring robust error handling, and keeping your UI reactive.

---

## Why Use Result Command?

1. **Encapsulation**: Wrap your business logic into reusable commands.
2. **State Tracking**: Automatically manage states like `Idle`, `Running`, `Success`, `Failure`, and `Cancelled`.
3. **Error Handling**: Centralize how you handle successes and failures using the intuitive `Result` API.
4. **State History**: Track state transitions with optional metadata.
5. **Timeout Support**: Specify execution time limits for commands.
6. **Cancellation Support**: Cancel long-running tasks when needed.
7. **UI Integration**: React to command state changes directly in your Flutter widgets.

---

## How It Works

At its core, **Result Command** lets you define reusable actions (commands) that manage their lifecycle. Each command:

- **Executes an action** (e.g., API call, user input validation).
- **Tracks its state** (`Idle`, `Running`, etc.).
- **Notifies listeners** when the state changes.
- **Maintains a history** of states and transitions.
- **Returns a result** (`Success` or `Failure`) using the `Result` API.

---

## Command State (`CommandState`)

Each `Command` exposes its current state through a `CommandState`. The state represents one of the following:

- **`IdleCommand`**: The command is ready to execute.
- **`RunningCommand`**: The command is currently executing an action.
- **`SuccessCommand`**: The action completed successfully.
- **`FailureCommand`**: The action failed with an error.
- **`CancelledCommand`**: The action was explicitly stopped.

### Accessing the State
You can access the current state using the `value` property of the command:
```dart
final command = Command0<String>(() async {
  return Success('Hello, World!');
});

// The current state of the command.
print(command.value); // Outputs: SuccessCommand<String>
```

### Reacting to State Changes
The state updates automatically as the command executes:
- Use `addListener` for manual handling.
- Use `ValueListenableBuilder` to bind the state to your UI.

## State History (`CommandHistory`)

Each command tracks a configurable history of its states, useful for debugging, auditing, and behavioral analysis.

### Configuring the History

Set the maximum length of the history when creating a command:

```dart
final command = Command0<String>(
  () async => const Success('Done'),
  maxHistoryLength: 5,
);
```

### Accessing the History

Access the history with `stateHistory`:

```dart
final history = command.stateHistory;
history.forEach(print);
```

---

## Examples

### Example 1: Simple Command with No Arguments

Encapsulate a simple action into a reusable `Command`:
```dart
final fetchGreetingCommand = Command0<String>(
  () async {
    await Future.delayed(Duration(seconds: 2));
    return Success('Hello, World!');
  },
);

fetchGreetingCommand.addListener(() {
  if (fetchGreetingCommand.value is SuccessCommand<String>) {
    final result = (fetchGreetingCommand.value as SuccessCommand<String>).value;
    print('Success: $result');
  } else if (fetchGreetingCommand.value is FailureCommand<String>) {
    final error = (fetchGreetingCommand.value as FailureCommand<String>).error;
    print('Failure: $error');
  }
});

// Execute the command
fetchGreetingCommand.execute();
```

---

### Example 2: Simple Command with Timeout

Commands now support a timeout for execution:

```dart
final fetchGreetingCommand = Command0<String>(
  () async {
    await Future.delayed(Duration(seconds: 5)); // Simulating a delay.
    return Success('Hello, World!');
  },
);

fetchGreetingCommand.execute(timeout: Duration(seconds: 2)).catchError((error) {
  print('Error: $error'); // "Error: Command timed out"
});
```

---

### Example 3: Command with Arguments

Pass input to your command's action:
```dart
final calculateSquareCommand = Command1<int, int>(
  (number) async {
    if (number < 0) {
      return Failure(Exception('Negative numbers are not allowed.'));
    }
    return Success(number * number);
  },
);

calculateSquareCommand.addListener(() {
  if (calculateSquareCommand.value is SuccessCommand<int>) {
    final result = (calculateSquareCommand.value as SuccessCommand<int>).value;
    print('Square: $result');
  } else if (calculateSquareCommand.value is FailureCommand<int>) {
    final error = (calculateSquareCommand.value as FailureCommand<int>).error;
    print('Error: $error');
  }
});

// Execute the command with input
calculateSquareCommand.execute(4);
```

---

### Example 4: Binding State to the UI

Use `ValueListenableBuilder` to update the UI automatically:
```dart
final loginCommand = Command2<bool, String, String>(
  (username, password) async {
    if (username == 'admin' && password == 'password') {
      return Success(true);
    }
    return Failure(Exception('Invalid credentials.'));
  },
);

Widget build(BuildContext context) {
  return Column(
    children: [
      ValueListenableBuilder<CommandState<bool>>(
        valueListenable: loginCommand,
        builder: (context, state, child) {
          if (state is RunningCommand<bool>) {
            return CircularProgressIndicator();
          } else if (state is SuccessCommand<bool>) {
            return Text('Login Successful!');
          } else if (state is FailureCommand<bool>) {
            return Text('Login Failed: ${(state as FailureCommand).error}');
          }
          return ElevatedButton(
            onPressed: () => loginCommand.execute('admin', 'password'),
            child: Text('Login'),
          );
        },
      ),
    ],
  );
}
```

---

### Example 5: Cancellation

Cancel long-running commands gracefully:
```dart
final uploadCommand = Command0<void>(
  () async {
    for (int i = 0; i < 10; i++) {
      await Future.delayed(Duration(seconds: 1));
      print('Uploading: ${i + 1}0%');
    }
    return Success();
  },
  onCancel: () {
    print('Upload cancelled!');
  },
);

// Start the upload
uploadCommand.execute();

// Cancel after 3 seconds
Future.delayed(Duration(seconds: 3), () {
  uploadCommand.cancel();
});
```

---

### Example 6: Using Stream

Using Stream to Monitor State Changes:
```dart

  final command = Command0<String>(
    () async {
      await Future.delayed(Duration(seconds: 2));
      return Result.success("Action completed successfully");
    },
  );

  command.stateStream.listen((state) {
    if (state is IdleCommand) {
      print("Command is idle.");
    } else if (state is RunningCommand) {
      print("Command is running.");
    } else if (state is SuccessCommand<String>) {
      print("Command succeeded with result: ${state.value}");
    } else if (state is FailureCommand<String>) {
      print("Command failed with error: ${state.error}");
    } else if (state is CancelledCommand) {
      print("Command was cancelled.");
    }
  });

  command.execute();
```

---  

## Benefits for Your Team

- **Simplified Collaboration**: Encapsulation makes it easier for teams to work independently on UI and business logic.
- **Reusability**: Commands can be reused across different widgets or flows.
- **Maintainability**: Cleaner separation of concerns reduces technical debt.

---

## Getting Started

1. Add the package to your `pubspec.yaml`:
   ```yaml
   dependencies:
     result_command: ^1.0.0
   ```

2. Wrap your actions in commands:
   - Use pre-defined `Command` types to encapsulate your logic.
   - Attach listeners to update your UI dynamically.

3. Execute commands from your UI and enjoy the benefits of encapsulated logic and state tracking.

---

## Contribute

We’d love your help in improving **Result Command**! Feel free to report issues, suggest features, or submit pull requests.

---