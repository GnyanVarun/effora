import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:effora/models/hustle_model.dart';
import 'package:effora/models/expense_model.dart';
import 'package:effora/services/supabase_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;
  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Hustle? _selectedHustle;

  final Box<Hustle> _hustleBox = Hive.box<Hustle>('hustles');
  final Box<Expense> _expenseBox = Hive.box<Expense>('expenses');

  @override
  void initState() {
    super.initState();

    if (widget.expense != null) {
      final expense = widget.expense!;
      _amountController.text = expense.amount.toStringAsFixed(2);
      _noteController.text = expense.note;
      _selectedDate = expense.createdAt;
      if (_hustleBox.values.isNotEmpty) {
        _selectedHustle = _hustleBox.values.firstWhere(
              (h) => h.id == expense.hustleId,
          orElse: () => _hustleBox.values.first,
        );
      }
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate() && _selectedHustle != null) {
      final isEditing = widget.expense != null;
      final id = isEditing ? widget.expense!.id : const Uuid().v4();

      final expense = Expense(
        id: id,
        amount: double.parse(_amountController.text),
        note: _noteController.text,
        hustleId: _selectedHustle!.id,
        createdAt: _selectedDate,
      );

      if (isEditing) {
        final key = _expenseBox.keys.firstWhere(
              (k) => _expenseBox.get(k)?.id == id,
          orElse: () => null,
        );
        if (key != null) {
          await _expenseBox.put(key, expense);
        }
      } else {
        await _expenseBox.add(expense);
      }

      try {
        await SupabaseService().upsertExpense(expense);
      } catch (e) {
        debugPrint('Supabase sync failed: $e');
      }

      Navigator.pop(context, expense);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hustles = _hustleBox.values.toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense != null ? 'Edit Expense' : 'Add Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<Hustle>(
                value: _selectedHustle,
                decoration: const InputDecoration(
                  labelText: 'Select Hustle',
                  border: OutlineInputBorder(),
                ),
                items: hustles
                    .map((hustle) => DropdownMenuItem(
                  value: hustle,
                  child: Text(hustle.title),
                ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedHustle = value),
                validator: (value) => value == null ? 'Please select a hustle' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  //prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter amount' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  prefixIcon: Icon(Icons.note_alt),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text('Date: ${DateFormat.yMMMd().format(_selectedDate)}'),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: const Text('Select Date'),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(widget.expense != null ? Icons.save : Icons.add),
                  label: Text(widget.expense != null ? 'Update Expense' : 'Save Expense',),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saveExpense,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
