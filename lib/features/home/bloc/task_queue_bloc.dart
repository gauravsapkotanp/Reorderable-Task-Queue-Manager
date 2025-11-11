import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reorderable_list/core/services/isolate_manager.dart';
import 'package:reorderable_list/core/services/service_locator.dart';
import 'package:reorderable_list/features/home/bloc/task_queue_event.dart';
import 'package:reorderable_list/features/home/bloc/task_queue_state.dart';
import 'package:reorderable_list/features/home/data/model/task_model.dart';
import 'package:reorderable_list/features/home/data/repository/task_repository.dart';

class TaskQueueBloc extends Bloc<TaskQueueEvent, TaskQueueState> {
  final taskRepository = getIt.get<TaskRepository>();
  late IsolateManager _isolateManager;
  List<TaskModel> _currentTasks = [];
  bool _isProcessing = false;
  bool _isPaused = false;
  late StreamSubscription<IsolateMessage> _isolateSubscription;

  TaskQueueBloc() : super(const TaskQueueInitial()) {
    on<FetchTasksEvent>(_onFetchTasks);
    on<StartProcessingEvent>(_onStartProcessing);
    on<PauseProcessingEvent>(_onPauseProcessing);
    on<ResumeProcessingEvent>(_onResumeProcessing);
    on<RestartAllTasksEvent>(_onRestartAllTasks);
    on<ClearCompletedTasksEvent>(_onClearCompletedTasks);
    on<ReorderTasksEvent>(_onReorderTasks);
    on<TaskStatusChangedEvent>(_onTaskStatusChanged);
    on<TerminateProcessingEvent>(_onTerminateProcessing);
    on<_TaskStateUpdateEvent>(_onTaskStateUpdate);

    _isolateManager = IsolateManager();
    _setupIsolateMessageListener();
  }

  void _setupIsolateMessageListener() {
    _isolateSubscription = _isolateManager.messages.listen((IsolateMessage message) {
      if (message.type == 'task_status') {
        final data = message.data as Map<String, dynamic>;
        final taskId = data['taskId'] as String;

        final taskIndex = _currentTasks.indexWhere((task) => task.id == taskId);
        if (taskIndex != -1) {
          final task = _currentTasks[taskIndex];
          _currentTasks[taskIndex] = task.copyWith(status: TaskStatus.running);
          _emitCurrentState();
        }
      } else if (message.type == 'task_completed') {
        final completedTask = message.data as TaskModel;

        final taskIndex = _currentTasks.indexWhere((task) => task.id == completedTask.id);
        if (taskIndex != -1) {
          _currentTasks[taskIndex] = completedTask;
          taskRepository.updateTask(completedTask);
          _emitCurrentState();
        }
      } else if (message.type == 'processing_complete') {
        _isProcessing = false;
        _emitCurrentState();
      }
    });
  }

  Future<void> _onFetchTasks(
    FetchTasksEvent event,
    Emitter<TaskQueueState> emit,
  ) async {
    emit(const TaskQueueLoading());
    try {
      final tasks = await taskRepository.getAllTasks();
      _currentTasks = tasks;
      final completedCount = tasks.where((t) => t.status == TaskStatus.completed).length;
      emit(
        TaskQueueLoaded(
          tasks: tasks,
          isProcessing: _isProcessing,
          isPaused: _isPaused,
          completedCount: completedCount,
        ),
      );
    } catch (e) {
      emit(TaskQueueError('Failed to fetch tasks: $e'));
    }
  }

  Future<void> _onStartProcessing(
    StartProcessingEvent event,
    Emitter<TaskQueueState> emit,
  ) async {
    if (_isProcessing) return;

    try {
      _isProcessing = true;
      _isPaused = false;

      final tasksToProcess = _currentTasks.where((task) => task.status != TaskStatus.completed).toList();

      // Create a fresh isolate manager for each processing cycle
      _isolateManager = IsolateManager();
      _isolateSubscription.cancel();
      _setupIsolateMessageListener();

      await _isolateManager.startProcessing(tasksToProcess);

      if (state is TaskQueueLoaded) {
        emit((state as TaskQueueLoaded).copyWith(isProcessing: true, isPaused: false));
      }
    } catch (e) {
      emit(TaskQueueError('Failed to start processing: $e'));
    }
  }

  void _onPauseProcessing(
    PauseProcessingEvent event,
    Emitter<TaskQueueState> emit,
  ) {
    if (_isProcessing && !_isPaused) {
      _isPaused = true;
      _isolateManager.pause();

      if (state is TaskQueueLoaded) {
        emit((state as TaskQueueLoaded).copyWith(isPaused: true));
      }
    }
  }

  void _onResumeProcessing(
    ResumeProcessingEvent event,
    Emitter<TaskQueueState> emit,
  ) {
    if (_isProcessing && _isPaused) {
      _isPaused = false;
      _isolateManager.resume();

      if (state is TaskQueueLoaded) {
        emit((state as TaskQueueLoaded).copyWith(isPaused: false));
      }
    }
  }

  Future<void> _onRestartAllTasks(
    RestartAllTasksEvent event,
    Emitter<TaskQueueState> emit,
  ) async {
    try {
      // Terminate current processing
      if (_isProcessing) {
        await _isolateManager.terminate();
        _isProcessing = false;
      }

      // Reset all tasks
      await taskRepository.resetAllTasks();
      final updatedTasks = await taskRepository.getAllTasks();
      _currentTasks = updatedTasks;

      final completedCount = updatedTasks.where((t) => t.status == TaskStatus.completed).length;
      emit(
        TaskQueueLoaded(
          tasks: updatedTasks,
          isProcessing: _isProcessing,
          isPaused: _isPaused,
          completedCount: completedCount,
        ),
      );
    } catch (e) {
      emit(TaskQueueError('Failed to restart tasks: $e'));
    }
  }

  Future<void> _onClearCompletedTasks(
    ClearCompletedTasksEvent event,
    Emitter<TaskQueueState> emit,
  ) async {
    try {
      await taskRepository.clearCompletedTasks();
      final updatedTasks = await taskRepository.getAllTasks();
      _currentTasks = updatedTasks;

      final completedCount = updatedTasks.where((t) => t.status == TaskStatus.completed).length;
      emit(
        TaskQueueLoaded(
          tasks: updatedTasks,
          isProcessing: _isProcessing,
          isPaused: _isPaused,
          completedCount: completedCount,
        ),
      );
    } catch (e) {
      emit(TaskQueueError('Failed to clear completed tasks: $e'));
    }
  }

  Future<void> _onReorderTasks(
    ReorderTasksEvent event,
    Emitter<TaskQueueState> emit,
  ) async {
    try {
      // Reorder based on task IDs
      final reorderedTasks = <TaskModel>[];
      for (int i = 0; i < event.newOrder.length; i++) {
        final taskId = event.newOrder[i];
        final task = _currentTasks.firstWhere((t) => t.id == taskId);
        reorderedTasks.add(task.copyWith(order: i));
      }

      _currentTasks = reorderedTasks;

      // Save to database
      await taskRepository.reorderTasks(reorderedTasks);

      // Update isolate if processing
      if (_isProcessing) {
        _isolateManager.updateTasks(reorderedTasks);
      }

      final completedCount = reorderedTasks.where((t) => t.status == TaskStatus.completed).length;
      emit(
        TaskQueueLoaded(
          tasks: reorderedTasks,
          isProcessing: _isProcessing,
          isPaused: _isPaused,
          completedCount: completedCount,
        ),
      );
    } catch (e) {
      emit(TaskQueueError('Failed to reorder tasks: $e'));
    }
  }

  Future<void> _onTaskStatusChanged(
    TaskStatusChangedEvent event,
    Emitter<TaskQueueState> emit,
  ) async {
    try {
      final taskIndex = _currentTasks.indexWhere((task) => task.id == event.taskId);
      if (taskIndex != -1) {
        final statusEnum = _stringToTaskStatus(event.status);
        final updatedTask = _currentTasks[taskIndex].copyWith(status: statusEnum);
        _currentTasks[taskIndex] = updatedTask;
        await taskRepository.updateTask(updatedTask);
        _emitCurrentState();
      }
    } catch (e) {
      emit(TaskQueueError('Failed to update task status: $e'));
    }
  }

  Future<void> _onTerminateProcessing(
    TerminateProcessingEvent event,
    Emitter<TaskQueueState> emit,
  ) async {
    try {
      if (_isProcessing) {
        await _isolateManager.terminate();
        _isProcessing = false;
        _isPaused = false;

        _emitCurrentState();
      }
    } catch (e) {
      emit(TaskQueueError('Failed to terminate processing: $e'));
    }
  }

  Future<void> _onTaskStateUpdate(
    _TaskStateUpdateEvent event,
    Emitter<TaskQueueState> emit,
  ) async {
    emit(
      TaskQueueLoaded(
        tasks: event.tasks,
        isProcessing: event.isProcessing,
        isPaused: event.isPaused,
        completedCount: event.completedCount,
      ),
    );
  }

  void _emitCurrentState() {
    final completedCount = _currentTasks.where((t) => t.status == TaskStatus.completed).length;

    add(
      _TaskStateUpdateEvent(
        tasks: _currentTasks,
        isProcessing: _isProcessing,
        isPaused: _isPaused,
        completedCount: completedCount,
      ),
    );
  }

  TaskStatus _stringToTaskStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return TaskStatus.pending;
      case 'running':
        return TaskStatus.running;
      case 'paused':
        return TaskStatus.paused;
      case 'completed':
        return TaskStatus.completed;
      default:
        return TaskStatus.pending;
    }
  }

  @override
  Future<void> close() async {
    await _isolateSubscription.cancel();
    if (_isProcessing) {
      await _isolateManager.terminate();
    }
    await super.close();
  }
}

// Internal event for state updates from isolate messages
class _TaskStateUpdateEvent extends TaskQueueEvent {
  final List<TaskModel> tasks;
  final bool isProcessing;
  final bool isPaused;
  final int completedCount;

  const _TaskStateUpdateEvent({
    required this.tasks,
    required this.isProcessing,
    required this.isPaused,
    required this.completedCount,
  });

  @override
  List<Object?> get props => [tasks, isProcessing, isPaused, completedCount];
}
