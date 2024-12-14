part of 'command.dart';

/// Represents a command history entry with timestamp and metadata.
class CommandHistoryEntry<T extends Object> {
  /// The state of the command at this point in time.
  final CommandState<T> state;

  /// The timestamp when the state change occurred.
  final DateTime timestamp;

  /// Optional additional metadata about the state change.
  final Map<String, dynamic>? metadata;

  CommandHistoryEntry({
    required this.state,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'CommandHistoryEntry(state: $state, timestamp: $timestamp, metadata: $metadata)';
  }
}

/// Manages the history of command states.
mixin CommandHistoryManager<T extends Object> {
  /// The maximum length of the state history.
  late int maxHistoryLength;

  /// A list to maintain the history of state changes.
  final List<CommandHistoryEntry<T>> _stateHistory = [];

  /// Initializes the history manager with a maximum length.
  void initializeHistoryManager(int maxHistoryLength) {
    this.maxHistoryLength = maxHistoryLength;
  }

  /// Provides read-only access to the state change history.
  List<CommandHistoryEntry<T>> get stateHistory => List.unmodifiable(_stateHistory);

  /// Adds a new entry to the history and ensures the history length limit.
  void addHistoryEntry(CommandHistoryEntry<T> entry) {
    _stateHistory.add(entry);
    if (_stateHistory.length > maxHistoryLength) {
      _stateHistory.removeAt(0);
    }
  }
}
