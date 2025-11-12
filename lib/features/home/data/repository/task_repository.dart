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
    // Generate mock tasks with guaranteed-unique ids and slightly staggered createdA
    final baseMicros = DateTime.now().microsecondsSinceEpoch;
    final titleTemplates = [
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
      'Optimize Performance',
      'Fix Bug Report',
      'Deploy to Production',
      'Review Pull Requests',
      'Update Documentation',
      'Schedule Maintenance',
      'Monitor Server Health',
      'Analyze User Behavior',
      'Create API Endpoint',
      'Test Payment Gateway',
      'Migrate Legacy Code',
      'Audit Security Logs',
      'Compress Media Files',
      'Update Dependencies',
      'Generate Invoice PDF',
      'Send Reminder Email',
      'Backup User Data',
      'Optimize Database Queries',
      'Run Unit Tests',
      'Deploy Hotfix',
      'Monitor API Usage',
      'Schedule Backup Job',
      'Update Cache Strategy',
      'Process Refund Request',
      'Validate Email Address',
      'Generate Report PDF',
      'Cleanup Temp Files',
      'Update SSL Certificate',
      'Process Payment',
      'Send Alert Notification',
    ];
    final descriptionTemplates = [
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
      'Optimize system performance',
      'Fix reported software bug',
      'Deploy latest version to production',
      'Review and approve code changes',
      'Update API and user documentation',
      'Schedule system maintenance window',
      'Monitor server health metrics',
      'Analyze user behavior patterns',
      'Create new REST API endpoint',
      'Test payment gateway integration',
      'Migrate legacy system code',
      'Audit security access logs',
      'Compress all media files',
      'Update project dependencies',
      'Generate monthly invoice PDF',
      'Send user reminder email',
      'Backup all user account data',
      'Optimize slow database queries',
      'Run all unit and integration tests',
      'Deploy hotfix to production',
      'Monitor API request usage',
      'Schedule automated backup job',
      'Update caching strategy',
      'Process customer refund request',
      'Validate email address format',
      'Generate financial report PDF',
      'Clean up temporary files',
      'Update SSL/TLS certificate',
      'Process payment transaction',
      'Send critical system alert',
    ];

    // Generate 40 tasks by cycling through templates
    for (var i = 0; i < 40; i++) {
      final templateIndex = i % titleTemplates.length;
      final id = 'task-${baseMicros + i}';
      final createdAt = DateTime.fromMicrosecondsSinceEpoch(baseMicros + i);

      final task = TaskModel(
        id: id,
        title: 'Task ${i + 1}: ${titleTemplates[templateIndex]}',
        description: descriptionTemplates[templateIndex],
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
