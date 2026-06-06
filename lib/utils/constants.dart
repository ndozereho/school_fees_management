import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'School Fees Management System';
  static const String schoolName = 'EXCELLENCE ACADEMY';
  static const String schoolMotto = 'School of Academic Excellence';
  static const String department = 'Accounts Department';
  static const String appVersion = '1.0.0';
  
  // Login Credentials
  static const String defaultUsername = 'admin';
  static const String defaultPassword = 'admin123';
  
  // Class Names
  static const List<String> primaryClasses = [
    'P.7', 'P.6', 'P.5', 'P.4', 'P.3', 'P.2', 'P.1'
  ];
  
  static const List<String> kindergartenClasses = [
    'TOP CLASS', 'MIDDLE CLASS', 'BABY CLASS'
  ];
  
  static const List<String> sectionTypes = ['Boarding', 'Day'];
  static const List<String> terms = ['ONE', 'TWO', 'THREE'];
  
  // Default Values
  static const String defaultTerm = 'ONE';
  static const String defaultYear = '2026';
  static const double defaultFeesStructure = 0.0;
  static const double defaultArrears = 0.0;
  
  // Ledger Number Formats
  static const Map<String, String> kgClassCodes = {
    'TOP CLASS': 'T',
    'MIDDLE CLASS': 'M',
    'BABY CLASS': 'B',
  };
  
  // Currency
  static const String currencySymbol = 'UGX';
  static const String currencyFormat = '#,###';
  
  // Date Format
  static const String dateFormatDisplay = 'dd-MMM-yyyy';
  static const String dateFormatShort = 'dd-MMM';
  static const String dateFormatDB = 'yyyy-MM-dd HH:mm:ss';
  
  // Database
  static const String dbName = 'school_fees.db';
  static const int dbVersion = 1;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double tableMinWidth = 1800.0;
  static const double headerHeight = 60.0;
  static const double dataRowHeight = 80.0;
  
  // Colors
  static const Color primaryColor = Colors.indigo;
  static const Color secondaryColor = Colors.blue;
  static const Color successColor = Colors.green;
  static const Color dangerColor = Colors.red;
  static const Color warningColor = Colors.orange;
  static const Color boardingColor = Color(0xFF1565C0);
  static const Color dayColor = Color(0xFF2E7D32);
  
  // Column Widths for Tables
  static const Map<String, double> columnWidths = {
    'ledgerNo': 120.0,
    'parentContact': 150.0,
    'reamPaid': 100.0,
    'fullName': 200.0,
    'paymentRecord': 350.0,
    'expectedFees': 130.0,
    'feesStructure': 130.0,
    'feesPaid': 130.0,
    'balance': 130.0,
    'arrears': 130.0,
    'actions': 100.0,
  };
}

class AppStyles {
  static const TextStyle headerStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  static const TextStyle titleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppConstants.primaryColor,
  );
  
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    color: Colors.grey,
  );
  
  static const TextStyle tableHeaderStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 13,
  );
  
  static const TextStyle dataStyle = TextStyle(
    fontSize: 13,
  );
  
  static const TextStyle totalStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );
  
  // Fixed: Changed from static to static getter or use withAlpha
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withAlpha(51), // 0.2 * 255 ≈ 51
        spreadRadius: 2,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static InputDecoration inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}

class AppRoutes {
  static const String login = '/';
  static const String dashboard = '/dashboard';
  static const String classSelection = '/class-selection';
  static const String classScreen = '/class-screen';
  static const String report = '/report';
}