import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ScrollController _privacyPolicyScrollController = ScrollController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String _userType = "Customer";
  bool _hasReadPrivacyPolicy = false;
  bool _privacyPolicyChecked = false;

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  int _hoveredIndex = -1;

  List<String> serviceCategories = [
    "Handyman Service",
    "Home Cleaning Service",
    "Laundry Service",
  ];

  List<bool> selectedServices = [false, false, false];

  IconData _getServiceIcon(String service) {
    switch (service) {
      case "Laundry Service":
        return Icons.local_laundry_service;
      case "Home Cleaning Service":
        return Icons.cleaning_services;
      case "Handyman Service":
        return Icons.build;
      default:
        return Icons.miscellaneous_services;
    }
  }

  List<TextSpan> _buildServiceText(String service) {
    final parts = service.split(' ');
    if (parts.length < 2) return [TextSpan(text: service)];
    return [
      TextSpan(text: parts[0] + ' ', style: TextStyle(fontWeight: FontWeight.bold)),
      TextSpan(text: parts.sublist(1).join(' ')),
    ];
  }

  TextSpan get _customerPrivacyPolicy => TextSpan(
        children: [
          TextSpan(
              text: 'SUYO Customer Privacy Policy\n\n',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          TextSpan(
              text: 'Overview\n\n',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          TextSpan(
              text:
                  'By creating an account as a Customer, you agree that SUYO may collect and use your personal information as outlined below.\n\n',
              style: TextStyle(fontSize: 14)),
          TextSpan(
              text: 'Information We Collect\n\n',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          TextSpan(
              text:
                  '- Real Name\n- Email Address\n- Device Location (for booking matching)\n- Transaction Information\n- Chat History\n\n',
              style: TextStyle(fontSize: 14)),
          TextSpan(
              text: 'How We Use Your Information\n\n',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          TextSpan(
              text:
                  'Your data is used solely to:\n- Manage your bookings\n- Match you with nearby service providers\n- Communicate updates regarding your requests\n\n',
              style: TextStyle(fontSize: 14)),
          TextSpan(
              text: 'Data Sharing\n\n',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          TextSpan(
              text:
                  'Your information will not be shared with third parties without your explicit consent.\n\n',
              style: TextStyle(fontSize: 14)),
          TextSpan(
              text: 'Your Rights\n\n',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          TextSpan(
              text:
                  'You may request to view or delete your account at any time through the profile settings in the SUYO app.\n\n',
              style: TextStyle(fontSize: 14)),
          TextSpan(
              text: 'Data Security\n\n',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          TextSpan(
              text:
                  'We implement secure practices to protect your personal information from unauthorized access or disclosure.\n\n',
              style: TextStyle(fontSize: 14)),
          TextSpan(
              text: 'Contact Us\n\n',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          TextSpan(
              text: 'For any questions or concerns, contact us at privacy@suyoapp.com\n\n',
              style: TextStyle(fontSize: 14)),
          TextSpan(
              text: 'Last updated: November 27, 2025',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
        ],
      );

  TextSpan get _serviceProviderPrivacyPolicy => TextSpan(
        children: [
          TextSpan(
              text: 'SUYO Service Provider Privacy Policy\n\n',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          TextSpan(
              text: 'Overview\n\n',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          TextSpan(
              text:
                  'By creating an account as a Service Provider, you agree that SUYO may collect and use your personal information.\n\n',
              style: TextStyle(fontSize: 14)),
          TextSpan(
              text: 'Information We Collect\n\n',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          TextSpan(
              text:
                  '- Real Name\n- Email Address\n- Device Location (for booking matching)\n- Transaction Information\n- Chat History\n\n',
              style: TextStyle(fontSize: 14)),
          TextSpan(
              text: 'How We Use Your Information\n\n',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          TextSpan(
              text:
                  'Your data is used to:\n- Match you with service requests\n- Help customers recognize your services\n- Track job performance\n\n',
              style: TextStyle(fontSize: 14)),
          TextSpan(
              text: 'Data Sharing\n\n',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          TextSpan(
              text: 'Your personal information will never be shared with third parties.\n\n',
              style: TextStyle(fontSize: 14)),
          TextSpan(
              text: 'Your Rights\n\n',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          TextSpan(
              text: 'You may delete your account or request your data anytime.\n\n',
              style: TextStyle(fontSize: 14)),
          TextSpan(
              text: 'Data Security\n\n',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          TextSpan(
              text: 'We use Firebase protections to secure your information.\n\n',
              style: TextStyle(fontSize: 14)),
          TextSpan(
              text: 'Contact Us\n\n',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          TextSpan(
              text: 'For concerns, contact privacy@suyoapp.com\n\n',
              style: TextStyle(fontSize: 14)),
          TextSpan(
              text: 'Last updated: November 27, 2025',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
        ],
      );

  void _showPrivacyPolicy() {
    bool hasScrolledToEnd = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            _privacyPolicyScrollController.addListener(() {
              if (!hasScrolledToEnd &&
                  _privacyPolicyScrollController.offset >=
                      _privacyPolicyScrollController.position.maxScrollExtent - 10) {
                hasScrolledToEnd = true;
                setDialogState(() {});
              }
            });

            return AlertDialog(
              title: Text("SUYO Privacy Policy - $_userType"),
              content: Container(
                height: 300,
                width: double.infinity,
                child: SingleChildScrollView(
                  controller: _privacyPolicyScrollController,
                  child: RichText(
                    text: _userType == "Customer"
                        ? _customerPrivacyPolicy
                        : _serviceProviderPrivacyPolicy,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: hasScrolledToEnd
                      ? () {
                          setState(() {
                            _hasReadPrivacyPolicy = true;
                            _privacyPolicyChecked = true;
                          });
                          Navigator.pop(dialogContext);
                        }
                      : null,
                  child: Text(
                    "Accept",
                    style: TextStyle(
                      color: hasScrolledToEnd ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _register() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final fullName = '$firstName $lastName';

    // Basic validation
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    if (!_privacyPolicyChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must accept the Privacy Policy')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print("Attempting to create user with email: $email");

      // 1️⃣ Create user in Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final uid = userCredential.user!.uid;

      print("User created successfully with UID: $uid");

      // 2️⃣ Prepare user profile for Firestore
      final userProfile = {
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'email': email,
        'userType': _userType,
        'createdAt': FieldValue.serverTimestamp(),
        'servicesOffered': _userType == "Service Provider"
            ? serviceCategories
                .asMap()
                .entries
                .where((e) => selectedServices[e.key])
                .map((e) => e.value)
                .toList()
            : [],
      };

      print("User profile data: $userProfile");

      // 3️⃣ Write to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set(userProfile);

      print("User profile written to Firestore successfully");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful!')),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      // Firebase Auth specific errors
      print("FirebaseAuthException caught: ${e.code} - ${e.message}");
      String message = 'Registration failed';
      if (e.code == 'email-already-in-use') message = 'Email already in use';
      else if (e.code == 'weak-password') message = 'Password is too weak';
      else if (e.code == 'invalid-email') message = 'Invalid email format';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e, stackTrace) {
      // Any other error (including Firestore permission issues)
      print("Exception caught: $e");
      print("StackTrace: $stackTrace");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Registration failed. See console logs')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _privacyPolicyScrollController.dispose();
    super.dispose();
  }

  Widget _buildTextField(
      IconData icon, String hint, TextEditingController controller) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.grey[200],
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
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: TextField(
        controller: controller,
        obscureText: isObscured,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: IconButton(
            icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600]),
            onPressed: toggleVisibility,
          ),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/SUYO_LOGO_LIGHTMODE.png', height: 100),
                SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                          text: "Create ",
                          style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFF56D16),
                              fontWeight: FontWeight.bold)),
                      TextSpan(
                          text: "an account!",
                          style: TextStyle(fontSize: 14, color: Colors.black)),
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
                    toggleVisibility: () => setState(() => _showPassword = !_showPassword)),
                SizedBox(height: 16),
                _buildPasswordField(
                    icon: Icons.lock_outline,
                    hint: "Confirm Password",
                    controller: _confirmPasswordController,
                    isObscured: !_showConfirmPassword,
                    toggleVisibility: () => setState(() => _showConfirmPassword = !_showConfirmPassword)),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _userType = "Customer";
                        _privacyPolicyChecked = false;
                        _hasReadPrivacyPolicy = false;
                      }),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: _userType == "Customer" ? Colors.white : Colors.black),
                        backgroundColor: _userType == "Customer"
                            ? Color(0xFFF56D16)
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text('Customer',
                          style: TextStyle(
                              color: _userType == "Customer" ? Colors.white : Colors.black)),
                    ),
                    SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _userType = "Service Provider";
                        _privacyPolicyChecked = false;
                        _hasReadPrivacyPolicy = false;
                      }),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: _userType == "Service Provider"
                                ? Colors.white
                                : Colors.black),
                        backgroundColor: _userType == "Service Provider"
                            ? Color(0xFFF56D16)
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text('Service Provider',
                          style: TextStyle(
                              color: _userType == "Service Provider"
                                  ? Colors.white
                                  : Colors.black)),
                    ),
                  ],
                ),
                if (_userType == "Service Provider") ...[
                  SizedBox(height: 20),
                  Text("Select the Home Services You Offer:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: Column(
                      children: List.generate(serviceCategories.length, (index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            onEnter: (_) => setState(() => _hoveredIndex = index),
                            onExit: (_) => setState(() => _hoveredIndex = -1),
                            child: Material(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.grey[200],
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () =>
                                    setState(() => selectedServices[index] = !selectedServices[index]),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: _hoveredIndex == index
                                        ? Colors.grey[300]
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(_getServiceIcon(serviceCategories[index]),
                                          color: Color(0xFFF56D16)),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                              children: _buildServiceText(
                                                  serviceCategories[index]),
                                              style: TextStyle(
                                                  fontSize: 16, color: Colors.black)),
                                        ),
                                      ),
                                      Checkbox(
                                        value: selectedServices[index],
                                        onChanged: (value) =>
                                            setState(() => selectedServices[index] = value!),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _privacyPolicyChecked,
                      activeColor: Color(0xFF4B2EFF),
                      onChanged: (value) {
                        if (value == true) _showPrivacyPolicy();
                        else
                          setState(() {
                            _privacyPolicyChecked = false;
                            _hasReadPrivacyPolicy = false;
                          });
                      },
                    ),
                    GestureDetector(
                      onTap: _showPrivacyPolicy,
                      child: Text("I agree to the SUYO $_userType Privacy Policy",
                          style: TextStyle(color: Color(0xFF4B2EFF))),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                SizedBox(
                  height: 55,
                  width: MediaQuery.of(context).size.width * 0.55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4B2EFF),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        padding: EdgeInsets.symmetric(vertical: 16)),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Register",
                            style: TextStyle(fontSize: 16, color: Colors.white)),
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
