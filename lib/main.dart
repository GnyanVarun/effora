import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:app_links/app_links.dart';
import 'dart:async';

// Models
import 'models/hustle_model.dart';
import 'models/income_model.dart';
import 'models/expense_model.dart';
import 'models/task_model.dart';

// Screens
import 'ui/dashboard/dashboard_screen.dart';
import 'ui/hustles/hustle_list_screen.dart';
import 'ui/income/income_screen.dart';
import 'ui/expenses/expense_screen.dart';
import 'ui/tasks/task_screen.dart';
import 'ui/reports/report_screen.dart';
import 'login_screen.dart';
import 'sign_up_screen.dart';
import 'settings_screen.dart';
import 'reset_password_screen.dart'; // ✅ Make sure this file exists

// Theme
import 'package:effora/core/theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(HustleAdapter());
  Hive.registerAdapter(IncomeAdapter());
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(TaskAdapter());

  await Hive.openBox<Hustle>('hustles');
  await Hive.openBox<Income>('incomes');
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Task>('tasks');
  await Hive.openBox('preferences');

  await Supabase.initialize(
    url: 'https://loenyzpsglpwdwidcwaw.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvZW55enBzZ2xwd2R3aWRjd2F3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5ODU0MjIsImV4cCI6MjA2NTU2MTQyMn0.7SSTohQsHDT5AUq2lfxJi_H88zT7_kD5Ohi-ysm7cgQ',
  );

  tz.initializeTimeZones();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  runApp(const EfforaApp());
}

class EfforaApp extends StatefulWidget {
  const EfforaApp({super.key});

  @override
  State<EfforaApp> createState() => _EfforaAppState();
}

class _EfforaAppState extends State<EfforaApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('⚡ Deep link received: $uri');
      final uriStr = uri.toString();

      if (uri.scheme == 'effora' && uri.host == 'reset-password') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.pushNamed('/reset-password', arguments: uri);
        });
      } else if (uri.scheme == 'effora' && uri.host == 'login') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (r) => false);
        });
      } else {
        debugPrint('🔹 Deep link ignored.');
      }
    }, onError: (err) {
      debugPrint('Deep link error: $err');
    });
  }


  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferencesBox = Hive.box('preferences');

    return ValueListenableBuilder(
      valueListenable: preferencesBox.listenable(),
      builder: (context, box, _) {
        final isDark = box.get('darkMode', defaultValue: false);

        return MaterialApp(
          title: 'Effora',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          navigatorKey: navigatorKey,
          initialRoute: Supabase.instance.client.auth.currentUser == null
              ? '/login'
              : '/home',
          routes: {
            '/login': (_) => const LoginScreen(),
            '/signup': (_) => const SignUpScreen(),
            '/home': (_) => const HomeScreen(),
            '/settings': (_) => const SettingsScreen(),
            '/reset-password': (_) => const ResetPasswordScreen(), // ✅ Route added
          },
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const HustleListScreen(),
    const IncomeScreen(),
    const ExpenseScreen(),
    const TaskScreen(task: null),
    const ReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.teal,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Hustles'),
          BottomNavigationBarItem(
              icon: Icon(Icons.attach_money), label: 'Income'),
          BottomNavigationBarItem(
              icon: Icon(Icons.money_off), label: 'Expenses'),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_box), label: 'Tasks'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Reports'),
        ],
      ),
    );
  }
}
