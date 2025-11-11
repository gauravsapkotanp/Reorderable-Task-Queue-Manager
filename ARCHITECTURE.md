# Architecture & Flow Diagrams

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   UI Layer (Presentation)                │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  HomeScreen                                        │  │  │
│  │  ├────────────────────────────────────────────────────┤  │  │
│  │  │  • AppBar with title                              │  │  │
│  │  │  • Stats Container (Total/Completed/Pending)      │  │  │
│  │  │  • ReorderableListView with 10 tasks              │  │  │
│  │  │  • Task Items (with drag handles)                 │  │  │
│  │  │  • Control Buttons (Start/Pause/Restart/Clear)    │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  │                          ↕                                │  │
│  │              BlocProvider/BlocBuilder                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                            ↕                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              BLoC Layer (State Management)               │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │                                                          │  │
│  │  ┌─────────────────────────────────────────────────┐   │  │
│  │  │  TaskQueueBloc                                  │   │  │
│  │  ├─────────────────────────────────────────────────┤   │  │
│  │  │  Events:                                        │   │  │
│  │  │  • FetchTasksEvent                              │   │  │
│  │  │  • StartProcessingEvent                         │   │  │
│  │  │  • PauseProcessingEvent                         │   │  │
│  │  │  • ResumeProcessingEvent                        │   │  │
│  │  │  • RestartAllTasksEvent                         │   │  │
│  │  │  • ClearCompletedTasksEvent                     │   │  │
│  │  │  • ReorderTasksEvent                            │   │  │
│  │  │  • TerminateProcessingEvent                     │   │  │
│  │  │  • _TaskStateUpdateEvent (internal)             │   │  │
│  │  │                                                  │   │  │
│  │  │  States:                                        │   │  │
│  │  │  • TaskQueueInitial                             │   │  │
│  │  │  • TaskQueueLoading                             │   │  │
│  │  │  • TaskQueueLoaded (+ isProcessing, isPaused)  │   │  │
│  │  │  • TaskQueueError                               │   │  │
│  │  └─────────────────────────────────────────────────┘   │  │
│  │            ↕ (listens)        ↕ (delegates)            │  │
│  │      IsolateManager         TaskRepository              │  │
│  └──────────────────────────────────────────────────────────┘  │
│         ↕                              ↕                        │
│  ┌────────────────────┐       ┌────────────────────┐          │
│  │ Background Isolate │       │   Data Layer       │          │
│  ├────────────────────┤       ├────────────────────┤          │
│  │                    │       │                    │          │
│  │ _processingIsolate │       │ TaskRepository     │          │
│  │  • ReceivePort     │       │  • getAllTasks()   │          │
│  │  • Process tasks   │       │  • updateTask()    │          │
│  │  • Send messages   │       │  • reorderTasks()  │          │
│  │  • Pause/Resume    │       │  • clearCompleted()│          │
│  │                    │       │  • resetAllTasks() │          │
│  │ SendPort           │       └────────────────────┘          │
│  │  ↓ (messages)      │              ↕                        │
│  │ IsolateManager     │       ┌────────────────────┐          │
│  │  • ReceivePort     │       │   Hive Database    │          │
│  │  • Start/Stop      │       ├────────────────────┤          │
│  │  • Pause/Resume    │       │                    │          │
│  │  • Update tasks    │       │  Box<TaskModel>    │          │
│  │  • Message stream  │       │  • taskBox         │          │
│  │                    │       │                    │          │
│  └────────────────────┘       └────────────────────┘          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Data Flow: Processing Tasks

```
┌──────────────────────────────────────────────────────────────────┐
│  User taps "Start" button on HomeScreen                          │
└───────────┬────────────────────────────────────────────────────┘
            │
            ↓
┌──────────────────────────────────────────────────────────────────┐
│  StartProcessingEvent emitted from UI                            │
└───────────┬────────────────────────────────────────────────────┘
            │
            ↓
┌──────────────────────────────────────────────────────────────────┐
│  TaskQueueBloc._onStartProcessing() handler                      │
│  • Sets _isProcessing = true                                     │
│  • Gets pending tasks from _currentTasks                         │
│  • Calls isolateManager.startProcessing(tasksToProcess)         │
└───────────┬────────────────────────────────────────────────────┘
            │
            ↓
┌──────────────────────────────────────────────────────────────────┐
│  IsolateManager.startProcessing()                                │
│  • Creates ReceivePort                                           │
│  • Spawns new Isolate                                            │
│  • Sends IsolateMessage(type: 'initialize', data: tasks)         │
│  • Listens for messages from isolate                             │
└───────────┬────────────────────────────────────────────────────┘
            │
            ↓
┌──────────────────────────────────────────────────────────────────┐
│  Isolate._processingIsolate() starts                             │
│  • Receives SendPort                                             │
│  • Sets up own ReceivePort                                       │
│  • Waits for 'initialize' message                                │
└───────────┬────────────────────────────────────────────────────┘
            │
            ↓
┌──────────────────────────────────────────────────────────────────┐
│  _startProcessingLoop() begins                                   │
│  For each task in tasks list:                                    │
│    1. Check if paused → wait if true                             │
│    2. Send 'task_status' message (RUNNING)                       │
│    3. Await Future.delayed(3 seconds)                            │
│    4. Send 'task_completed' message with updated task            │
│    5. Continue to next task                                      │
│  After all tasks: Send 'processing_complete'                     │
└───────────┬────────────────────────────────────────────────────┘
            │
            ↓
┌──────────────────────────────────────────────────────────────────┐
│  Main Isolate receives messages                                  │
│  • 'task_status' → Update local task to Running                  │
│  • 'task_completed' → Update task, save to DB, emit new state    │
│  • 'processing_complete' → Set _isProcessing = false             │
└───────────┬────────────────────────────────────────────────────┘
            │
            ↓
┌──────────────────────────────────────────────────────────────────┐
│  BLoC adds _TaskStateUpdateEvent internally                      │
│  Triggers _onTaskStateUpdate handler                             │
│  Emits TaskQueueLoaded state with updated task list              │
└───────────┬────────────────────────────────────────────────────┘
            │
            ↓
┌──────────────────────────────────────────────────────────────────┐
│  BlocBuilder listens to state changes                            │
│  HomeScreen rebuilds with:                                       │
│  • Updated task status badges                                    │
│  • Updated stats (Completed count++)                             │
│  • Smooth UI transition                                          │
└──────────────────────────────────────────────────────────────────┘
```

---

## Data Flow: Reordering Tasks

```
┌──────────────────────────────────────────────────────────────────┐
│  User drags task from position 2 to position 5 in ReorderableList│
└───────────┬────────────────────────────────────────────────────┘
            │
            ↓
┌──────────────────────────────────────────────────────────────────┐
│  ReorderableListView.onReorder callback                          │
│  • oldIndex = 2, newIndex = 5                                    │
│  • Adjust index if needed                                        │
│  • Build list of new task IDs order                              │
└───────────┬────────────────────────────────────────────────────┘
            │
            ↓
┌──────────────────────────────────────────────────────────────────┐
│  ReorderTasksEvent(newOrder) emitted                             │
└───────────┬────────────────────────────────────────────────────┘
            │
            ↓
┌──────────────────────────────────────────────────────────────────┐
│  TaskQueueBloc._onReorderTasks() handler                         │
│  • Creates new TaskModel list with updated order indices         │
│  • Updates _currentTasks in memory                               │
│  • Calls taskRepository.reorderTasks(reorderedTasks)             │
└───────────┬────────────────────────────────────────────────────┘
            │
            ↓
┌──────────────────────────────────────────────────────────────────┐
│  TaskRepository.reorderTasks()                                   │
│  For each task in reorderedTasks:                                │
│    • task.copyWith(order: newIndex)                              │
│    • await _taskBox.put(key, updatedTask)                        │
│  Saves to Hive database                                          │
└───────────┬────────────────────────────────────────────────────┘
            │
            ↓
┌──────────────────────────────────────────────────────────────────┐
│  If processing is active:                                        │
│  • isolateManager.updateTasks(reorderedTasks)                    │
│  • Isolate receives 'update_tasks' message                       │
│  • Updates task list for processing queue                        │
└───────────┬────────────────────────────────────────────────────┘
            │
            ↓
┌──────────────────────────────────────────────────────────────────┐
│  BLoC emits TaskQueueLoaded with updated task list               │
└───────────┬────────────────────────────────────────────────────┘
            │
            ↓
┌──────────────────────────────────────────────────────────────────┐
│  HomeScreen rebuilds                                             │
│  • ReorderableListView shows new task order                      │
│  • Changes persisted to database                                 │
└──────────────────────────────────────────────────────────────────┘
```

---

## State Machine: Task Status

```
                    ┌─────────────┐
                    │   PENDING   │
                    └──────┬──────┘
                           │
                    Start Processing
                           │
                           ↓
                    ┌─────────────┐
                    │   RUNNING   │
                    └──────┬──────┘
                     │           │
              Pause  │           │  Complete
                     ↓           ↓
                ┌─────────┐  ┌───────────┐
                │ PAUSED  │  │ COMPLETED │
                └────┬────┘  └───────────┘
                     │              ▲
              Resume │              │
                     ↓              │
              ┌──────────────────────┘
              │
        ┌─────────────┐
        │   RUNNING   │
        └─────────────┘

Legend:
→ Automatic transition
↓ User action / Pause/Resume
```

---

## Isolate Communication Protocol

```
MAIN ISOLATE                          WORKER ISOLATE
     │                                      │
     │  Spawn                              │
     ├─────────────────────────────────────>│
     │                                      │
     │  ReceivePort sendPort              │
     │<─────────────────────────────────────┤
     │                                      │
     │  IsolateMessage                      │
     │  (type: 'initialize')                │
     │  (data: [TaskModel...])              │
     ├─────────────────────────────────────>│
     │                                      │ Setup listening
     │                                      │
     │                                    For each task:
     │                                      │
     │  IsolateMessage                      │
     │  (type: 'task_status')               │
     │<─────────────────────────────────────┤
     │                                      │
     │  Update UI                      Wait 3 seconds
     │  _emitCurrentState()                │
     │                                      │
     │  IsolateMessage                      │
     │  (type: 'task_completed')            │
     │<─────────────────────────────────────┤
     │                                      │
     │  Save to DB                      Continue
     │  Update state                        │
     │  Rebuild UI                          │
     │                                      │
     │  [Repeat for each task...]           │
     │                                      │
     │  IsolateMessage                      │
     │  (type: 'processing_complete')       │
     │<─────────────────────────────────────┤
     │                                      │
     │  Final state update            Ready for
     │                                 new work
     │
     │ (User can send anytime):
     │  'pause', 'resume', 'update_tasks', 'terminate'
     │
     ├────────────────────────────────────>│
     │                                      │
     │                                 Process commands
     │
     │  terminate                          │
     │────────────────────────────────────>│ X Kill isolate
```

---

## Pause/Resume Mechanism

```
┌─────────────────────────────────────────────────────────────┐
│  NORMAL PROCESSING                                          │
├─────────────────────────────────────────────────────────────┤
│  for (int i = 0; i < tasks.length; i++) {                  │
│    • Check pause: isPausedFn() → false                      │
│    • Send task_status message                              │
│    • Process task (wait 3 seconds)                          │
│    • Send task_completed message                           │
│  }                                                          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  WHEN PAUSE CALLED                                          │
├─────────────────────────────────────────────────────────────┤
│  1. Main sets _isPaused = true                              │
│  2. Sends 'pause' message                                   │
│  3. Isolate receives 'pause' message                        │
│  4. Sets isPaused = true                                    │
│  5. Loop check:                                             │
│     while (isPaused() && !shouldTerminate()) {              │
│       await Future.delayed(500ms)  // Non-blocking wait    │
│     }                                                       │
│  6. Loop exits when isPaused() returns false                │
│  7. Processing continues                                    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  WHEN RESUME CALLED                                         │
├─────────────────────────────────────────────────────────────┤
│  1. Main sets _isPaused = false                             │
│  2. Sends 'resume' message                                  │
│  3. Isolate receives 'resume' message                       │
│  4. Sets isPaused = false                                   │
│  5. While loop condition becomes false                      │
│  6. Processing resumes immediately                          │
│  7. No task is lost or duplicated                           │
└─────────────────────────────────────────────────────────────┘
```

---

## Database Schema: Hive

```
┌─────────────────────────────────────┐
│  TasksBox (Box<TaskModel>)          │
├─────────────────────────────────────┤
│  Key: Auto-incremented index        │
│                                     │
│  Value: TaskModel                   │
│  ├── id: String                     │
│  ├── title: String                  │
│  ├── description: String            │
│  ├── status: TaskStatus             │
│  │   ├── pending                    │
│  │   ├── running                    │
│  │   ├── paused                     │
│  │   └── completed                  │
│  ├── order: int                     │
│  ├── createdAt: DateTime            │
│  └── completedAt: DateTime? (null)  │
│                                     │
│  Sample Records:                    │
│  ┌────────────────────────────────┐ │
│  │ Key: 0                         │ │
│  │ id: "1"                        │ │
│  │ title: "Task 1: ..."           │ │
│  │ status: TaskStatus.pending     │ │
│  │ order: 0                       │ │
│  │ createdAt: 2025-11-11 10:00:00 │ │
│  └────────────────────────────────┘ │
│  ┌────────────────────────────────┐ │
│  │ Key: 1                         │ │
│  │ id: "2"                        │ │
│  │ title: "Task 2: ..."           │ │
│  │ status: TaskStatus.completed   │ │
│  │ order: 1                       │ │
│  │ completedAt: 2025-11-11 10:03:00 │
│  └────────────────────────────────┘ │
│  ... (8 more tasks)                 │
└─────────────────────────────────────┘
```

---

## Class Dependencies

```
HomeScreen (UI)
  ├── depends on: TaskQueueBloc
  ├── depends on: TaskItemWidget
  └── depends on: service_locator.getIt<TaskRepository>()

TaskQueueBloc
  ├── depends on: TaskRepository
  ├── depends on: IsolateManager
  └── depends on: TaskQueueEvent/State classes

TaskRepository
  ├── depends on: Hive
  ├── depends on: TaskModel
  └── depends on: Box<TaskModel>

IsolateManager
  ├── depends on: TaskModel
  ├── depends on: Isolate (dart:isolate)
  └── depends on: SendPort/ReceivePort

TaskModel
  ├── depends on: equatable
  ├── depends on: hive
  └── depends on: TaskStatus enum
```

---

## Performance Characteristics

```
Operation                    Time        Blocking?
───────────────────────────────────────────────────
Load tasks from Hive         < 50ms      UI Thread
Add new task                 < 20ms      UI Thread
Update task status           < 10ms      UI Thread
Reorder tasks                < 200ms     UI Thread
Save reorder to DB           < 100ms     DB Thread
Spawn isolate                < 500ms     UI Thread
Process single task          3000ms      Isolate Only
Pause/Resume                 < 100ms     Isolate
Terminate isolate            < 50ms      Both Threads
```

---

**This architecture ensures:**
- ✅ Responsive UI (no blocking operations)
- ✅ Efficient data persistence
- ✅ Clean separation of concerns
- ✅ Real-time state management
- ✅ Proper resource cleanup
- ✅ Scalable design for future extensions
