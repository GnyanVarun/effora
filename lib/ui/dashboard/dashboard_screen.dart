import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:effora/models/hustle_model.dart';
import 'package:effora/models/income_model.dart';
import 'package:effora/models/expense_model.dart';
import 'package:effora/models/task_model.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../tasks/task_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  String? _username;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUsernameAndAvatar();
  }

  Future<void> _loadUsernameAndAvatar() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('user_preferences')
          .select('username, profile_image_url')
          .eq('user_id', user.id)
          .maybeSingle();

      setState(() {
        _username = response?['username'] ?? '';
        _avatarUrl = response?['profile_image_url'];
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final hustleBox = Hive.box<Hustle>('hustles');
    final incomeBox = Hive.box<Income>('incomes');
    final expenseBox = Hive.box<Expense>('expenses');
    final taskBox = Hive.box<Task>('tasks');

    final now = DateTime.now();

    final hustleEarnings = hustleBox.values.map((hustle) {
      final hustleIncome = incomeBox.values
          .where((i) => i.hustleId == hustle.id)
          .fold(0.0, (sum, i) => sum + i.amount);
      return {'hustle': hustle, 'total': hustleIncome};
    }).toList()
      ..sort((a, b) =>
          (b['total'] as double? ?? 0.0).compareTo(a['total'] as double? ?? 0.0));

    final topHustle = hustleEarnings.isNotEmpty ? hustleEarnings.first : null;
    final currency = topHustle != null
        ? (topHustle['hustle'] as Hustle).currency
        : '₹';

    final totalIncome = incomeBox.values.fold(0.0, (a, b) => a + b.amount);
    final totalExpenses = expenseBox.values.fold(0.0, (a, b) => a + b.amount);
    final netProfit = totalIncome - totalExpenses;

    final totalTasks = taskBox.values.length;
    final completedTasks = taskBox.values.where((t) => t.isCompleted).length;
    final pendingTasks = totalTasks - completedTasks;

    double sumForMonth(DateTime date) {
      return incomeBox.values
          .where((i) => i.date.year == date.year && i.date.month == date.month)
          .fold(0.0, (a, b) => a + b.amount);
    }

    final currentMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);
    final currentIncome = sumForMonth(currentMonth);
    final previousIncome = sumForMonth(lastMonth);

    String earningsLabel;
    IconData trendIcon;
    Color trendColor;

    if (previousIncome == 0 && currentIncome == 0) {
      earningsLabel = "No earnings this or last month";
      trendIcon = Icons.remove;
      trendColor = Colors.grey;
    } else if (previousIncome == 0 && currentIncome > 0) {
      earningsLabel = "Earnings started this month";
      trendIcon = Icons.trending_up;
      trendColor = Colors.green;
    } else {
      final incomeDiff = currentIncome - previousIncome;
      final percentChange = (incomeDiff / previousIncome) * 100;
      final isUp = percentChange >= 0;

      earningsLabel =
      "${percentChange.abs().toStringAsFixed(1)}% ${isUp ? "up" : "down"} from last month";
      trendIcon = isUp ? Icons.trending_up : Icons.trending_down;
      trendColor = isUp ? Colors.green : Colors.red;
    }

    final upcomingTasks = taskBox.values
        .where((t) => !t.isCompleted)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(context, '/settings');
              _loadUsernameAndAvatar();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: _avatarUrl != null
                    ? NetworkImage(_avatarUrl!)
                    : NetworkImage(
                  'https://api.dicebear.com/7.x/adventurer/png?seed=${_username ?? "effora"}',
                ),
              ),
            ),
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLight
                ? [Colors.white, Colors.grey.shade100]
                : [Colors.grey.shade900, Colors.black],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_username != null && _username!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      "${_getGreeting()}, $_username 👋",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isLight ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ],
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _summaryCard("Total Income", "$currency${totalIncome.toStringAsFixed(2)}", Icons.attach_money, Colors.green, isLight),
                    _summaryCard("Total Expenses", "$currency${totalExpenses.toStringAsFixed(2)}", Icons.money_off, Colors.red, isLight),
                    _summaryCard("Net Profit", "$currency${netProfit.toStringAsFixed(2)}", Icons.stacked_line_chart, netProfit >= 0 ? Colors.teal : Colors.red, isLight),
                    _summaryCard("Pending Tasks", "$pendingTasks", Icons.pending_actions, Colors.orange, isLight),
                    _summaryCard("Completed Tasks", "$completedTasks", Icons.check_circle, Colors.teal, isLight),
                    _summaryCard("Total Hustles", "${hustleBox.length}", Icons.work_outline, Colors.blue, isLight),
                  ],
                ),
                const SizedBox(height: 24),
                if (topHustle != null)
                  _highlightCard(
                    "Top Hustle of the Month",
                    (topHustle['hustle'] as Hustle).title,
                    "$currency${(topHustle['total'] as double).toStringAsFixed(2)} earned",
                    Icons.emoji_events,
                    Colors.orange,
                    isLight,
                  ),
                const SizedBox(height: 20),
                _highlightCard(
                  "Earnings Trend",
                  "$currency${currentIncome.toStringAsFixed(2)}",
                  earningsLabel,
                  trendIcon,
                  trendColor,
                  isLight,
                ),
                const SizedBox(height: 20),
                if (upcomingTasks.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Upcoming Tasks",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isLight ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...upcomingTasks.take(3).map((task) => Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(task.title,
                          style: TextStyle(
                              color: isLight ? Colors.black : Colors.white)),
                      subtitle: Text(
                          "Due: ${DateFormat.yMMMd().format(task.dueDate)}",
                          style: TextStyle(
                              color: isLight ? Colors.black : Colors.white70)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskScreen(task: task),
                          ),
                        );
                      },
                    ),
                  )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color,
      bool isLight) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: isLight ? Colors.black87 : Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isLight ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _highlightCard(
      String title,
      String value,
      String subtitle,
      IconData icon,
      Color iconColor,
      bool isLight) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isLight ? Colors.black : Colors.white)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: isLight ? Colors.black54 : Colors.white70)),
                ],
              ),
            ),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isLight ? Colors.black : Colors.white)),
          ],
        ),
      ),
    );
  }
}
