import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/expense_model.dart';
import '../../models/hustle_model.dart';
import '../../services/supabase_service.dart';
import 'add_expense_screen.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final Box<Expense> _expenseBox = Hive.box<Expense>('expenses');
  final Box<Hustle> _hustleBox = Hive.box<Hustle>('hustles');
  final SupabaseService _supabaseService = SupabaseService();

  Future<void> _navigateToAddExpense({Expense? existingExpense}) async {
    final updatedExpense = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(expense: existingExpense),
      ),
    );

    if (updatedExpense != null && updatedExpense is Expense) {
      if (existingExpense != null) {
        final key = _expenseBox.keys.firstWhere(
              (k) => _expenseBox.get(k)?.id == existingExpense.id,
          orElse: () => null,
        );
        if (key != null) await _expenseBox.put(key, updatedExpense);
      } else {
        await _expenseBox.add(updatedExpense);
      }

      await _supabaseService.upsertExpense(updatedExpense);
      setState(() {});
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      final key = _expenseBox.keys.firstWhere(
            (k) => _expenseBox.get(k)?.id == expense.id,
        orElse: () => null,
      );
      if (key != null) {
        await _expenseBox.delete(key);
        await _supabaseService.deleteExpense(expense.id);
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenses = _expenseBox.values.toList();
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddExpense(),
          ),
        ],
      ),
      body: expenses.isEmpty
          ? const Center(child: Text('No expenses yet.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ListView.builder(
              itemCount: expenses.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (_, index) {
                final expense = expenses[index];
                final hustle = _hustleBox.values.firstWhere(
                      (h) => h.id == expense.hustleId,
                  orElse: () => Hustle(
                    id: 'unknown',
                    title: 'Unknown Hustle',
                    description: '',
                    currency: '₹',
                    totalEarnings: 0.0,
                    createdAt: DateTime.now(),
                  ),
                );

                return Dismissible(
                  key: Key(expense.id),
                  background: Container(
                    color: Colors.green,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.horizontal,
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      await _navigateToAddExpense(existingExpense: expense);
                      return false;
                    } else if (direction == DismissDirection.endToStart) {
                      await _deleteExpense(expense);
                      return false;
                    }
                    return false;
                  },
                  child: ListTile(
                    title: Text(hustle.title,
                        style: textTheme.titleMedium?.copyWith(
                          color: isDark ? Colors.white : Colors.black,
                        )),
                    subtitle: Text(
                      expense.note,
                      style: textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${hustle.currency}${expense.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${expense.createdAt.day}/${expense.createdAt.month}/${expense.createdAt.year}',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Expenses by Hustle:',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._hustleBox.values.map((hustle) {
                    final hustleExpenses = _expenseBox.values
                        .where((e) => e.hustleId == hustle.id)
                        .toList();
                    final total = hustleExpenses.fold<double>(
                      0.0,
                          (sum, e) => sum + e.amount,
                    );

                    if (total == 0) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            hustle.title,
                            style: textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            '${hustle.currency}${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
