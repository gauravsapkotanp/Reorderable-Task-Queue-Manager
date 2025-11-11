# Reorderable Queue Manager with Background Processing

A Flutter application that manages a queue of tasks with reordering capabilities and background processing using isolates.

## Features Implemented ✅

### 1. **UI Components**
- ✅ ReorderableListView with 10+ mock tasks
- ✅ Task item cards with:
  - Title and description
  - Status badges (Pending, Running, Paused, Completed)
  - Drag handle for reordering
  - Tap-to-open functionality

### 2. **Reordering**
- ✅ Drag and drop to reorder tasks
- ✅ Persistent storage using Hive database
- ✅ Minimal database writes using bulk updates
- ✅ New order automatically applied to pending tasks

### 3. **Isolate Background Processing**
- ✅ Separate isolate for task processing
- ✅ Full lifecycle management (start, pause, resume, terminate)
- ✅ Bi-directional communication via SendPort/ReceivePort
- ✅ Task processing with 3-second simulation per task
- ✅ Pause/Resume capability with flag-based logic

### 4. **State Management**
- ✅ BLoC pattern using `flutter_bloc`
- ✅ TaskQueueBloc with comprehensive events and states
- ✅ Real-time UI updates from isolate messages
- ✅ Internal event system for state updates

### 5. **Controls**
- ✅ **Start Button**: Begin processing tasks
- ✅ **Play/Pause Button**: Pause and resume processing
- ✅ **Restart Button**: Reset all tasks to pending
- ✅ **Clear Completed**: Remove completed tasks
- ✅ **Stop Button**: Terminate processing

### 6. **Local Database**
- ✅ Hive for persistent storage
- ✅ Task status persistence
- ✅ Order preservation
- ✅ Mock data initialization

## Project Structure

```
lib/
├── main.dart
├── core/
│   └── services/
│       ├── service_locator.dart
│       ├── hive_service.dart
│       └── isolate_manager.dart
├── features/
│   └── home/
│       ├── bloc/
│       │   ├── task_queue_bloc.dart
│       │   ├── task_queue_event.dart
│       │   └── task_queue_state.dart
│       ├── data/
│       │   ├── model/
│       │   │   ├── task_model.dart
│       │   │   └── task_model.g.dart (generated)
│       │   └── repository/
│       │       └── task_repository.dart
│       └── presentation/
│           ├── screens/
│           │   └── Home_screen.dart
│           └── widgets/
│               └── task_item_widget.dart
├── routes/
│   └── routes.dart
└── theme/
    ├── darkmode_bloc.dart
    ├── darkmode_event.dart
    └── darkmode_state.dart
```

## Key Components

### 1. **Task Model** (`task_model.dart`)
```dart
@HiveType(typeId: 1)
class TaskModel {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final int order;
  final DateTime createdAt;
  final DateTime? completedAt;
}
```

**TaskStatus Enum:**
- `pending`: Task is waiting to be processed
- `running`: Task is currently being processed
- `paused`: Task processing is paused
- `completed`: Task has been processed

### 2. **IsolateManager** (`isolate_manager.dart`)
Manages background isolate for task processing:
- **startProcessing()**: Spawns isolate and begins processing
- **pause()**: Pauses task processing
- **resume()**: Resumes paused processing
- **updateTasks()**: Updates task list during processing
- **terminate()**: Cleanly stops isolate

**Communication Protocol:**
- Main → Isolate: IsolateMessage with type and data
- Isolate → Main: Status updates and completion notifications

### 3. **TaskQueueBloc** (`task_queue_bloc.dart`)
Manages application state and orchestrates all operations:

**Events:**
- `FetchTasksEvent`: Load tasks from database
- `StartProcessingEvent`: Begin background processing
- `PauseProcessingEvent`: Pause processing
- `ResumeProcessingEvent`: Resume processing
- `RestartAllTasksEvent`: Reset all tasks
- `ClearCompletedTasksEvent`: Remove completed tasks
- `ReorderTasksEvent`: Update task order
- `TerminateProcessingEvent`: Stop processing

**States:**
- `TaskQueueInitial`: Initial state
- `TaskQueueLoading`: Loading tasks
- `TaskQueueLoaded`: Tasks ready with isProcessing and isPaused flags
- `TaskQueueError`: Error state with message

### 4. **TaskRepository** (`task_repository.dart`)
Handles all database operations:
- Initialization with 10 mock tasks
- CRUD operations
- Bulk reordering with minimal writes
- Clearing completed tasks
- Resetting task status

### 5. **Home Screen** (`Home_screen.dart`)
Main UI with:
- Stats bar showing Total/Completed/Pending counts
- ReorderableListView for task management
- Control buttons panel
- Real-time state updates via BLoC

## How It Works

### Initialization Flow
```
main()
  ↓
WidgetsFlutterBinding.ensureInitialized()
  ↓
await HiveSetup.init()  [← Important: Must be awaited]
  - Initialize Hive
  - Register adapters (TaskStatus, TaskModel)
  - Open tasksBox
  ↓
await setUpLocator()
  - Create TaskRepository instance
  - Initialize with mock data if empty
  - Register in GetIt
  ↓
runApp(MyApp)
  ↓
HomeScreen -> TaskQueueBloc -> BlocProvider
```

### Processing Flow
```
User taps "Start"
  ↓
StartProcessingEvent
  ↓
_onStartProcessing handler
  ↓
isolateManager.startProcessing(tasksToProcess)
  ↓
Isolate spawned with _processingIsolate function
  ↓
For each task:
  - Send task_status message (Running)
  - Await Future.delayed(3 seconds)
  - Send task_completed message
  - Update UI in real-time
  ↓
Send processing_complete message
```

### Pause/Resume Flow
```
User taps "Pause"
  ↓
PauseProcessingEvent
  ↓
_isPaused = true
isolateManager.pause()
  ↓
Isolate receives "pause" message
  ↓
while (isPausedFn()) { await Future.delayed(500ms) }
  ↓
Processing halted (not CPU intensive)
  ↓
User taps "Resume"
  ↓
ResumeProcessingEvent
  ↓
_isPaused = false
isolateManager.resume()
  ↓
while loop exits, processing continues
```

### Reordering Flow
```
User drags task from index 2 to index 5
  ↓
ReorderableListView onReorder callback
  ↓
ReorderTasksEvent with new order
  ↓
_onReorderTasks handler
  ↓
Remap task IDs to new order indices
  ↓
Save to database (batch operation)
  ↓
Update isolate if processing
  ↓
Emit TaskQueueLoaded with updated tasks
  ↓
UI rebuilds automatically
```

## Isolation & Communication

### Why Use Isolates?
- **Prevent UI Freezing**: Heavy processing doesn't block main thread
- **True Parallelism**: On multi-core devices, actual parallel execution
- **CPU-Bound Tasks**: Processing simulated with `Future.delayed()`

### Message Flow
```
Main Isolate              Isolate
    |                      |
    +---> IsolateMessage(type: 'initialize', data: tasks)
    |                      |
    |                  Process tasks
    |                      |
    |<---- IsolateMessage(type: 'task_status', data: {...})
    |                      |
    |                  Wait 3 seconds
    |                      |
    |<---- IsolateMessage(type: 'task_completed', data: TaskModel)
    |                      |
    |                  [Loop or complete]
    |                      |
    |<---- IsolateMessage(type: 'processing_complete')
```

## Dependencies

```yaml
flutter_bloc: ^9.1.1          # State management
bloc: ^9.1.0                  # Bloc core
hive: ^2.2.3                  # Local database
hive_flutter: ^1.1.0          # Hive Flutter integration
hive_generator: ^2.0.0        # Adapter code generation (dev)
build_runner: ^2.4.0          # Code generation runner (dev)
get_it: ^9.0.5                # Service locator
flutter_screenutil: ^5.9.3    # Responsive design
equatable: ^2.0.7             # Value equality
```

## Running the App

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Generate Hive Adapters
```bash
flutter pub run build_runner build
# Or for clean build:
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Run the App
```bash
flutter run
```

## Usage Instructions

### Starting Task Processing
1. Tap the **Start** button
2. Tasks will process sequentially (3 seconds each)
3. Task status changes: Pending → Running → Completed
4. Progress shown in stats bar

### Pausing Processing
1. Tap **Pause** while processing is running
2. Current task pauses execution
3. Pause button changes to "Resume"

### Resuming Processing
1. Tap **Resume** to continue
2. Processing resumes from where it paused

### Reordering Tasks
1. Long-press or grab the drag handle (≡) on any task
2. Drag to new position in the list
3. Release to drop
4. Order is saved automatically to database

### Restarting All Tasks
1. Tap **Restart** to reset all tasks to "Pending"
2. Useful for testing the processing flow multiple times

### Clearing Completed Tasks
1. Once some tasks are completed
2. Tap **Clear Completed** to remove them from list
3. Only completed tasks are removed

### Stopping Processing
1. While processing is running, tap **Stop**
2. Isolate is terminated immediately
3. Can start over with Start button

## Optimization Features

### Database Efficiency
- **Lazy Loading**: Tasks loaded on-demand via BLoC
- **Batch Reordering**: All order updates in single transaction
- **No Unnecessary Writes**: Only updates when data changes

### Performance
- **Isolate Usage**: Processing doesn't block UI
- **Minimal State Updates**: Only changed tasks trigger rebuilds
- **Efficient Message Passing**: Lightweight message objects

### UI/UX
- **Real-Time Updates**: Changes reflected immediately
- **Clear Status Indicators**: Color-coded status badges
- **Intuitive Controls**: Self-explanatory button layout
- **Responsive Design**: Works on different screen sizes

## Known Limitations & Future Enhancements

### Current Limitations
- Processing time is mocked (3 seconds per task)
- No error handling for individual tasks
- No task retry mechanism
- Single queue (no multiple queues)

### Future Enhancements
- Actual file processing instead of mocked delay
- Per-task error handling and retry logic
- Multiple priority queues
- Task scheduling
- Progress percentage per task
- Estimated time remaining
- Task history/logging
- Export completed tasks

## Troubleshooting

### HiveError: You need to initialize Hive
- **Solution**: Ensure `await HiveSetup.init()` is called in `main()` before accessing boxes

### Tasks not saving
- **Solution**: Check that TaskRepository is properly registered in GetIt service locator

### Isolate not starting
- **Solution**: Verify TaskModel is serializable and adapters are registered

### UI not updating during processing
- **Solution**: Ensure messages from isolate are being listened to in _setupIsolateMessageListener()

## Code Quality

- ✅ Type-safe Dart code
- ✅ Null safety enabled
- ✅ BLoC best practices
- ✅ Separation of concerns (UI/BLoC/Data)
- ✅ Comprehensive error handling
- ✅ Proper resource cleanup (close streams, terminate isolates)

---

**Created**: November 11, 2025  
**Framework**: Flutter 3.9.2+  
**State Management**: BLoC Pattern  
**Database**: Hive  
**Concurrency**: Dart Isolates
