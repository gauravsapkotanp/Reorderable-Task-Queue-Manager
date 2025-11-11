import 'package:flutter/material.dart';
import 'package:reorderable_list/features/home/data/model/task_model.dart';

class TaskItemWidget extends StatelessWidget {
  final TaskModel task;
  final int index;

  const TaskItemWidget({
    super.key,
    required this.task,
    required this.index,
  });

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.grey[400]!;
      case TaskStatus.running:
        return Colors.blue[400]!;
      case TaskStatus.paused:
        return Colors.orange[400]!;
      case TaskStatus.completed:
        return Colors.green[400]!;
    }
  }

  String _getStatusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.running:
        return 'Running';
      case TaskStatus.paused:
        return 'Paused';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(task.status),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Text(
                _getStatusLabel(task.status),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          ListTile(
            leading: ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_indicator_sharp,
                color: Colors.deepPurple,
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(
                task.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
