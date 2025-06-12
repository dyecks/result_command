part of 'command.dart';

/// Represents a command that listens to changes in one or more ValueListenables and executes an action.
///
/// The `CommandRef` class allows you to define a reference function (`ref`) that derives values from
/// `ValueListenables`. These values are then passed to the action for execution whenever the `ValueListenables` change.
///
/// - [CommandRefAction0]: A function that derives values from `ValueListenables`.
/// - [CommandAction1]: The action to be executed based on the derived values.
///
/// Example:
/// ```dart
/// final listenable = ValueNotifier<int>(0);
///
/// final commandRef = CommandRef<int, int>(
///   (ref) => ref(listenable),
///   (value) async => Success(value * 2),
/// );
///
/// commandRef.addListener(() {
///   final status = commandRef.value;
///   if (status is SuccessCommand<int>) {
///     print('Result: ${status.value}');
///   }
/// });
///
/// listenable.value = 5; // Executes the command with the value 5.
/// ```
///
/// Features:
/// - Automatically listens to changes in `ValueListenables`.
/// - Executes the action whenever the derived value changes.
/// - Cleans up listeners when disposed.
final class CommandRef<T extends Object, W> extends Command<T> {
  /// The reference function that derives values from ValueListenables.
  final CommandRefAction0<W> _refAction;

  /// The action to be executed based on the derived values.
  final CommandAction1<T, W> _action;

  /// A set of ValueListenables being observed.
  final Set<ValueListenable> _listenables = {};

  /// Derives a value from a ValueListenable and adds it to the set of observed listenables.
  V _ref<V>(ValueListenable<V> listenable) {
    if (!_listenables.contains(listenable)) {
      _listenables.add(listenable);
      listenable.addListener(_innerExecute);
    }
    return listenable.value;
  }

  /// Creates a CommandRef with the specified reference function and action.
  CommandRef(this._refAction, this._action) {
    _refAction(_ref);
  }

  /// Executes the action based on the derived values.
  Future<void> _innerExecute() {
    return _execute(() => _action(_refAction(_ref)));
  }

  /// Disposes the CommandRef and cleans up listeners.
  @override
  void dispose() {
    for (final listenable in _listenables) {
      listenable.removeListener(_innerExecute);
    }
    _listenables.clear();
    super.dispose();
  }
}
