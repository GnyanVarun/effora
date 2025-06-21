import 'package:hive/hive.dart';
import 'income_model.dart'; // ✅ Make sure this is imported

part 'hustle_model.g.dart';

@HiveType(typeId: 0)
class Hustle extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  double? totalEarnings; // ✅ Keep for now (required for old data)

  @HiveField(5)
  final String currency;

  Hustle({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.totalEarnings = 0.0, // Still supported
    this.currency = '₹',
  });

  // ✅ Dynamic computed earnings (does not interfere with Hive)
  double get computedEarnings {
    final incomeBox = Hive.box<Income>('income');
    final hustleIncomes = incomeBox.values.where((i) => i.hustleId == id);
    return hustleIncomes.fold(0.0, (sum, i) => sum + i.amount);
  }
}
