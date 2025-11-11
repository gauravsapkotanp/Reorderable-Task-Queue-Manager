import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'task_model.g.dart';

enum TaskStatus {
  pending,
  running,
  paused,
  completed,
}

@HiveType(typeId: 1)
class TaskModel extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final TaskStatus status;

  @HiveField(4)
  final int order;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime? completedAt;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    this.status = TaskStatus.pending,
    required this.order,
    required this.createdAt,
    this.completedAt,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    int? order,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, description, status, order, createdAt, completedAt];
}

@HiveType(typeId: 2)
class TaskStatusAdapter extends TypeAdapter<TaskStatus> {
  @override
  final typeId = 2;

  @override
  TaskStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskStatus.pending;
      case 1:
        return TaskStatus.running;
      case 2:
        return TaskStatus.paused;
      case 3:
        return TaskStatus.completed;
      default:
        return TaskStatus.pending;
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
      case TaskStatus.paused:
        writer.writeByte(2);
        break;
      case TaskStatus.completed:
        writer.writeByte(3);
        break;
    }
  }
}
