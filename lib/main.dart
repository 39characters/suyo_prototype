import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/home_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/job_in_progress_screen.dart';
import 'screens/rating_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/provider_home_screen.dart';
import 'screens/customer_pending_screen.dart';
import 'screens/provider_in_progress_screen.dart'; // ✅ Import this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(SuyoApp());
}

class SuyoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SUYO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF4B2EFF),
        scaffoldBackgroundColor: const Color(0xFF4B2EFF),
        fontFamily: 'Roboto',
      ),
      home: LoginScreen(),
      routes: {
        //'/rate': (context) => RatingScreen(),
        '/home': (context) => HomeScreen(),
        '/register': (context) => RegisterScreen(),
        '/providerHome': (context) => ProviderHomeScreen(),

        // ✅ CUSTOMER PENDING
        '/pending': (context) {
          final settings = ModalRoute.of(context)!.settings;
          final args = settings.arguments;
          if (args == null || args is! Map<String, dynamic>) {
            return const Scaffold(
              body: Center(child: Text("❌ Missing or invalid arguments for /pending")),
            );
          }
          return CustomerPendingScreen(
            provider: args['provider'],
            serviceCategory: args['serviceCategory'],
            price: (args['price'] ?? 0.0) as double,
            location: args['location'] ?? {},
            bookingId: args['bookingId'],
            customerId: args['customerId'],
          );
        },

        // ✅ CUSTOMER IN PROGRESS
        '/inprogress': (context) {
          final settings = ModalRoute.of(context)!.settings;
          final args = settings.arguments;
          if (args == null || args is! Map<String, dynamic>) {
            return const Scaffold(
              body: Center(child: Text("❌ Missing or invalid arguments for /inprogress")),
            );
          }
          return JobInProgressScreen(
            bookingId: args['bookingId'],
            provider: args['provider'],
            serviceCategory: args['serviceCategory'],
            price: (args['price'] ?? 0.0) as double,
            location: args['location'] ?? {},
            startedAt: args['startedAt']?.toString() ?? '',
            eta: args['eta']?.toString() ?? '',
          );
        },

        // ✅ PROVIDER IN PROGRESS
        '/providerInProgress': (context) {
          final settings = ModalRoute.of(context)!.settings;
          final args = settings.arguments;
          if (args == null || args is! Map<String, dynamic> || args['bookingId'] == null) {
            return const Scaffold(
              body: Center(child: Text("❌ Missing or invalid arguments for /providerInProgress")),
            );
          }
          return ProviderInProgressScreen(bookingId: args['bookingId']);
        },
      },
    );
  }
}
