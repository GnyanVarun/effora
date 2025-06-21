import 'package:hive/hive.dart';
import 'package:effora/models/income_model.dart';
import 'package:effora/models/expense_model.dart';
import 'package:effora/models/hustle_model.dart';


Map<String, double> getMonthlyExpenses(Box<Expense> expenseBox) {
  final Map<String, double> monthlyData = {};
  for (var expense in expenseBox.values) {
    final key = "${expense.createdAt.year}-${expense.createdAt.month.toString().padLeft(2, '0')}";
    monthlyData[key] = (monthlyData[key] ?? 0) + expense.amount;
  }
  return Map.fromEntries(monthlyData.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key)));
}

Map<String, double> getMonthlyIncome(Box<Income> incomeBox) {
  final Map<String, double> monthlyData = {};

  for (var income in incomeBox.values) {
    final date = income.date;
    final key = "${date.year}-${date.month.toString().padLeft(2, '0')}";

    monthlyData[key] = (monthlyData[key] ?? 0) + income.amount;
  }

  return Map.fromEntries(
    monthlyData.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
}

Map<String, double> getIncomeVsExpenseTotals({
  required Box<Income> incomeBox,
  required Box<Expense> expenseBox,
}) {
  double totalIncome = 0;
  double totalExpense = 0;

  for (var income in incomeBox.values) {
    totalIncome += income.amount;
  }

  for (var expense in expenseBox.values) {
    totalExpense += expense.amount;
  }

  return {
    'Income': totalIncome,
    'Expenses': totalExpense,
  };
}

Map<String, double> getIncomePerHustle(Box<Income> incomeBox, Box<Hustle> hustleBox) {
  final hustleMap = {
    for (var hustle in hustleBox.values) hustle.id: hustle.title,
  };

  final Map<String, double> incomeMap = {};

  for (final income in incomeBox.values) {
    final hustleTitle = hustleMap[income.hustleId];
    if (hustleTitle == null) continue;

    incomeMap[hustleTitle] = (incomeMap[hustleTitle] ?? 0) + income.amount;
  }

  return incomeMap;
}





