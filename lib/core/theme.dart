import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.teal,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.teal,
    foregroundColor: Colors.white,
    elevation: 1,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black54),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStatePropertyAll(Colors.teal),
    trackColor: MaterialStatePropertyAll(Colors.tealAccent),
  ),
  cardTheme: const CardTheme(
    color: Colors.white,
    elevation: 2,
    margin: EdgeInsets.all(8),
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.teal,
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    elevation: 1,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStatePropertyAll(Colors.tealAccent),
    trackColor: MaterialStatePropertyAll(Colors.white24),
  ),
  cardTheme: const CardTheme(
    color: Color(0xFF1E1E1E),
    elevation: 2,
    margin: EdgeInsets.all(8),
  ),
);
