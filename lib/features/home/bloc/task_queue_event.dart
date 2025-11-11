import 'package:equatable/equatable.dart';

abstract class TaskQueueEvent extends Equatable {
  const TaskQueueEvent();

  @override
  List<Object?> get props => [];
}

class FetchTasksEvent extends TaskQueueEvent {
  const FetchTasksEvent();
}

class StartProcessingEvent extends TaskQueueEvent {
  const StartProcessingEvent();
}

class PauseProcessingEvent extends TaskQueueEvent {
  const PauseProcessingEvent();
}

class ResumeProcessingEvent extends TaskQueueEvent {
  const ResumeProcessingEvent();
}

class RestartAllTasksEvent extends TaskQueueEvent {
  const RestartAllTasksEvent();
}

class ClearCompletedTasksEvent extends TaskQueueEvent {
  const ClearCompletedTasksEvent();
}

class ReorderTasksEvent extends TaskQueueEvent {
  final List<String> newOrder;

  const ReorderTasksEvent(this.newOrder);

  @override
  List<Object?> get props => [newOrder];
}

class TaskStatusChangedEvent extends TaskQueueEvent {
  final String taskId;
  final String status;

  const TaskStatusChangedEvent(this.taskId, this.status);

  @override
  List<Object?> get props => [taskId, status];
}

class TerminateProcessingEvent extends TaskQueueEvent {
  const TerminateProcessingEvent();
}
