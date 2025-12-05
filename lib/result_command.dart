///# Result Command
///
///**Result Command** is a lightweight package that brings the **Command Pattern** to Flutter, allowing you to encapsulate actions, track their execution state, and manage results with clarity. Perfect for simplifying complex workflows, ensuring robust error handling, and keeping your UI reactive.
///
///---
///
///## Why Use Result Command?
///
///1. **Encapsulation**: Wrap your business logic into reusable commands.
///2. **State Tracking**: Automatically manage states like `Idle`, `Running`, `Success`, `Failure`, and `Cancelled`.
///3. **Error Handling**: Centralize how you handle successes and failures using the intuitive `Result` API.
///4. **State History**: Track state transitions with optional metadata.
///5. **Timeout Support**: Specify execution time limits for commands.
///6. **Cancellation Support**: Cancel long-running tasks when needed.
///7. **UI Integration**: React to command state changes directly in your Flutter widgets.
///
///---
///
///## How It Works
///
///At its core, **Result Command** lets you define reusable actions (commands) that manage their lifecycle. Each command:
///
///- **Executes an action** (e.g., API call, user input validation).
///- **Tracks its state** (`Idle`, `Running`, etc.).
///- **Notifies listeners** when the state changes.
///- **Maintains a history** of states and transitions.
///- **Returns a result** (`Success` or `Failure`) using the `Result` API.
///
///---
///
///## Command State (`CommandState`)
///
///Each `Command` exposes its current state through a `CommandState`. The state represents one of the following:
///
///- **`IdleCommand`**: The command is ready to execute.
///- **`RunningCommand`**: The command is currently executing an action.
///- **`SuccessCommand`**: The action completed successfully.
///- **`FailureCommand`**: The action failed with an error.
///- **`CancelledCommand`**: The action was explicitly stopped.
///
///### Accessing the State
///You can access the current state using the `state` property of the command:
///```dart
///final command = Command0<String>(() async {
///  return Success('Hello, World!');
///});
///
///// The current state of the command.
///print(command.state); // Outputs: SuccessCommand<String>
///```
///
///### Reacting to State Changes
///The state updates automatically as the command executes:
///- Use `addListener` for manual handling.
///- Use `ValueListenableBuilder` to bind the state to your UI.
///
///## State History (`CommandHistory`)
///
///Each command tracks a configurable history of its states, useful for debugging, auditing, and behavioral analysis.
///
///### Configuring the History
///
///Set the maximum length of the history when creating a command:
///
///```dart
///final command = Command0<String>(
///  () async => const Success('Done'),
///  maxHistoryLength: 5,
///);
///```
///
///### Accessing the History
///
///Access the history with `stateHistory`:
///
///```dart
///final history = command.stateHistory;
///history.forEach(print);
///```
///
///---
///
///## Getters for State Checks
///
///To simplify state management and improve code readability, the following getters are available:
///
///- **`isIdle`**: Checks if the command is in the idle state.
///  ```dart
///  bool get isIdle => value is IdleCommand<T>;
///  ```
///
///- **`isRunning`**: Checks if the command is currently running.
///  ```dart
///  bool get isRunning => value is RunningCommand<T>;
///  ```
///
///- **`isCancelled`**: Checks if the command has been cancelled.
///  ```dart
///  bool get isCancelled => value is CancelledCommand<T>;
///  ```
///
///- **`isSuccess`**: Checks if the command execution was successful.
///  ```dart
///  bool get isSuccess => value is SuccessCommand<T>;
///  ```
///
///- **`isFailure`**: Checks if the command execution failed.
///  ```dart
///  bool get isFailure => value is FailureCommand<T>;
///  ```
///
///These getters allow you to write cleaner and more intuitive code when interacting with commands in your views or controllers.
library result_command;

export 'src/command.dart';
