import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

// Pages
import 'pages/add_person_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/find_person_page.dart';
import 'pages/login_page.dart';
import 'pages/my_reports_page.dart';
import 'pages/profile_page.dart';
import 'pages/report_missing_page.dart';
import 'pages/signup_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const PersonFinderApp());
}

class PersonFinderApp extends StatelessWidget {
  const PersonFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Person Finder',

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),

      // Login page opens first
      home: const LoginPage(),

      routes: {
        // Authentication
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),

        // Main application
        '/dashboard': (context) => const DashboardPage(),

        // Person pages
        '/find': (context) => const FindPersonPage(),
        '/add': (context) => AddPersonPage(),
        '/report': (context) => const ReportMissingPage(),
        '/reports': (context) => const MyReportsPage(),

        // Profile
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}