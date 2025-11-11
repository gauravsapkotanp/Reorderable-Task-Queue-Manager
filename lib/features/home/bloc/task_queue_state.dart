import 'package:equatable/equatable.dart';
import 'package:reorderable_list/features/home/data/model/task_model.dart';

abstract class TaskQueueState extends Equatable {
  const TaskQueueState();

  @override
  List<Object?> get props => [];
}

class TaskQueueInitial extends TaskQueueState {
  const TaskQueueInitial();
}

class TaskQueueLoading extends TaskQueueState {
  const TaskQueueLoading();
}

class TaskQueueLoaded extends TaskQueueState {
  final List<TaskModel> tasks;
  final bool isProcessing;
  final bool isPaused;
  final int completedCount;

  const TaskQueueLoaded({
    required this.tasks,
    this.isProcessing = false,
    this.isPaused = false,
    this.completedCount = 0,
  });

  TaskQueueLoaded copyWith({
    List<TaskModel>? tasks,
    bool? isProcessing,
    bool? isPaused,
    int? completedCount,
  }) {
    return TaskQueueLoaded(
      tasks: tasks ?? this.tasks,
      isProcessing: isProcessing ?? this.isProcessing,
      isPaused: isPaused ?? this.isPaused,
      completedCount: completedCount ?? this.completedCount,
    );
  }

  @override
  List<Object?> get props => [tasks, isProcessing, isPaused, completedCount];
}

class TaskQueueError extends TaskQueueState {
  final String message;

  const TaskQueueError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProcessingComplete extends TaskQueueState {
  final List<TaskModel> tasks;

  const ProcessingComplete(this.tasks);

  @override
  List<Object?> get props => [tasks];
}
