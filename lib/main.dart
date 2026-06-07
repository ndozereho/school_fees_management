import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/school_data_provider.dart';
import 'screens/login_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sqflite for Windows desktop
  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Initialize the database and load data
  final schoolDataProvider = SchoolDataProvider();
  await schoolDataProvider.loadAllData();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: schoolDataProvider),
      ],
      child: const SchoolFeesApp(),
    ),
  );
}

class SchoolFeesApp extends StatelessWidget {
  const SchoolFeesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Fees Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: const CardTheme(
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
),
      ),
      home: const LoginScreen(),
    );
  }
}
