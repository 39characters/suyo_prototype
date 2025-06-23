import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF4B2EFF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/SUYO_LOGIN_ART.png',
                  height: 280,
                ),
                SizedBox(height: 24),
                Image.asset(
                  'assets/images/SUYO_LOGO.png',
                  height: 100,
                ),
                SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Need help? ",
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      TextSpan(
                        text: "We got you.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFF56D16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                _buildTextField(
                  icon: Icons.person_outline,
                  hint: "Email",
                  obscure: false,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  icon: Icons.lock_outline,
                  hint: "Password",
                  obscure: true,
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(value: false, onChanged: (_) {}),
                        Text("Remember Me", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Example: Navigator.pushReplacementNamed(context, '/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF56D16),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text("Login", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
                SizedBox(height: 24),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: "Create an account",
                        style: TextStyle(color: Color(0xFFF56D16)),
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
  }) {
    return TextField(
      obscureText: obscure,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Color(0xFFF56D16)),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Color(0xFF3A22CC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
