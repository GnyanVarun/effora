import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:effora/models/hustle_model.dart';
import 'package:effora/models/income_model.dart';
import 'package:effora/models/expense_model.dart';
import 'package:effora/models/task_model.dart';
import 'package:effora/ui/hustles/add_hustle_screen.dart';
import 'package:effora/services/supabase_service.dart';
import 'package:intl/intl.dart';

class HustleListScreen extends StatefulWidget {
  const HustleListScreen({super.key});

  @override
  State<HustleListScreen> createState() => _HustleListScreenState();
}

class _HustleListScreenState extends State<HustleListScreen> {
  final Box<Hustle> _hustleBox = Hive.box<Hustle>('hustles');
  final Box<Income> _incomeBox = Hive.box<Income>('incomes');
  final Box<Expense> _expenseBox = Hive.box<Expense>('expenses');
  final Box<Task> _taskBox = Hive.box<Task>('tasks');

  double _calculateTotalIncome(String hustleId) {
    return _incomeBox.values
        .where((income) => income.hustleId == hustleId)
        .fold(0.0, (sum, income) => sum + income.amount);
  }

  Future<void> _navigateToAddHustle({Hustle? existingHustle}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddHustleScreen(existingHustle: existingHustle),
      ),
    );

    if (result != null && result is Hustle) {
      final hustleBoxKey = _hustleBox.keys.firstWhere(
            (key) => _hustleBox.get(key)?.id == result.id,
        orElse: () => null,
      );

      if (hustleBoxKey != null) {
        await _hustleBox.put(hustleBoxKey, result);
      } else {
        await _hustleBox.put(result.id, result);
      }

      await SupabaseService().upsertHustle(result);
      setState(() {});
    }
  }

  Future<void> _deleteHustleAndAssociatedData(Hustle hustle) async {
    final hustleId = hustle.id;

    final incomeKeys = _incomeBox.keys
        .where((key) => _incomeBox.get(key)?.hustleId == hustleId)
        .toList();
    for (final key in incomeKeys) {
      await _incomeBox.delete(key);
    }

    final expenseKeys = _expenseBox.keys
        .where((key) => _expenseBox.get(key)?.hustleId == hustleId)
        .toList();
    for (final key in expenseKeys) {
      await _expenseBox.delete(key);
    }

    final taskKeys = _taskBox.keys
        .where((key) => _taskBox.get(key)?.hustleId == hustleId)
        .toList();
    for (final key in taskKeys) {
      await _taskBox.delete(key);
    }

    final hustleKey = _hustleBox.keys
        .firstWhere((key) => _hustleBox.get(key)?.id == hustleId, orElse: () => null);
    if (hustleKey != null) {
      await _hustleBox.delete(hustleKey);
    }

    await SupabaseService().deleteHustleAndAssociatedData(hustle.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Hustles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddHustle(),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _hustleBox.listenable(),
        builder: (context, Box<Hustle> box, _) {
          final hustles = box.values.toList();

          if (hustles.isEmpty) {
            return const Center(child: Text('No hustles yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: hustles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final hustle = hustles[index];
              final totalIncome = _calculateTotalIncome(hustle.id);

              return Dismissible(
                key: Key(hustle.id),
                direction: DismissDirection.horizontal,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.blue,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Hustle?'),
                        content: const Text(
                          'Deleting this hustle will also remove all related income, expenses, and tasks. Are you sure?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    return result ?? false;
                  } else {
                    _navigateToAddHustle(existingHustle: hustle);
                    return false;
                  }
                },
                onDismissed: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await _deleteHustleAndAssociatedData(hustle);
                  }
                },
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.work_outline, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hustle.title,
                                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hustle.description.isNotEmpty ? hustle.description : 'No description',
                                style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${hustle.currency}${totalIncome.toStringAsFixed(2)}',
                              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat.yMMMd().format(hustle.createdAt),
                              style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
