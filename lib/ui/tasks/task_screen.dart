import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:effora/models/task_model.dart';
import 'package:effora/models/hustle_model.dart';
import 'package:effora/ui/tasks/add_task_screen.dart';
import 'package:effora/services/supabase_service.dart';
import 'package:effora/utils/notification_helper.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key, required Task? task});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final Box<Task> _taskBox = Hive.box<Task>('tasks');
  final Box<Hustle> _hustleBox = Hive.box<Hustle>('hustles');
  final Box _prefsBox = Hive.box('preferences');

  Hustle? _selectedHustleFilter;
  bool _showOnlyPending = false;

  @override
  void initState() {
    super.initState();
    _showOnlyPending = _prefsBox.get('showOnlyPending', defaultValue: false);
  }

  List<Task> get _filteredTasks {
    var tasks = _taskBox.values.toList();
    if (_selectedHustleFilter != null) {
      tasks = tasks.where((task) => task.hustleId == _selectedHustleFilter!.id).toList();
    }
    if (_showOnlyPending) {
      tasks = tasks.where((task) => !task.isCompleted).toList();
    }
    return tasks;
  }

  Future<void> _navigateToAddTask({Task? taskToEdit}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddTaskScreen(taskToEdit: taskToEdit)),
    );
    if (result is Task) {
      setState(() {});
    }
  }

  void _deleteTask(Task task) async {
    final key = _taskBox.keys.firstWhere((k) => _taskBox.get(k)?.id == task.id);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      await _taskBox.delete(key);
      await flutterLocalNotificationsPlugin.cancel(key as int);
      await SupabaseService().deleteTask(task.id);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted and reminder cancelled')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hustles = _hustleBox.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showFilterDialog(hustles),
            tooltip: 'Filters',
          ),
        ],
      ),
      body: _filteredTasks.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt_outlined, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No tasks found', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Try changing the filter or adding new tasks.'),
          ],
        ),
      )
          : ListView.separated(
        itemCount: _filteredTasks.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (context, index) {
          final task = _filteredTasks[index];
          final hustle = _hustleBox.values.firstWhere(
                (h) => h.id == task.hustleId,
            orElse: () => Hustle(
              id: 'unknown',
              title: 'Unknown',
              currency: '',
              totalEarnings: 0,
              createdAt: DateTime.now(),
              description: '',
            ),
          );

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              title: Text(task.title, style: theme.textTheme.titleMedium),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14),
                      const SizedBox(width: 4),
                      Text(DateFormat.yMMMd().format(task.dueDate)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.work_outline, size: 14),
                      const SizedBox(width: 4),
                      Text(hustle.title),
                    ],
                  ),
                ],
              ),
              leading: Checkbox(
                value: task.isCompleted,
                onChanged: (value) {
                  final key = _taskBox.keys.firstWhere((k) => _taskBox.get(k)?.id == task.id);
                  _taskBox.put(
                    key,
                    Task(
                      id: task.id,
                      hustleId: task.hustleId,
                      title: task.title,
                      dueDate: task.dueDate,
                      isCompleted: value ?? false,
                      createdAt: task.createdAt,
                      description: task.description,
                    ),
                  );
                  setState(() {});
                },
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                    onPressed: () => _navigateToAddTask(taskToEdit: task),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteTask(task),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddTask(),
        label: const Text('Add Task'),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterDialog(List<Hustle> hustles) {
    Hustle? tempHustle = _selectedHustleFilter;
    bool tempPending = _showOnlyPending;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Filter Tasks'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Hustle>(
                  decoration: const InputDecoration(labelText: 'Filter by Hustle'),
                  value: tempHustle,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Hustles')),
                    ...hustles.map((h) => DropdownMenuItem(value: h, child: Text(h.title))),
                  ],
                  onChanged: (value) {
                    setModalState(() => tempHustle = value);
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Show only pending tasks'),
                  value: tempPending,
                  onChanged: (value) => setModalState(() => tempPending = value),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedHustleFilter = tempHustle;
                    _showOnlyPending = tempPending;
                    _prefsBox.put('showOnlyPending', tempPending); // Save to Hive
                  });
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

}
