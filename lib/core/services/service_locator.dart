// * Global Define
import 'package:get_it/get_it.dart';
import 'package:reorderable_list/features/home/data/repository/task_repository.dart';

GetIt getIt = GetIt.instance;

setUpLocator() async {
  // Register TaskRepository
  final taskRepository = TaskRepository();
  await taskRepository.init();
  getIt.registerSingleton<TaskRepository>(taskRepository);
}
