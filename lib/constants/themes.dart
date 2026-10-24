import 'package:flutter/material.dart';

const Color seedColor = Color(0xFF1685FF);

ThemeData lightMode = ThemeData(
  useMaterial3: true,
  fontFamily: 'Linotte',
  brightness: Brightness.light,
  scaffoldBackgroundColor:
      ColorScheme.fromSeed(brightness: Brightness.light, seedColor: seedColor)
          .surface,
  colorScheme: ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
  ),
  pageTransitionsTheme: PageTransitionsTheme(
    builders: {
      for (var platform in TargetPlatform.values)
        platform: const CupertinoPageTransitionsBuilder(),
    },
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black),
    titleLarge: TextStyle(
        color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
    bodySmall: TextStyle(color: Colors.white, fontSize: 12),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade300,
    hintStyle: TextStyle(color: Colors.grey.shade600),
    prefixIconColor: Colors.grey.shade700,
    suffixIconColor: Colors.grey.shade700,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: seedColor,
    textTheme: ButtonTextTheme.primary,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: seedColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  ),
  iconTheme: const IconThemeData(
    color: Colors.black,
    size: 24,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: seedColor,
    foregroundColor: Colors.white,
  ),
);

ThemeData darkMode = ThemeData(
  useMaterial3: true,
  fontFamily: 'Linotte',
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF07111F),
  colorScheme: ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
    surface: const Color(0xFF0B1626),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF142236),
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFF24364D), width: 0.6),
    ),
  ),
  dividerColor: const Color(0xFF1C2B40),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFF142236),
    selectedColor: const Color(0xFF1685FF),
    side: const BorderSide(color: Color(0xFF24364D)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    labelStyle: const TextStyle(color: Color(0xFFE7ECF5)),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
    titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    bodySmall: TextStyle(
        color: Colors.grey, fontSize: 12), // Updated to a lighter color
  ),
  pageTransitionsTheme: PageTransitionsTheme(
    builders: {
      for (var platform in TargetPlatform.values)
        platform: const CupertinoPageTransitionsBuilder(),
    },
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF142236),
    hintStyle: TextStyle(color: Colors.grey.shade400),
    prefixIconColor: Colors.grey.shade500,
    suffixIconColor: Colors.grey.shade500,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: seedColor,
    textTheme: ButtonTextTheme.primary,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: seedColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  ),
  iconTheme: const IconThemeData(
    color: Colors.white,
    size: 24,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: seedColor,
    foregroundColor: Colors.white,
  ),
);
