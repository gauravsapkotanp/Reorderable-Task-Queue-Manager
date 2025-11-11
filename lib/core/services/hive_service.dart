import 'package:hive_flutter/hive_flutter.dart';
import 'package:reorderable_list/features/home/data/model/task_model.dart';

class HiveSetup {
  static Future<void> init() async {
    try {
      await Hive.initFlutter();

      // Register Hive Adapters
      Hive.registerAdapter(TaskStatusAdapter());
      Hive.registerAdapter(TaskModelAdapter());

      // Open Boxes
      await _openHiveBoxes();
    } catch (e) {
      print('Hive initialization error: $e');
      rethrow;
    }
  }

  static Future<void> _openHiveBoxes() async {
    try {
      await Hive.openBox<TaskModel>('tasksBox');
    } catch (e) {
      print('Error opening Hive boxes: $e');
      rethrow;
    }
  }
}
