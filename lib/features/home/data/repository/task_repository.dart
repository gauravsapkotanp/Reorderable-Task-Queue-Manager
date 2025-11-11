import 'package:hive/hive.dart';
import 'package:reorderable_list/features/home/data/model/task_model.dart';

class TaskRepository {
  static const String _boxName = 'tasksBox';
  late Box<TaskModel> _taskBox;

  Future<void> init() async {
    // Get the already opened box
    _taskBox = Hive.box<TaskModel>(_boxName);
    // Initialize with mock data if empty
    if (_taskBox.isEmpty) {
      await _initializeMockTasks();
    }
  }

  Future<void> _initializeMockTasks() async {
    // Generate mock tasks with guaranteed-unique ids and slightly staggered createdAt
    final baseMicros = DateTime.now().microsecondsSinceEpoch;
    final titles = [
      'Process Invoice',
      'Send Email Notification',
      'Update Database',
      'Generate Report',
      'Backup Database',
      'Clean Cache',
      'Sync Cloud Data',
      'Validate User Input',
      'Send Webhook',
      'Archive Old Records',
    ];
    final descriptions = [
      'Process invoice data',
      'Send email to user',
      'Update user records',
      'Generate monthly report',
      'Create database backup',
      'Clean application cache',
      'Sync with cloud storage',
      'Validate form data',
      'Send webhook notification',
      'Archive old data',
    ];

    for (var i = 0; i < titles.length; i++) {
      final id = 'task-${baseMicros + i}';
      final createdAt = DateTime.fromMicrosecondsSinceEpoch(baseMicros + i);

      final task = TaskModel(
        id: id,
        title: 'Task ${i + 1}: ${titles[i]}',
        description: descriptions[i],
        status: TaskStatus.pending,
        order: i,
        createdAt: createdAt,
      );

      await _taskBox.add(task);
    }
  }

  Future<List<TaskModel>> getAllTasks() async {
    final tasks = _taskBox.values.toList();
    tasks.sort((a, b) => a.order.compareTo(b.order));
    return tasks;
  }

  Future<void> updateTask(TaskModel task) async {
    final key = _getTaskKey(task.id);
    if (key != null) {
      await _taskBox.put(key, task);
    }
  }

  Future<void> updateTasks(List<TaskModel> tasks) async {
    for (final task in tasks) {
      await updateTask(task);
    }
  }

  Future<void> reorderTasks(List<TaskModel> tasks) async {
    for (int i = 0; i < tasks.length; i++) {
      final updatedTask = tasks[i].copyWith(order: i);
      await updateTask(updatedTask);
    }
  }

  Future<void> deleteTask(String id) async {
    final key = _getTaskKey(id);
    if (key != null) {
      await _taskBox.delete(key);
    }
  }

  Future<void> clearCompletedTasks() async {
    final completedTasks = _taskBox.values.where((task) => task.status == TaskStatus.completed).toList();

    for (final task in completedTasks) {
      final key = _getTaskKey(task.id);
      if (key != null) {
        await _taskBox.delete(key);
      }
    }
  }

  Future<void> resetAllTasks() async {
    final allTasks = _taskBox.values.toList();
    for (final task in allTasks) {
      final resetTask = task.copyWith(status: TaskStatus.pending);
      await updateTask(resetTask);
    }
  }

  int? _getTaskKey(String id) {
    for (int i = 0; i < _taskBox.length; i++) {
      if (_taskBox.getAt(i)?.id == id) {
        return i;
      }
    }
    return null;
  }

  Future<void> clearAll() async {
    await _taskBox.clear();
  }

  Future<void> dispose() async {
    await _taskBox.close();
  }
}
