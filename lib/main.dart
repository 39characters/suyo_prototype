import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/job_in_progress_screen.dart';
import 'screens/rating_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(SuyoApp());
}

class SuyoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SUYO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF4B2EFF),
        scaffoldBackgroundColor: Color(0xFF4B2EFF),
        fontFamily: 'Roboto',
      ),
      home: LoginScreen(),
      routes: {
        '/booking': (context) => BookingScreen(),
        '/inprogress': (context) => JobInProgressScreen(),
        '/rate': (context) => RatingScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
