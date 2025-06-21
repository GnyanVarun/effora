import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 4)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String hustleId;

  @HiveField(2)
  String title;

  @HiveField(3)
  DateTime dueDate;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  String description;

  @HiveField(7)
  bool? completed; // ✅ Add this field

  Task({
    required this.id,
    required this.hustleId,
    required this.title,
    required this.dueDate,
    required this.isCompleted,
    required this.createdAt,
    required this.description,
    this.completed = false, // ✅ Initialize the field
  });
}
