import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String _userType = "Customer";

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  void _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'userType': _userType,
        'createdAt': Timestamp.now(),
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Account created! Please log in.")),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
                Image.asset('assets/images/SUYO_LOGIN_ART.png', height: 180),
                SizedBox(height: 24),
                Image.asset('assets/images/SUYO_LOGO.png', height: 60),
                SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 16),
                    children: [
                      TextSpan(
                        text: "Create ",
                        style: TextStyle(color: Color(0xFFF56D16), fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: "an account!",
                        style: TextStyle(color: Color(0xFFC7C7C7)),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                _buildTextField(Icons.person_outline, "First Name", _firstNameController),
                SizedBox(height: 16),
                _buildTextField(Icons.person_outline, "Last Name", _lastNameController),
                SizedBox(height: 16),
                _buildTextField(Icons.email_outlined, "Email", _emailController),
                SizedBox(height: 16),
                _buildPasswordField(
                  icon: Icons.lock_outline,
                  hint: "Password",
                  controller: _passwordController,
                  isObscured: !_showPassword,
                  toggleVisibility: () => setState(() => _showPassword = !_showPassword),
                ),
                SizedBox(height: 16),
                _buildPasswordField(
                  icon: Icons.lock_outline,
                  hint: "Confirm Password",
                  controller: _confirmPasswordController,
                  isObscured: !_showConfirmPassword,
                  toggleVisibility: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: Text('Customer'),
                      selected: _userType == "Customer",
                      onSelected: (selected) => setState(() => _userType = "Customer"),
                      selectedColor: Color(0xFFF56D16),
                      labelStyle: TextStyle(color: Colors.white),
                      backgroundColor: Color(0xFF3A22CC),
                    ),
                    SizedBox(width: 12),
                    ChoiceChip(
                      label: Text('Service Provider'),
                      selected: _userType == "Service Provider",
                      onSelected: (selected) => setState(() => _userType = "Service Provider"),
                      selectedColor: Color(0xFFF56D16),
                      labelStyle: TextStyle(color: Colors.white),
                      backgroundColor: Color(0xFF3A22CC),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF56D16),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Register", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
                SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: "Already have an account? ", style: TextStyle(color: Colors.white)),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            "Login",
                            style: TextStyle(color: Color(0xFFF56D16), fontWeight: FontWeight.bold),
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

  Widget _buildTextField(IconData icon, String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
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

  Widget _buildPasswordField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    required bool isObscured,
    required VoidCallback toggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscured,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Color(0xFFF56D16)),
        suffixIcon: IconButton(
          icon: Icon(
            isObscured ? Icons.visibility_off : Icons.visibility,
            color: Color(0xFFC7C7C7).withOpacity(0.65),
          ),
          onPressed: toggleVisibility,
        ),
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
