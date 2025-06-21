import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:effora/models/hustle_model.dart';
import 'package:effora/models/task_model.dart';
import 'package:effora/services/supabase_service.dart';
import 'package:effora/utils/notification_helper.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? taskToEdit;

  const AddTaskScreen({super.key, this.taskToEdit});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isCompleted = false;
  Hustle? _selectedHustle;

  final Box<Hustle> _hustleBox = Hive.box<Hustle>('hustles');
  final Box<Task> _taskBox = Hive.box<Task>('tasks');

  @override
  void initState() {
    super.initState();

    if (widget.taskToEdit != null) {
      _titleController.text = widget.taskToEdit!.title;
      _selectedDate = widget.taskToEdit!.dueDate;
      _isCompleted = widget.taskToEdit!.isCompleted;

      _selectedHustle = _hustleBox.values.firstWhere(
            (h) => h.id == widget.taskToEdit!.hustleId,
        orElse: () => Hustle(
          id: 'unknown',
          title: 'Unknown Hustle',
          description: '',
          currency: '₹',
          totalEarnings: 0.0,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate() && _selectedHustle != null) {
      final isEditing = widget.taskToEdit != null;

      final newTask = Task(
        id: widget.taskToEdit?.id ?? const Uuid().v4(),
        hustleId: _selectedHustle!.id,
        title: _titleController.text.trim(),
        dueDate: _selectedDate,
        isCompleted: _isCompleted,
        createdAt: widget.taskToEdit?.createdAt ?? DateTime.now(),
        description: '',
      );

      try {
        int? notificationId;

        if (isEditing) {
          final index = _taskBox.values.toList().indexWhere((t) => t.id == widget.taskToEdit!.id);
          if (index == -1) throw Exception("Original task not found");
          final key = _taskBox.keyAt(index);
          await _taskBox.put(key, newTask);

          if (key is int) {
            notificationId = key;
            await flutterLocalNotificationsPlugin.cancel(notificationId);
          }
        } else {
          final newKey = await _taskBox.add(newTask);
          if (newKey is int) {
            notificationId = newKey;
          }
        }

        if (notificationId != null) {
          await scheduleTaskNotification(
            id: notificationId,
            title: newTask.title,
            scheduledTime: newTask.dueDate,
          );
        }

        await SupabaseService().upsertTask(newTask);
        Navigator.pop(context, newTask);
      } catch (e, stack) {
        debugPrint('❌ Task Save Error: $e');
        debugPrint('🔍 Stacktrace: $stack');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save task')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hustles = _hustleBox.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskToEdit != null ? 'Edit Task' : 'Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<Hustle>(
                decoration: const InputDecoration(
                  labelText: 'Select Hustle',
                  border: OutlineInputBorder(),
                ),
                value: _selectedHustle,
                items: hustles.map((hustle) {
                  return DropdownMenuItem<Hustle>(
                    value: hustle,
                    child: Text(hustle.title),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedHustle = value),
                validator: (value) => value == null ? 'Please select a hustle' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter task title' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Due: ${DateFormat.yMMMd().format(_selectedDate)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Pick Date'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _isCompleted,
                onChanged: (value) =>
                    setState(() => _isCompleted = value ?? false),
                title: const Text('Mark as Completed'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveTask,
                icon: const Icon(Icons.save),
                label: Text(widget.taskToEdit != null ? 'Update Task' : 'Save Task'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
