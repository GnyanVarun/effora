import 'package:hive/hive.dart';

part 'income_model.g.dart';

@HiveType(typeId: 1)
class Income extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String hustleId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String note;

  @HiveField(5)
  final String description;

  Income({
    required this.id,
    required this.hustleId,
    required this.amount,
    required this.date,
    required this.note, required this.description,
    //this.completed = false, // ✅ Initialize the field
  });
}
