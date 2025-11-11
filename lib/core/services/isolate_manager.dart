import 'dart:async';
import 'dart:isolate';

import 'package:reorderable_list/features/home/data/model/task_model.dart';

// Message classes for isolate communication
class IsolateMessage {
  final String type;
  final dynamic data;

  IsolateMessage({required this.type, this.data});
}

class IsolateManager {
  late Isolate _isolate;
  late SendPort _sendPort;
  late ReceivePort _receivePort;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isClosed = false;
  late StreamController<IsolateMessage> _messageController;

  Stream<IsolateMessage> get messages => _messageController.stream;

  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;

  IsolateManager() {
    _messageController = StreamController<IsolateMessage>.broadcast();
  }

  Future<void> startProcessing(List<TaskModel> tasks) async {
    if (_isRunning) return;

    // Reset stream controller if it was closed
    if (_messageController.isClosed) {
      // Create a new stream controller
      // ignore: close_sinks
      _messageController = StreamController<IsolateMessage>.broadcast();
      _isClosed = false;
    }

    _receivePort = ReceivePort();
    _isRunning = true;
    _isPaused = false;

    _isolate = await Isolate.spawn(
      _processingIsolate,
      _receivePort.sendPort,
    );

    _receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        // Send initial tasks
        _sendPort.send(IsolateMessage(type: 'initialize', data: tasks));
      } else if (message is IsolateMessage) {
        if (!_isClosed && !_messageController.isClosed) {
          _messageController.add(message);
        }
      }
    });
  }

  void pause() {
    if (_isRunning && !_isPaused) {
      _isPaused = true;
      _sendPort.send(IsolateMessage(type: 'pause'));
    }
  }

  void resume() {
    if (_isRunning && _isPaused) {
      _isPaused = false;
      _sendPort.send(IsolateMessage(type: 'resume'));
    }
  }

  void updateTasks(List<TaskModel> tasks) {
    if (_isRunning) {
      _sendPort.send(IsolateMessage(type: 'update_tasks', data: tasks));
    }
  }

  Future<void> terminate() async {
    if (_isRunning) {
      _isRunning = false;
      _isClosed = true;
      try {
        _sendPort.send(IsolateMessage(type: 'terminate'));
        _isolate.kill(priority: Isolate.immediate);
        _receivePort.close();
      } catch (e) {
        // Handle any errors during termination
      }
      // Close the message controller after isolate is terminated
      if (!_messageController.isClosed) {
        await _messageController.close();
      }
    }
  }

  static void _processingIsolate(SendPort sendPort) async {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    bool isPaused = false;
    List<TaskModel> currentTasks = [];
    bool shouldTerminate = false;

    await for (final message in receivePort) {
      if (message is IsolateMessage) {
        switch (message.type) {
          case 'initialize':
            currentTasks = List.from(message.data as List<TaskModel>);
            _startProcessingLoop(
              sendPort,
              currentTasks,
              () => isPaused,
              () => shouldTerminate,
            );
            break;

          case 'pause':
            isPaused = true;
            break;

          case 'resume':
            isPaused = false;
            break;

          case 'update_tasks':
            currentTasks = List.from(message.data as List<TaskModel>);
            break;

          case 'terminate':
            shouldTerminate = true;
            receivePort.close();
            return;
        }
      }
    }
  }

  static void _startProcessingLoop(
    SendPort sendPort,
    List<TaskModel> tasks,
    bool Function() isPausedFn,
    bool Function() shouldTerminate,
  ) async {
    for (int i = 0; i < tasks.length; i++) {
      if (shouldTerminate()) break;

      // Check if paused
      while (isPausedFn() && !shouldTerminate()) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (shouldTerminate()) break;

      final task = tasks[i];

      // Send status update
      sendPort.send(
        IsolateMessage(
          type: 'task_status',
          data: {'taskId': task.id, 'status': TaskStatus.running},
        ),
      );

      // Simulate processing
      await Future.delayed(const Duration(seconds: 3));

      if (shouldTerminate()) break;

      final completedTask = task.copyWith(
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
      );

      // Send completion update
      sendPort.send(
        IsolateMessage(
          type: 'task_completed',
          data: completedTask,
        ),
      );
    }

    if (!shouldTerminate()) {
      // Send completion message
      sendPort.send(IsolateMessage(type: 'processing_complete'));
    }
  }
}
