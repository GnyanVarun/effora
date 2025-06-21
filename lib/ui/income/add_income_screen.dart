import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/income_model.dart';
import '../../models/hustle_model.dart';
import '../../services/supabase_service.dart';

class AddIncomeScreen extends StatefulWidget {
  final Income? existingIncome;

  const AddIncomeScreen({super.key, this.existingIncome});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _incomeBox = Hive.box<Income>('incomes');
  final _hustleBox = Hive.box<Hustle>('hustles');

  String? _selectedHustleId;
  double _amount = 0;
  String _description = '';
  DateTime _selectedDate = DateTime.now();

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.existingIncome != null) {
      final income = widget.existingIncome!;
      _selectedHustleId = income.hustleId;
      _amount = income.amount;
      _description = income.description;
      _selectedDate = income.date;

      _amountController.text = _amount.toStringAsFixed(2);
      _descriptionController.text = _description;
    }
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final income = Income(
      id: widget.existingIncome?.id ?? const Uuid().v4(),
      hustleId: _selectedHustleId!,
      amount: _amount,
      description: _description,
      date: _selectedDate,
      note: widget.existingIncome?.note ?? '',
    );

    final hustle = _hustleBox.values.firstWhere((h) => h.id == income.hustleId);

    if (widget.existingIncome != null) {
      await _incomeBox.put(income.id, income);
      hustle.totalEarnings = (hustle.totalEarnings ?? 0) - widget.existingIncome!.amount + _amount;
    } else {
      await _incomeBox.put(income.id, income);
      hustle.totalEarnings = (hustle.totalEarnings ?? 0) + _amount;
    }

    await hustle.save();

    try {
      await SupabaseService().upsertIncome(income);
    } catch (e) {
      debugPrint("❌ Supabase sync failed: $e");
    }

    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hustles = _hustleBox.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingIncome != null ? 'Edit Income' : 'Add Income'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedHustleId,
                    decoration: const InputDecoration(
                      labelText: 'Select Hustle',
                      border: OutlineInputBorder(),
                    ),
                    items: hustles.map((hustle) {
                      return DropdownMenuItem(
                        value: hustle.id,
                        child: Text(hustle.title),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedHustleId = value),
                    validator: (value) => value == null ? 'Please select a hustle' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                     // prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => _amount = double.tryParse(value ?? '') ?? 0,
                    validator: (value) =>
                    (value == null || value.isEmpty) ? 'Enter amount' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note_alt),
                    ),
                    onSaved: (value) => _description = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Date: ${DateFormat.yMMMd().format(_selectedDate)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2022),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveIncome,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(widget.existingIncome != null ? 'Update Income' : 'Save Income'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
