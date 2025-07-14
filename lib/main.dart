import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/job_in_progress_screen.dart';
import 'screens/rating_screen.dart';
import 'screens/rate_customer_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/provider_home_screen.dart';
import 'screens/customer_pending_screen.dart';
import 'screens/provider_in_progress_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SuyoApp());
}

class SuyoApp extends StatelessWidget {
  const SuyoApp({super.key});

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
      home: InternetGate(child: LoginScreen()),

      routes: {
        '/home': (context) => InternetGate(child: HomeScreen()),
        '/register': (context) => InternetGate(child: RegisterScreen()),
        '/providerHome': (context) => InternetGate(child: ProviderHomeScreen()),

        '/pending': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return args == null
              ? const Scaffold(body: Center(child: Text("❌ Missing or invalid arguments for /pending")))
              : InternetGate(
                  child: CustomerPendingScreen(
                    provider: args['provider'],
                    serviceCategory: args['serviceCategory'],
                    price: (args['price'] ?? 0.0) as double,
                    location: args['location'] ?? {},
                    bookingId: args['bookingId'],
                    customerId: args['customerId'],
                  ),
                );
        },

        '/inprogress': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return args == null
              ? const Scaffold(body: Center(child: Text("❌ Missing or invalid arguments for /inprogress")))
              : InternetGate(
                  child: JobInProgressScreen(
                    bookingId: args['bookingId'],
                    provider: args['provider'],
                    serviceCategory: args['serviceCategory'],
                    price: (args['price'] ?? 0.0) as double,
                    location: args['location'] ?? {},
                    startedAt: args['startedAt']?.toString() ?? '',
                    eta: args['eta']?.toString() ?? '',
                  ),
                );
        },

        '/providerInProgress': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return args == null || args['bookingId'] == null
              ? const Scaffold(body: Center(child: Text("❌ Missing or invalid arguments for /providerInProgress")))
              : InternetGate(
                  child: ProviderInProgressScreen(bookingId: args['bookingId']),
                );
        },

        '/rate': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return args == null
              ? const Scaffold(body: Center(child: Text("❌ Missing or invalid arguments for /rate")))
              : InternetGate(
                  child: RatingScreen(
                    bookingId: args['bookingId'],
                    provider: args['provider'],
                    serviceCategory: args['serviceCategory'],
                    price: (args['price'] ?? 0.0) as double,
                  ),
                );
        },

        '/rate_customer': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return args == null
              ? const Scaffold(body: Center(child: Text("❌ Missing or invalid arguments for /rate_customer")))
              : InternetGate(
                  child: RateCustomerScreen(
                    bookingId: args['bookingId'],
                    customer: args['customer'],
                    serviceCategory: args['serviceCategory'],
                    price: (args['price'] ?? 0.0) as double,
                  ),
                );
        },
      },
    );
  }
}

class InternetGate extends StatefulWidget {
  final Widget child;
  const InternetGate({super.key, required this.child});

  @override
  State<InternetGate> createState() => _InternetGateState();
}

class _InternetGateState extends State<InternetGate> {
  bool _connected = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _connected = result != ConnectivityResult.none;
      });
    });
  }

  Future<void> _checkConnection() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _connected = result != ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _connected ? widget.child : const NoInternetScreen();
  }
}

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.wifi_off, size: 70, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              "No Internet Connection",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),
            Text(
              "Please check your network and try again.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
