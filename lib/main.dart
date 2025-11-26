import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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
      home: InternetGate(child: PermissionGate(child: LoginScreen())),

      routes: {
        '/home': (context) => InternetGate(child: PermissionGate(child: HomeScreen())),
        '/register': (context) => InternetGate(child: PermissionGate(child: RegisterScreen())),
        '/providerHome': (context) => InternetGate(child: PermissionGate(child: ProviderHomeScreen())),
        '/login': (context) => LoginScreen(),
        '/pending': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return args == null
              ? const Scaffold(body: Center(child: Text("❌ Missing or invalid arguments for /pending")))
              : InternetGate(
                  child: PermissionGate(
                    child: CustomerPendingScreen(
                      provider: args['provider'],
                      serviceCategory: args['serviceCategory'],
                      price: (args['price'] ?? 0.0) as double,
                      location: args['location'] ?? {},
                      bookingId: args['bookingId'],
                      customerId: args['customerId'],
                    ),
                  ),
                );
        },

        '/inprogress': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return args == null
              ? const Scaffold(body: Center(child: Text("❌ Missing or invalid arguments for /inprogress")))
              : InternetGate(
                  child: PermissionGate(
                    child: JobInProgressScreen(
                      bookingId: args['bookingId'],
                      provider: args['provider'],
                      serviceCategory: args['serviceCategory'],
                      price: (args['price'] ?? 0.0) as double,
                      location: args['location'] ?? {},
                      startedAt: args['startedAt']?.toString() ?? '',
                      eta: args['eta']?.toString() ?? '',
                    ),
                  ),
                );
        },

        '/providerInProgress': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return args == null || args['bookingId'] == null
              ? const Scaffold(body: Center(child: Text("❌ Missing or invalid arguments for /providerInProgress")))
              : InternetGate(
                  child: PermissionGate(
                    child: ProviderInProgressScreen(bookingId: args['bookingId']),
                  ),
                );
        },

        '/rate': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return args == null
              ? const Scaffold(body: Center(child: Text("❌ Missing or invalid arguments for /rate")))
              : InternetGate(
                  child: PermissionGate(
                    child: RatingScreen(
                      bookingId: args['bookingId'],
                      provider: args['provider'],
                      serviceCategory: args['serviceCategory'],
                      price: (args['price'] ?? 0.0) as double,
                    ),
                  ),
                );
        },

        '/rate_customer': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return args == null
              ? const Scaffold(body: Center(child: Text("❌ Missing or invalid arguments for /rate_customer")))
              : InternetGate(
                  child: PermissionGate(
                    child: RateCustomerScreen(
                      bookingId: args['bookingId'],
                      customer: args['customer'],
                      serviceCategory: args['serviceCategory'],
                      price: (args['price'] ?? 0.0) as double,
                    ),
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

class PermissionGate extends StatefulWidget {
  final Widget child;
  const PermissionGate({super.key, required this.child});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool _granted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }

    setState(() {
      _granted = status.isGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _granted
        ? widget.child
        : Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_off, size: 70, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    "Location Permission Denied",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Please enable location access to continue.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _checkPermissions,
                    child: const Text("Try Again"),
                  ),
                ],
              ),
            ),
          );
  }
}
