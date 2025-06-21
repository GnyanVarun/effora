import 'package:flutter/material.dart';
import 'package:effora/models/hustle_model.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../services/supabase_service.dart';

class AddHustleScreen extends StatefulWidget {
  final Hustle? existingHustle;

  const AddHustleScreen({super.key, this.existingHustle});

  @override
  State<AddHustleScreen> createState() => _AddHustleScreenState();
}

class _AddHustleScreenState extends State<AddHustleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCurrency = '₹';

  final List<Map<String, String>> _currencyOptions = [
    {'symbol': '₹', 'label': 'INR'},
    {'symbol': '\$', 'label': 'USD'},
    {'symbol': '€', 'label': 'EUR'},
    {'symbol': '£', 'label': 'GBP'},
    {'symbol': '¥', 'label': 'JPY'},
    {'symbol': '₩', 'label': 'KRW'},
    {'symbol': '₽', 'label': 'RUB'},
    {'symbol': '฿', 'label': 'THB'},
    {'symbol': '₫', 'label': 'VND'},
    {'symbol': '₪', 'label': 'ILS'},
    {'symbol': '₱', 'label': 'PHP'},
    {'symbol': 'R\$', 'label': 'BRL'},
    {'symbol': '₦', 'label': 'NGN'},
    {'symbol': 'C\$', 'label': 'CAD'},
    {'symbol': 'A\$', 'label': 'AUD'},
    {'symbol': 'CHF', 'label': 'CHF'},
    {'symbol': 'kr', 'label': 'SEK'},
    {'symbol': '₺', 'label': 'TRY'},
    {'symbol': 'د.إ', 'label': 'AED'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingHustle != null) {
      _titleController.text = widget.existingHustle!.title;
      _descriptionController.text = widget.existingHustle!.description;
      _selectedCurrency = widget.existingHustle!.currency;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveHustle() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    final hustle = Hustle(
      id: widget.existingHustle?.id ?? const Uuid().v4(),
      title: title,
      description: description,
      createdAt: widget.existingHustle?.createdAt ?? DateTime.now(),
      currency: _selectedCurrency,
    );

    final hustleBox = Hive.box<Hustle>('hustles');

    if (widget.existingHustle != null) {
      final key = hustleBox.keys.firstWhere((k) => hustleBox.get(k)?.id == hustle.id);
      await hustleBox.put(key, hustle);
    } else {
      await hustleBox.put(hustle.id, hustle);
    }

    try {
      await SupabaseService().upsertHustle(hustle);
      debugPrint('✅ Supabase Hustle synced successfully');
    } catch (e) {
      debugPrint('❌ Supabase sync failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hustle saved locally but sync failed.')),
      );
    }

    Navigator.pop(context, hustle);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingHustle != null;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Hustle' : 'Add Hustle'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveHustle,
        icon: const Icon(Icons.save),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        label: Text(isEditing ? 'Update' : 'Save'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Hustle Title',
                  prefixIcon: Icon(Icons.work_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  //prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCurrency,
                    isExpanded: true,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCurrency = value);
                      }
                    },
                    items: _currencyOptions.map((currency) {
                      return DropdownMenuItem<String>(
                        value: currency['symbol'],
                        child: Text('${currency['symbol']} ${currency['label']}'),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
