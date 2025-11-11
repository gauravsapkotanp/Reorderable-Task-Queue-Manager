import 'dart:developer';

import 'package:reorderable_list/features/home/data/model/task_status.dart';

class MockStorageService {
  static List<Task> _tasks = [];

  // In a real app, this would use SharedPreferences or Hive for persistence.
  // For this single-file demo, we use a static variable.

  static Future<List<Task>> loadTasks() async {
    if (_tasks.isEmpty) {
      // Initialize with 10 mock tasks
      _tasks = List.generate(
        10,
        (i) => Task(
          id: 'task_${i + 1}',
          title: 'Job Processing Task ${i + 1}',
          status: TaskStatus.pending,
          index: i,
        ),
      );
    }
    return Future.delayed(Duration(milliseconds: 50), () => _tasks);
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    // Mimic saving the current order and state
    _tasks = tasks.map((t) => t.copyWith()).toList();
    log('Tasks saved (Mock): ${_tasks.length} tasks');
    // In a real app, serialize and save to local storage here.
    await Future.delayed(Duration(milliseconds: 10));
  }
}
