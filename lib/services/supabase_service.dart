import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:effora/models/hustle_model.dart';
import 'package:hive/hive.dart';
import 'package:effora/models/income_model.dart';
import 'package:effora/models/expense_model.dart';
import 'package:effora/models/task_model.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  Future<void> upsertHustle(Hustle hustle) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[upsertHustle] User not logged in');
      return;
    }

    final hustleData = {
      'id': hustle.id,
      'title': hustle.title,
      'description': hustle.description,
      'created_at': hustle.createdAt.toIso8601String(),
      'currency': hustle.currency,
      'total_earning': hustle.totalEarnings ?? 0.0,
      'user_id': userId,
    };

    try {
      final response = await _client.from('hustles').upsert(hustleData).select();
      debugPrint('[upsertHustle] Response: $response');
    } catch (e) {
      debugPrint('[upsertHustle] Error: $e');
    }
  }

  Future<void> syncHustlesFromSupabase() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final response = await _client
        .from('hustles')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final hustleBox = Hive.box<Hustle>('hustles');

    for (final item in response) {
      if (!hustleBox.containsKey(item['id'])) {
        final hustle = Hustle(
          id: item['id'],
          title: item['title'] ?? '',
          description: item['description'] ?? '',
          createdAt: DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
          totalEarnings: (item['total_earning'] as num?)?.toDouble() ?? 0.0,
          currency: item['currency'] ?? '₹',
        );

        await hustleBox.put(hustle.id, hustle);
      }
    }
  }

  Future<void> syncIncomesFromSupabase() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final response = await _client.from('incomes').select().eq('user_id', userId);

    final incomeBox = Hive.box<Income>('incomes');

    for (final item in response) {
      if (!incomeBox.containsKey(item['id'])) {
        final income = Income(
          id: item['id'],
          hustleId: item['hustle_id'],
          amount: (item['amount'] as num).toDouble(),
          date: DateTime.parse(item['date']),
          description: item['description'] ?? '',
          note: item['note'] ?? '',
        );
        await incomeBox.put(income.id, income);
      }
    }
  }

  Future<void> syncExpensesFromSupabase() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final response = await _client.from('expenses').select().eq('user_id', userId);

    final expenseBox = Hive.box<Expense>('expenses');

    for (final item in response) {
      if (!expenseBox.containsKey(item['id'])) {
        final expense = Expense(
          id: item['id'],
          hustleId: item['hustle_id'],
          amount: (item['amount'] as num).toDouble(),
          createdAt: DateTime.parse(item['created_at']),
          note: item['note'] ?? '',
        );
        await expenseBox.put(expense.id, expense);
      }
    }
  }

  Future<void> syncTasksFromSupabase() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final response = await _client.from('tasks').select().eq('user_id', userId);

    final taskBox = Hive.box<Task>('tasks');

    for (final item in response) {
      if (!taskBox.containsKey(item['id'])) {
        final task = Task(
          id: item['id'],
          hustleId: item['hustle_id'],
          title: item['title'],
          description: item['description'] ?? '',
          isCompleted: item['is_completed'] ?? false,
          completed: item['completed'] ?? false,
          dueDate: DateTime.tryParse(item['due_date'] ?? '') ?? DateTime.now(),
          createdAt: DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
        );
        await taskBox.put(task.id, task);
      }
    }
  }

  Future<void> upsertIncome(Income income) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final incomeData = {
      'id': income.id,
      'hustle_id': income.hustleId,
      'amount': income.amount,
      'date': income.date.toIso8601String(),
      'note': income.note,
      'description': income.description,
      'user_id': userId,
    };

    await _client.from('incomes').upsert(incomeData);
  }

  Future<void> upsertExpense(Expense expense) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final expenseData = {
      'id': expense.id,
      'hustle_id': expense.hustleId,
      'amount': expense.amount,
      'created_at': expense.createdAt.toIso8601String(),
      'note': expense.note,
      'user_id': userId,
    };

    await _client.from('expenses').upsert(expenseData);
  }

  Future<void> upsertTask(Task task) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final taskData = {
      'id': task.id,
      'hustle_id': task.hustleId,
      'title': task.title,
      'due_date': task.dueDate.toIso8601String(),
      'is_completed': task.isCompleted,
      'created_at': task.createdAt.toIso8601String(),
      'description': task.description,
      'completed': task.completed ?? false,
      'user_id': userId,
    };

    await _client.from('tasks').upsert(taskData);
  }

  Future<void> deleteTask(String taskId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('tasks').delete().eq('id', taskId).eq('user_id', userId);
  }

  Future<void> deleteHustle(String hustleId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('hustles').delete().eq('id', hustleId).eq('user_id', userId);
  }

  Future<void> deleteHustleAndAssociatedData(String hustleId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from('incomes').delete().match({
        'hustle_id': hustleId,
        'user_id': userId,
      });

      await _client.from('expenses').delete().match({
        'hustle_id': hustleId,
        'user_id': userId,
      });

      await _client.from('tasks').delete().match({
        'hustle_id': hustleId,
        'user_id': userId,
      });

      await _client.from('hustles').delete().match({
        'id': hustleId,
        'user_id': userId,
      });
    } catch (e) {
      print('Error while deleting hustle and related data: $e');
    }
  }

  Future<void> deleteIncome(String incomeId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('incomes').delete().eq('id', incomeId).eq('user_id', userId);
  }

  Future<void> deleteExpense(String expenseId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('expenses').delete().eq('id', expenseId).eq('user_id', userId);
  }

  Future<void> syncAllLocalToSupabase() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final hustleBox = Hive.box<Hustle>('hustles');
    final incomeBox = Hive.box<Income>('incomes');
    final expenseBox = Hive.box<Expense>('expenses');
    final taskBox = Hive.box<Task>('tasks');

    for (final hustle in hustleBox.values) {
      await upsertHustle(hustle);
    }

    for (final income in incomeBox.values) {
      await upsertIncome(income);
    }

    for (final expense in expenseBox.values) {
      await upsertExpense(expense);
    }

    for (final task in taskBox.values) {
      await upsertTask(task);
    }

    debugPrint('✅ All local data synced to Supabase');
  }

  Future<void> syncFromSupabaseToHive() async {
    await syncHustlesFromSupabase();
    await syncIncomesFromSupabase();
    await syncExpensesFromSupabase();
    await syncTasksFromSupabase();
  }

  Future<void> syncAllExistingHiveData() async {
    final hustleBox = Hive.box<Hustle>('hustles');
    final incomeBox = Hive.box<Income>('incomes');
    final expenseBox = Hive.box<Expense>('expenses');
    final taskBox = Hive.box<Task>('tasks');

    for (final hustle in hustleBox.values) {
      await upsertHustle(hustle);
    }

    for (final income in incomeBox.values) {
      await upsertIncome(income);
    }

    for (final expense in expenseBox.values) {
      await upsertExpense(expense);
    }

    for (final task in taskBox.values) {
      await upsertTask(task);
    }
    debugPrint("✅ All existing Hive data synced to Supabase.");
  }
}
