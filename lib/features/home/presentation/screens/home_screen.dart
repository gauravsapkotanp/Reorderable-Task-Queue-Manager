import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reorderable_list/features/home/bloc/task_queue_bloc.dart';
import 'package:reorderable_list/features/home/bloc/task_queue_event.dart';
import 'package:reorderable_list/features/home/bloc/task_queue_state.dart';
import 'package:reorderable_list/features/home/presentation/widgets/task_item_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TaskQueueBloc _taskQueueBloc;

  @override
  void initState() {
    super.initState();
    _taskQueueBloc = TaskQueueBloc();
    _taskQueueBloc.add(const FetchTasksEvent());
  }

  @override
  void dispose() {
    _taskQueueBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TaskQueueBloc>(
      create: (context) => _taskQueueBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Task Queue Manager'),
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<TaskQueueBloc, TaskQueueState>(
          builder: (context, state) {
            if (state is TaskQueueLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is TaskQueueError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${state.message}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<TaskQueueBloc>().add(const FetchTasksEvent());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is TaskQueueLoaded) {
              return Column(
                children: [
                  // Stats Bar
                  Container(
                    color: Colors.grey[100],
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Total',
                          value: state.tasks.length.toString(),
                          color: Colors.blue,
                        ),
                        _StatItem(
                          label: 'Completed',
                          value: state.completedCount.toString(),
                          color: Colors.green,
                        ),
                        _StatItem(
                          label: 'Pending',
                          value: (state.tasks.length - state.completedCount).toString(),
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  // Task List
                  Expanded(
                    child: state.tasks.isEmpty
                        ? Center(
                            child: Text(
                              'No tasks available',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : ReorderableListView(
                            onReorder: (oldIndex, newIndex) {
                              // Adjust index for removal
                              if (oldIndex < newIndex) {
                                newIndex -= 1;
                              }

                              final reorderedTasks = List<String>.from(
                                state.tasks.map((t) => t.id),
                              );
                              final task = reorderedTasks.removeAt(oldIndex);
                              reorderedTasks.insert(newIndex, task);

                              context.read<TaskQueueBloc>().add(ReorderTasksEvent(reorderedTasks));
                            },
                            children: [
                              for (int i = 0; i < state.tasks.length; i++)
                                TaskItemWidget(
                                  key: ValueKey(state.tasks[i].id),
                                  index: i,
                                  task: state.tasks[i],
                                ),
                            ],
                          ),
                  ),
                  // Control Buttons
                  Container(
                    color: Colors.grey[100],
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: state.isProcessing
                                  ? null
                                  : () {
                                      context.read<TaskQueueBloc>().add(const StartProcessingEvent());
                                    },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                disabledBackgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: !state.isProcessing
                                  ? null
                                  : (state.isPaused
                                        ? () {
                                            context.read<TaskQueueBloc>().add(const ResumeProcessingEvent());
                                          }
                                        : () {
                                            context.read<TaskQueueBloc>().add(const PauseProcessingEvent());
                                          }),
                              icon: Icon(
                                state.isPaused ? Icons.play_arrow : Icons.pause,
                              ),
                              label: Text(state.isPaused ? 'Resume' : 'Pause'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                disabledBackgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                context.read<TaskQueueBloc>().add(const RestartAllTasksEvent());
                              },
                              icon: const Icon(Icons.restart_alt),
                              label: const Text('Restart'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  context.read<TaskQueueBloc>().add(const ClearCompletedTasksEvent());
                                },
                                icon: const Icon(Icons.delete_sweep),
                                label: const Text('Clear Completed'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (state.isProcessing)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<TaskQueueBloc>().add(const TerminateProcessingEvent());
                                  },
                                  icon: const Icon(Icons.stop),
                                  label: const Text('Stop'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[800],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
