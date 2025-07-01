import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ← newly generated file

import 'screens/home_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/job_in_progress_screen.dart';
import 'screens/rating_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/provider_home_screen.dart';
import 'screens/pending_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // ← required for web & all platforms
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
        primaryColor: Color(0xFF4B2EFF),
        scaffoldBackgroundColor: Color(0xFF4B2EFF),
        fontFamily: 'Roboto',
      ),
      home: LoginScreen(),
      routes: {
        '/rate': (context) => RatingScreen(),
        '/home': (context) => HomeScreen(),
        '/register': (context) => RegisterScreen(),
        '/providerHome': (context) => ProviderHomeScreen(),
        '/inprogress': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

          return JobInProgressScreen(
            bookingId: args['bookingId'],
            provider: args['provider'],
            serviceCategory: args['serviceCategory'],
            price: args['price'],
            startedAt: args['startedAt'],
            eta: args['eta'],
          );
        }
      },
    );
    
  }
}
