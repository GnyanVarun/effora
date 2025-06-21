import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import 'package:effora/models/expense_model.dart';
import 'package:effora/models/income_model.dart';
import 'package:effora/models/hustle_model.dart';
import 'package:effora/utils/report_utils.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseBox = Hive.box<Expense>('expenses');
    final incomeBox = Hive.box<Income>('incomes');
    final hustleBox = Hive.box<Hustle>('hustles');

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ValueListenableBuilder(
          valueListenable: expenseBox.listenable(),
          builder: (context, Box<Expense> eBox, _) {
            return ValueListenableBuilder(
              valueListenable: incomeBox.listenable(),
              builder: (context, Box<Income> iBox, _) {
                return ValueListenableBuilder(
                  valueListenable: hustleBox.listenable(),
                  builder: (context, Box<Hustle> hBox, _) {
                    final currencySymbol = hBox.isNotEmpty ? hBox.values.first.currency : '₹';

                    final monthlyIncome = getMonthlyIncome(iBox);
                    final monthlyExpenses = getMonthlyExpenses(eBox);
                    final incomePerHustle = getIncomePerHustle(iBox, hBox);

                    final allMonths = {
                      ...monthlyIncome.keys,
                      ...monthlyExpenses.keys,
                    }.toList()
                      ..sort((a, b) => a.compareTo(b));

                    final totalIncome = monthlyIncome.values.fold(0.0, (a, b) => a + b);
                    final totalExpense = monthlyExpenses.values.fold(0.0, (a, b) => a + b);

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                            child: Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 3,
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Total Income'),
                                        Text(
                                          '$currencySymbol${totalIncome.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Total Expenses'),
                                        Text(
                                          '$currencySymbol${totalExpense.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          chartCard(
                            title: "Monthly Income vs Expenses",
                            chart: groupedBarChart(allMonths, monthlyIncome, monthlyExpenses, currencySymbol),
                            legend: legendRow({
                              Colors.green: 'Income',
                              Colors.red: 'Expenses',
                            }),
                          ),
                          chartCard(
                            title: "Monthly Income",
                            chart: singleBarChart(monthlyIncome, Colors.green, currencySymbol),
                            legend: legendBarDetails(monthlyIncome, currencySymbol),
                          ),
                          chartCard(
                            title: "Monthly Expenses",
                            chart: singleBarChart(monthlyExpenses, Colors.red, currencySymbol),
                            legend: legendBarDetails(monthlyExpenses, currencySymbol),
                          ),
                          chartCard(
                            title: "Income per Hustle",
                            chart: singleBarChart(incomePerHustle, Colors.blue, currencySymbol, isLabelText: true),
                            legend: legendBarDetails(incomePerHustle, currencySymbol),
                          ),
                          chartCard(
                            title: "Income vs Expense Breakdown",
                            chart: AspectRatio(
                              aspectRatio: 1.5,
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      value: totalIncome,
                                      title: 'Income',
                                      color: Colors.green,
                                      radius: 60,
                                      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      titlePositionPercentageOffset: 1.2,
                                    ),
                                    PieChartSectionData(
                                      value: totalExpense,
                                      title: 'Expenses',
                                      color: Colors.red,
                                      radius: 60,
                                      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      titlePositionPercentageOffset: 1.2,
                                    ),
                                  ],
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 40,
                                ),
                              ),
                            ),
                            legend: legendRow({
                              Colors.green: 'Income',
                              Colors.red: 'Expenses',
                            }),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget chartCard({required String title, required Widget chart, required Widget legend}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: chart,
              ),
              const SizedBox(height: 16),
              legend,
            ],
          ),
        ),
      ),
    );
  }

  Widget groupedBarChart(List<String> months, Map<String, double> incomeMap, Map<String, double> expenseMap, String currency) {
    return AspectRatio(
      aspectRatio: 1.4,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, _) {
                  if (value % 1000 == 0) {
                    return Text("$currency${value.toInt()}", style: const TextStyle(fontSize: 10));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  int index = value.toInt();
                  if (index < months.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('MMM').format(DateFormat('yyyy-MM').parse(months[index])),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(months.length, (i) {
            final month = months[i];
            return BarChartGroupData(
              x: i,
              barsSpace: 8,
              barRods: [
                BarChartRodData(toY: incomeMap[month] ?? 0, color: Colors.green, width: 12, borderRadius: BorderRadius.circular(4)),
                BarChartRodData(toY: expenseMap[month] ?? 0, color: Colors.red, width: 12, borderRadius: BorderRadius.circular(4)),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget singleBarChart(Map<String, double> data, Color color, String currency, {bool isLabelText = false}) {
    final keys = data.keys.toList();
    final values = data.values.toList();

    return AspectRatio(
      aspectRatio: 1.4,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, _) {
                  if (value % 1000 == 0) {
                    return Text("$currency${value.toInt()}", style: const TextStyle(fontSize: 10));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  int index = value.toInt();
                  if (index < keys.length) {
                    final rawLabel = keys[index];
                    if (isLabelText) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(rawLabel, style: const TextStyle(fontSize: 10)),
                      );
                    } else {
                      try {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('MMM').format(DateFormat('yyyy-MM').parse(rawLabel)),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      } catch (_) {
                        return const Text('');
                      }
                    }
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(keys.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(toY: values[i], color: color, width: 14, borderRadius: BorderRadius.circular(4)),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget legendRow(Map<Color, String> items) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items.entries.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: e.key, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(e.value),
          ],
        );
      }).toList(),
    );
  }

  Widget legendBarDetails(Map<String, double> data, String currency) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: data.entries.map((entry) {
        try {
          final formatted = DateFormat('MMM yyyy').format(DateFormat('yyyy-MM').parse(entry.key));
          return Text("$formatted – $currency${entry.value.toStringAsFixed(2)}");
        } catch (_) {
          return Text("${entry.key} – $currency${entry.value.toStringAsFixed(2)}");
        }
      }).toList(),
    );
  }
}