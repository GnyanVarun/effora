import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 2)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String hustleId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime createdAt; // ✅ Rename this from 'date' to 'createdAt'

  @HiveField(4)
  final String note; // ✅ Rename this from 'description' to 'note'

  Expense({
    required this.id,
    required this.hustleId,
    required this.amount,
    required this.createdAt,
    required this.note,
  });
}
