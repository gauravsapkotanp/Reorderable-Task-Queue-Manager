# Reorderable Queue Manager with Background Processing

A powerful Flutter application that manages a queue of tasks with reordering capabilities, background processing via Isolates, and persistent storage using Hive. Built with clean architecture principles using BLoC for state management.

## 🎯 Features

### ✨ Core Features
- **Reorderable Task Queue**: Drag and drop to reorder tasks in real-time
- **Background Isolate Processing**: Process tasks in a separate isolate with full lifecycle management
- **Pause/Resume Control**: Pause task processing and resume from where it left off
- **Persistent Storage**: All tasks are saved to Hive local database
- **Real-time Status Updates**: Monitor task status (Pending, Running, Paused, Completed)
- **Task Management**: Clear completed tasks, restart all tasks, or stop processing

### 🏗️ Architecture
- **Clean Architecture**: Organized into presentation, data, and core layers
- **BLoC Pattern**: Robust state management with flutter_bloc
- **Service Locator**: GetIt for dependency injection
- **Hive Database**: Local persistence with zero configuration
- **Isolate Communication**: SendPort/ReceivePort for main-isolate communication

## 📋 Requirements

### Minimum Requirements
- Flutter SDK: ^3.9.2
- Dart SDK: Included with Flutter
- Minimum Android: API 21
- Minimum iOS: 11.0

### Dependencies
```yaml
flutter_bloc: ^9.1.1          # State management
bloc: ^9.1.0                  # BLoC library
hive: ^2.2.3                  # Local database
hive_flutter: ^1.1.0          # Flutter integration for Hive
flutter_screenutil: ^5.9.3    # Responsive UI
get_it: ^9.0.5                # Service locator
equatable: ^2.0.7             # Value equality
```

## 🚀 Getting Started

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/reorderable_list.git
   cd reorderable_list
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters** (if using hive_generator)
   ```bash
   flutter pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── core/
│   └── services/
│       ├── hive_service.dart          # Hive database initialization
│       ├── isolate_manager.dart       # Isolate lifecycle management
│       └── service_locator.dart       # Dependency injection setup
├── features/
│   └── home/
│       ├── bloc/
│       │   ├── task_queue_bloc.dart   # BLoC for queue management
│       │   ├── task_queue_event.dart  # BLoC events
│       │   └── task_queue_state.dart  # BLoC states
│       ├── data/
│       │   ├── model/
│       │   │   └── task_model.dart    # Task data model with Hive adapters
│       │   ├── repository/
│       │   │   └── task_repository.dart # Data access layer
│       │   └── sources/
│       └── presentation/
│           ├── screens/
│           │   └── home_screen.dart   # Main task queue UI
│           └── widgets/
│               └── task_item_widget.dart # Individual task item widget
├── routes/
│   └── routes.dart                    # Route navigation
└── theme/
    ├── darkmode_bloc.dart             # Theme BLoC
    ├── darkmode_event.dart            # Theme events
    └── darkmode_state.dart            # Theme states
```

## 🎮 Usage Guide

### Launching the App

When you run the app, you'll be greeted with a splash screen that navigates to the Home Screen after 2 seconds.

### Task Queue Interface

#### 1. **Stats Bar**
Displays three statistics:
- **Total**: Total number of tasks
- **Completed**: Number of completed tasks
- **Pending**: Number of pending tasks

#### 2. **Task List**
A reorderable list view with at least 10 mock tasks. Each task item shows:
- **Drag Handle**: Long press to drag and reorder
- **Title**: Task name (e.g., "Task 1: Process Invoice")
- **Description**: Brief task description
- **Status Badge**: Color-coded status indicator
  - 🟩 **Pending** (Gray): Not started
  - 🟦 **Running** (Blue): Currently processing
  - 🟨 **Paused** (Orange): Processing paused
  - 🟩 **Completed** (Green): Task finished

#### 3. **Control Buttons**

##### First Row
- **Start**: Begin processing tasks (only available when not processing)
- **Pause/Resume**: Toggle pause during processing
- **Restart**: Reset all tasks to pending status

##### Second Row
- **Clear Completed**: Remove all completed tasks from the queue
- **Stop**: Terminate current processing (visible only when processing)

## 📝 Task Management

### Creating Tasks

Tasks are initialized as mock data on first app launch. The repository automatically creates 10 sample tasks:

```dart
TaskModel(
  id: '1',
  title: 'Task 1: Process Invoice',
  description: 'Process invoice data',
  status: TaskStatus.pending,
  order: 0,
  createdAt: DateTime.now(),
)
```

### Reordering Tasks

1. **Drag and Drop**: 
   - Press and hold on a task
   - Drag to new position
   - Release to place

2. **Persistence**:
   - Order is automatically saved to Hive
   - Minimal write operations for efficiency
   - Order preserved on app restart

### Processing Workflow

1. **Start Processing**
   - Click "Start" button
   - Isolate begins processing tasks one by one
   - Each task takes ~3 seconds to process (simulated)
   - Status updates in real-time

2. **Pause/Resume**
   - Click "Pause" to pause during processing
   - Click "Resume" to continue from where it paused
   - Other controls disabled during processing

3. **Stop Processing**
   - Click "Stop" to terminate processing
   - Isolate is properly cleaned up
   - Tasks retain their current status

## 🔄 Isolate Architecture

### Main Features
- **Separate Execution**: Tasks run in a dedicated isolate (background thread)
- **Two-way Communication**: Uses SendPort and ReceivePort
- **Lifecycle Management**: 
  - Start: Initialize isolate with task list
  - Pause: Freeze execution state
  - Resume: Continue from pause point
  - Terminate: Cleanly shut down isolate

### Message Types
- `'initialize'`: Send tasks to isolate
- `'pause'`: Pause task processing
- `'resume'`: Resume task processing
- `'update_tasks'`: Update task list in isolate
- `'terminate'`: Stop isolate execution
- `'task_status'`: Task status update from isolate
- `'task_completed'`: Task completion from isolate
- `'processing_complete'`: All tasks finished

## 💾 Data Persistence

### Hive Setup
```dart
// lib/core/services/hive_service.dart
class HiveSetup {
  static Future<void> init() async {
    await Hive.initFlutter();
    // Register adapters for type safety
    Hive.registerAdapter(TaskStatusAdapter());
    // Box initialization handled by repository
  }
}
```

### Task Repository

The `TaskRepository` handles all database operations:

```dart
// Fetch all tasks (sorted by order)
final tasks = await taskRepository.getAllTasks();

// Update single task
await taskRepository.updateTask(updatedTask);

// Reorder tasks
await taskRepository.reorderTasks(newOrderedList);

// Clear completed
await taskRepository.clearCompletedTasks();

// Reset all tasks
await taskRepository.resetAllTasks();
```

## 🎨 UI/UX Features

### Responsive Design
- Built with `flutter_screenutil` for multi-device support
- Design size: 375 x 812 (iPhone SE baseline)
- Scales automatically for tablets and larger screens

### Color Scheme
- **Primary**: Blue (#0066FF)
- **Success**: Green (#00CC00)
- **Warning**: Orange (#FF9900)
- **Danger**: Red (#FF0000)
- **Neutral**: Gray (#999999)

### Interactive Elements
- Status badges with color coding
- Drag handles for reordering
- Disabled buttons during processing
- Real-time UI updates via BLoC
- Statistics counter updates

## 🔧 State Management (BLoC)

### Events
```dart
FetchTasksEvent()              // Load tasks
StartProcessingEvent()         // Begin processing
PauseProcessingEvent()         // Pause execution
ResumeProcessingEvent()        // Resume execution
RestartAllTasksEvent()         // Reset all tasks
ClearCompletedTasksEvent()     // Remove completed
ReorderTasksEvent(newOrder)    // Update task order
TaskStatusChangedEvent(id, status) // Manual status update
TerminateProcessingEvent()     // Stop processing
```

### States
```dart
TaskQueueInitial()             // Initial state
TaskQueueLoading()             // Loading state
TaskQueueLoaded(tasks)         // Tasks loaded successfully
TaskQueueError(message)        // Error occurred
ProcessingComplete(tasks)      // All tasks processed
```

## 📊 Performance Optimization

### Database Efficiency
- Minimal write operations on reorder
- Batch updates for multiple tasks
- Efficient key lookup for task updates

### Memory Management
- Proper isolate cleanup on app close
- Stream subscription cancellation
- Resource disposal in BLoC close()

### UI Performance
- ReorderableListView for smooth animations
- ValueKey for proper list item tracking
- Lazy loading capability (bonus feature)

## 🐛 Debugging

### Enable Verbose Logging
```dart
// In main.dart during initialization
print('Hive initialization error: $e');
print('Error opening Hive boxes: $e');
```

### Common Issues

1. **Hive Not Initialized Error**
   - Ensure `HiveSetup.init()` is called before `setUpLocator()`
   - Check main.dart initialization order

2. **Adapters Not Registered**
   - Run `flutter pub run build_runner build` if using generated adapters
   - Manually register adapters in correct order

3. **Isolate Communication Issues**
   - Ensure messages are serializable
   - Check IsolateMessage type casting
   - Verify SendPort/ReceivePort pairing

## 📦 Building for Release

### Android
```bash
flutter build apk --split-per-abi
# or
flutter build appbundle
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🧪 Testing

Create a test file at `test/widget_test.dart`:

```dart
void main() {
  testWidgets('Task queue loads with tasks', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Task 1: Process Invoice'), findsOneWidget);
  });
}
```

Run tests:
```bash
flutter test
```

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [BLoC Pattern Documentation](https://bloclibrary.dev/)
- [Hive Database Documentation](https://docs.hivedb.dev/)
- [Isolates in Dart](https://dart.dev/guides/language/concurrency)
- [Flutter GetIt Service Locator](https://github.com/flutterando/get_it)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Author

**Garry** - [GitHub Profile](https://github.com/yourusername)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- BLoC library maintainers
- Hive database developers
- All contributors and supporters

## 📞 Support

For support, email garry@example.com or open an issue in the GitHub repository.

---

**Last Updated**: November 11, 2025

**Version**: 1.0.0

**Status**: Active Development ✅
