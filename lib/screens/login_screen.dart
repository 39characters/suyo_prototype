import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _showPassword = false; // ✅ added this for toggle

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData == null || !userData.containsKey('userType')) {
          throw Exception('Your account is registered but missing profile data. Contact support.');
        }

        final userType = userData['userType'];
        if (userType == 'Customer') {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (userType == 'Service Provider') {
          Navigator.pushReplacementNamed(context, '/providerHome');
        } else {
          throw Exception('Unknown user type: $userType');
        }
      } else {
        throw Exception('No matching profile found. Please register first.');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Wrong credentials. Please try again.';
      if (e.code == 'user-not-found') message = 'No user found with that email.';
      if (e.code == 'wrong-password') message = 'Incorrect password.';
      _showErrorSnackbar(message);
    } catch (e) {
      _showErrorSnackbar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInputValid = _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/SUYO_LOGO_LIGHTMODE.png', height: 100),
                const SizedBox(height: 12),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(text: "Need help? ", style: TextStyle(fontSize: 14, color: Colors.black)),
                      TextSpan(
                        text: "We got you.",
                        style: TextStyle(fontSize: 14, color: Color(0xFFF56D16), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // EMAIL FIELD
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                      hintText: "Email",
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // PASSWORD FIELD with TOGGLE
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey[600],
                        ),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                      hintText: "Password",
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: const Color(0xFF4B2EFF),
                            onChanged: (value) => setState(() => _rememberMe = value ?? false),
                          ),
                          const Text("Remember Me", style: TextStyle(color: Colors.black)),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text("Forgot Password?", style: TextStyle(color: Colors.blue)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // LOGIN BUTTON
                SizedBox(
                  height: 55,
                  width: MediaQuery.of(context).size.width * 0.55,
                  child: ElevatedButton(
                    onPressed: (!_isLoading && isInputValid) ? _login : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4B2EFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Login", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),

                const SizedBox(height: 24),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(text: "Don't have an account? ", style: TextStyle(color: Colors.black)),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/register'),
                          child: const Text(
                            "Create an account",
                            style: TextStyle(
                              color: Color(0xFFF56D16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
