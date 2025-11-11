import 'package:hive/hive.dart';

enum TaskStatus {
  // Use unique integers for typeId mapping
  @HiveField(0)
  pending,
  @HiveField(1)
  running,
  @HiveField(2)
  completed,
  @HiveField(3)
  paused,
}

// Manual TypeAdapter registration for TaskStatus
class TaskStatusAdapter extends TypeAdapter<TaskStatus> {
  @override
  final int typeId = 1; // Unique ID for TaskStatus

  @override
  TaskStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskStatus.pending;
      case 1:
        return TaskStatus.running;
      case 2:
        return TaskStatus.completed;
      case 3:
        return TaskStatus.paused;
      default:
        throw ArgumentError('Unknown TaskStatus ID');
    }
  }

  @override
  void write(BinaryWriter writer, TaskStatus obj) {
    switch (obj) {
      case TaskStatus.pending:
        writer.writeByte(0);
        break;
      case TaskStatus.running:
        writer.writeByte(1);
        break;
      case TaskStatus.completed:
        writer.writeByte(2);
        break;
      case TaskStatus.paused:
        writer.writeByte(3);
        break;
    }
  }
}

class Task {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final TaskStatus status;
  @HiveField(3)
  final int index;
  @HiveField(4)
  final int durationSeconds;

  Task({
    required this.id,
    required this.title,
    required this.status,
    required this.index,
    this.durationSeconds = 3,
  });

  Task copyWith({
    String? title,
    TaskStatus? status,
    int? index,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      status: status ?? this.status,
      index: index ?? this.index,
      durationSeconds: durationSeconds,
    );
  }

  // Helper for Isolate communication (serialization)
  // Hive objects cannot be sent across isolates, so we use Map conversion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'status': status.name,
      'index': index,
      'durationSeconds': durationSeconds,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      status: TaskStatus.values.byName(map['status'] as String),
      index: map['index'] as int,
      durationSeconds: map['durationSeconds'] as int,
    );
  }
}
