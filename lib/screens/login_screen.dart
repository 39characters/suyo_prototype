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
  bool _showPassword = false;

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
      _showErrorDialog(message);
    } catch (e) {
      _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Login Error"),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B2EFF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/SUYO_LOGIN_ART.png', height: 280),
                const SizedBox(height: 24),
                Image.asset('assets/images/SUYO_LOGO.png', height: 100),
                const SizedBox(height: 12),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(text: "Need help? ", style: TextStyle(fontSize: 14, color: Colors.white)),
                      TextSpan(
                        text: "We got you.",
                        style: TextStyle(fontSize: 14, color: Color(0xFFF56D16), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: _buildTextField(
                      icon: Icons.person_outline,
                      hint: "Email",
                      obscure: false,
                      controller: _emailController,
                    ),
                  ),

                const SizedBox(height: 16),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: _buildTextField(
                      icon: Icons.lock_outline,
                      hint: "Password",
                      obscure: true,
                      controller: _passwordController,
                    ),
                  ),
                
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) => setState(() => _rememberMe = value ?? false),
                        ),
                        const Text("Remember Me", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text("Forgot Password?", style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  width: MediaQuery.of(context).size.width * 0.55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF56D16),
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
                      const TextSpan(text: "Don't have an account? ", style: TextStyle(color: Colors.white)),
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
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required IconData icon,
    required String hint,
    required bool obscure,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure ? !_showPassword : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 12.0),
          child: Icon(icon, color: const Color(0xFFF56D16)),
        ),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF3A22CC),
        suffixIcon: obscure
            ? Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFFC7C7C7).withOpacity(0.65),
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
