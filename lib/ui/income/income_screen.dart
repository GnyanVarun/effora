// Enhanced IncomeScreen with modern UI & UX

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:effora/models/income_model.dart';
import 'package:effora/models/hustle_model.dart';
import 'package:effora/services/supabase_service.dart';
import 'add_income_screen.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  late final Box<Income> _incomeBox;
  late final Box<Hustle> _hustleBox;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _incomeBox = Hive.box<Income>('incomes');
    _hustleBox = Hive.box<Hustle>('hustles');
  }

  double _calculateTotalIncome() {
    return _incomeBox.values.fold(0, (sum, income) => sum + income.amount);
  }

  String _getPrimaryCurrencySymbol() {
    if (_incomeBox.isEmpty) return '₹';
    final hustle = _hustleBox.values.firstWhere(
          (h) => h.id == _incomeBox.values.first.hustleId,
      orElse: () => Hustle(
        id: '',
        title: '',
        description: '',
        createdAt: DateTime.now(),
        totalEarnings: 0,
        currency: '₹',
      ),
    );
    return hustle.currency;
  }

  Future<void> _navigateToAddOrEditIncome({Income? existingIncome}) async {
    final updatedIncome = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddIncomeScreen(existingIncome: existingIncome),
      ),
    );

    if (updatedIncome != null && updatedIncome is Income) {
      await _incomeBox.put(updatedIncome.id, updatedIncome);
      await _supabaseService.upsertIncome(updatedIncome);

      final hustle = _hustleBox.values.firstWhere(
            (h) => h.id == updatedIncome.hustleId,
        orElse: () => Hustle(
          id: '',
          title: 'Unknown',
          description: '',
          createdAt: DateTime.now(),
          totalEarnings: 0,
          currency: '₹',
        ),
      );

      double previousAmount = existingIncome?.amount ?? 0;
      hustle.totalEarnings = (hustle.totalEarnings ?? 0) - previousAmount + updatedIncome.amount;
      await hustle.save();
      await _supabaseService.upsertHustle(hustle);

      setState(() {});
    }
  }

  Future<void> _deleteIncome(Income income) async {
    await _incomeBox.delete(income.key);
    await _supabaseService.deleteIncome(income.id);

    final hustle = _hustleBox.values.firstWhere(
          (h) => h.id == income.hustleId,
      orElse: () => Hustle(
        id: '',
        title: 'Unknown',
        description: '',
        createdAt: DateTime.now(),
        totalEarnings: 0,
        currency: '₹',
      ),
    );

    hustle.totalEarnings = (hustle.totalEarnings ?? 0) - income.amount;
    await hustle.save();
    await _supabaseService.upsertHustle(hustle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddOrEditIncome(),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _incomeBox.listenable(),
        builder: (context, Box<Income> box, _) {
          final incomes = box.values.toList();

          if (incomes.isEmpty) {
            return const Center(
              child: Text(
                'No income entries yet.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: incomes.length,
                  itemBuilder: (context, index) {
                    final income = incomes[index];
                    final hustle = _hustleBox.values.firstWhere(
                          (h) => h.id == income.hustleId,
                      orElse: () => Hustle(
                        id: '',
                        title: 'Unknown',
                        description: '',
                        createdAt: DateTime.now(),
                        totalEarnings: 0,
                        currency: '₹',
                      ),
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Slidable(
                        key: Key(income.id),
                        startActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.25,
                          children: [
                            SlidableAction(
                              onPressed: (_) => _navigateToAddOrEditIncome(existingIncome: income),
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              icon: Icons.edit,
                              label: 'Edit',
                            ),
                          ],
                        ),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.25,
                          children: [
                            SlidableAction(
                              onPressed: (_) async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete Income?'),
                                    content: const Text('Are you sure you want to delete this income entry?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm ?? false) {
                                  await _deleteIncome(income);
                                  setState(() {});
                                }
                              },
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Delete',
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          title: Text(
                            '${hustle.currency}${income.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(hustle.title),
                          trailing: Text(
                            '${income.date.day}/${income.date.month}/${income.date.year}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Income',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${_getPrimaryCurrencySymbol()}${_calculateTotalIncome().toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}