import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  GoogleMapController? _mapController;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String _userType = "Customer";
  String? _selectedServiceCategory;
  bool _hasReadPrivacyPolicy = false;
  bool _privacyPolicyChecked = false;
  ScrollController _privacyPolicyScrollController = ScrollController();

  final List<String> _serviceCategories = [
    'Laundry Service',
    'House Cleaning',
    'Errands',
  ];

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  LatLng? _selectedLocation;

  bool get _isBusinessNameRequired {
    return _userType == "Service Provider" &&
        (_selectedServiceCategory == "Laundry Service" || _selectedServiceCategory == "House Cleaning");
  }

  bool get _needsLocationPin {
    return _userType == "Service Provider" &&
        (_selectedServiceCategory == "Laundry Service" || _selectedServiceCategory == "House Cleaning");
  }

  Future<void> _pickLocationOnMap() async {
    LatLng defaultCenter = const LatLng(14.5995, 120.9842);
    LatLng tempSelected = _selectedLocation ?? defaultCenter;

    void _onMapCreated(GoogleMapController controller) async {
      _mapController = controller;
      String style = await rootBundle.loadString('assets/map_style.json');
      _mapController!.setMapStyle(style);
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Pick your Business Location',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(target: tempSelected, zoom: 15),
                  onCameraMove: (position) => tempSelected = position.target,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                Align(
                  alignment: Alignment.center,
                  child: Icon(Icons.location_on, size: 48, color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _selectedLocation = tempSelected);
                Navigator.pop(context);
              },
              child: const Text("Confirm Location", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF56D16),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicy() {
    bool hasScrolledToEnd = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Use StatefulBuilder to manage state within the dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
            _privacyPolicyScrollController.addListener(() {
              if (_privacyPolicyScrollController.position.pixels >=
                  _privacyPolicyScrollController.position.maxScrollExtent - 10) {
                setDialogState(() {
                  hasScrolledToEnd = true;
                });
              }
            });

            return AlertDialog(
              title: Text('SUYO Privacy Policy - $_userType'),
              content: Container(
                width: double.maxFinite,
                height: 300,
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
                  onPressed: () {
                    setState(() {
                      _privacyPolicyChecked = false;
                      _hasReadPrivacyPolicy = false;
                    });
                    Navigator.pop(dialogContext);
                  },
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
                      color: hasScrolledToEnd ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Dispose the listener when dialog is closed to prevent memory leaks
      _privacyPolicyScrollController.removeListener(() {});
    });
  }

  void _register() async {
    if (!_privacyPolicyChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please read and accept the privacy policy")),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    if (_userType == "Service Provider") {
      if (_selectedServiceCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select a service category")),
        );
        return;
      }

      if (_isBusinessNameRequired && _businessNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter your business name")),
        );
        return;
      }

      if (!_isBusinessNameRequired &&
          (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter your full name")),
        );
        return;
      }

      if (_needsLocationPin && _selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please set your business location")),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      final Map<String, dynamic> userProfile = {
        'email': _emailController.text.trim(),
        'userType': _userType,
        'createdAt': Timestamp.now(),
      };

      if (_userType == "Customer") {
        userProfile['firstName'] = _firstNameController.text.trim();
        userProfile['lastName'] = _lastNameController.text.trim();
      } else if (_userType == "Service Provider") {
        userProfile['serviceCategory'] = _selectedServiceCategory;
        userProfile['rating'] = 0.0;
        userProfile['ratingCount'] = 0;

        if (_isBusinessNameRequired) {
          userProfile['businessName'] = _businessNameController.text.trim();
        } else {
          userProfile['firstName'] = _firstNameController.text.trim();
          userProfile['lastName'] = _lastNameController.text.trim();
        }

        if (_needsLocationPin && _selectedLocation != null) {
          userProfile['location'] = {
            'lat': _selectedLocation!.latitude,
            'lng': _selectedLocation!.longitude,
          };
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(userProfile);

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
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _businessNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _privacyPolicyScrollController.dispose();
    super.dispose();
  }

  Widget _buildTextField(IconData icon, String hint, TextEditingController controller) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
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
            icon: Icon(
              isObscured ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
            onPressed: toggleVisibility,
          ),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  TextSpan get _customerPrivacyPolicy => TextSpan(
        children: [
          TextSpan(
            text: 'SUYO Customer Privacy Policy\n\n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          TextSpan(
            text: 'Overview\n\n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          TextSpan(
            text: 'By creating an account as a Customer, you agree that SUYO may collect and use your personal information as outlined below.\n\n',
            style: TextStyle(fontSize: 14),
          ),
          TextSpan(
            text: 'Information We Collect\n\n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          TextSpan(
            text: '- Name\n- Email address\n- Phone number\n- Home address (including saved booking locations)\n- Device location (for booking matching)\n\n',
            style: TextStyle(fontSize: 14),
          ),
          TextSpan(
            text: 'How We Use Your Information\n\n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          TextSpan(
            text: 'Your data is used solely to:\n- Manage your bookings\n- Match you with nearby service providers\n- Communicate updates regarding your requests\n\n',
            style: TextStyle(fontSize: 14),
          ),
          TextSpan(
            text: 'Data Sharing\n\n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          TextSpan(
            text: 'Your information will not be shared with third parties without your explicit consent.\n\n',
            style: TextStyle(fontSize: 14),
          ),
          TextSpan(
            text: 'Your Rights\n\n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          TextSpan(
            text: 'You may request to view or delete your account at any time through the profile settings in the SUYO app.\n\n',
            style: TextStyle(fontSize: 14),
          ),
          TextSpan(
            text: 'Data Security\n\n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          TextSpan(
            text: 'We implement secure practices to protect your personal information from unauthorized access or disclosure.\n\n',
            style: TextStyle(fontSize: 14),
          ),
          TextSpan(
            text: 'Contact Us\n\n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          TextSpan(
            text: 'For any questions or concerns about this policy, please contact us at privacy@suyoapp.com.\n\n',
            style: TextStyle(fontSize: 14),
          ),
          TextSpan(
            text: 'Last updated: July 23, 2025',
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
        ],
      );

  TextSpan get _serviceProviderPrivacyPolicy => TextSpan(
        children: [
          TextSpan(
            text: 'SUYO Service Provider Privacy Policy\n\n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          TextSpan(
            text: 'Overview\n\n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          TextSpan(
            text: 'By creating an account as a Service Provider, you agree that SUYO may collect and use your personal information as outlined below.\n\n',
            style: TextStyle(fontSize: 14),
          ),
          TextSpan(
            text: 'Information We Collect\n\n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          TextSpan(
            text: '- Business Name (or Real Name if individual)\n- Email address\n- Phone number\n- Coverage area / work location\n- Booking history\n\n',
            style: TextStyle(fontSize: 14),
          ),
          TextSpan(
            text: 'How We Use Your Information\n\n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          TextSpan(
            text: 'Your data is used to:\n- Match you with service requests\n- Help customers recognize and book your services\n- Track completed jobs and job performance\n\n',
            style: TextStyle(fontSize: 14),
          ),
          TextSpan(
            text: 'Data Sharing\n\n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          TextSpan(
            text: 'Your personal data will remain private and will not be shared with other providers or third parties.\n\n',
            style: TextStyle(fontSize: 14),
          ),
          TextSpan(
            text: 'Your Rights\n\n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          TextSpan(
            text: 'You can access or delete your account and data at any time through the app settings.\n\n',
            style: TextStyle(fontSize: 14),
          ),
          TextSpan(
            text: 'Data Security\n\n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          TextSpan(
            text: 'SUYO applies data security measures using Firebase protections to safeguard your information.\n\n',
            style: TextStyle(fontSize: 14),
          ),
          TextSpan(
            text: 'Contact Us\n\n',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          TextSpan(
            text: 'For any questions or concerns about this policy, please contact us at privacy@suyoapp.com.\n\n',
            style: TextStyle(fontSize: 14),
          ),
          TextSpan(
            text: 'Last updated: July 23, 2025',
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
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
                      TextSpan(text: "Create ", style: TextStyle(fontSize: 14, color: Color(0xFFF56D16), fontWeight: FontWeight.bold)),
                      TextSpan(text: "an account!", style: TextStyle(fontSize: 14, color: Colors.black)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ...[
                  if (_userType == "Customer" || (_userType == "Service Provider" && !_isBusinessNameRequired)) ...[
                    _buildTextField(Icons.person_outline, "First Name", _firstNameController),
                    const SizedBox(height: 16),
                    _buildTextField(Icons.person_outline, "Last Name", _lastNameController),
                  ] else
                    _buildTextField(Icons.store_mall_directory_outlined, "Business Name", _businessNameController),
                ],
                const SizedBox(height: 16),
                _buildTextField(Icons.email_outlined, "Email", _emailController),
                const SizedBox(height: 16),
                _buildPasswordField(
                  icon: Icons.lock_outline,
                  hint: "Password",
                  controller: _passwordController,
                  isObscured: !_showPassword,
                  toggleVisibility: () => setState(() => _showPassword = !_showPassword),
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  icon: Icons.lock_outline,
                  hint: "Confirm Password",
                  controller: _confirmPasswordController,
                  isObscured: !_showConfirmPassword,
                  toggleVisibility: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _userType = "Customer";
                          _selectedServiceCategory = null;
                          _privacyPolicyChecked = false;
                          _hasReadPrivacyPolicy = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _userType == "Customer" ? Colors.white : Colors.black),
                        backgroundColor: _userType == "Customer" ? Color(0xFFF56D16) : Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text('Customer', style: TextStyle(color: _userType == "Customer" ? Colors.white : Colors.black)),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _userType = "Service Provider";
                          _privacyPolicyChecked = false;
                          _hasReadPrivacyPolicy = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _userType == "Service Provider" ? Colors.white : Colors.black),
                        backgroundColor: _userType == "Service Provider" ? Color(0xFFF56D16) : Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text('Service Provider', style: TextStyle(color: _userType == "Service Provider" ? Colors.white : Colors.black)),
                    ),
                  ],
                ),
                if (_userType == "Service Provider") ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 12.0),
                          child: Icon(Icons.business_center, color: Colors.grey),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      dropdownColor: Colors.grey[200],
                      iconEnabledColor: Colors.grey,
                      style: TextStyle(color: Colors.black, fontSize: 16),
                      value: _selectedServiceCategory,
                      hint: Text("Select Service Category", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      onChanged: (value) => setState(() => _selectedServiceCategory = value),
                      items: _serviceCategories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category, style: TextStyle(fontSize: 16)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (_needsLocationPin) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickLocationOnMap,
                    icon: Icon(Icons.location_pin, color: Colors.white),
                    label: Text(
                      _selectedLocation == null ? 'Set Location' : 'Change Location',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF56D16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _privacyPolicyChecked,
                      onChanged: (value) {
                        if (value == true) {
                          _showPrivacyPolicy();
                        } else {
                          setState(() {
                            _privacyPolicyChecked = false;
                            _hasReadPrivacyPolicy = false;
                          });
                        }
                      },
                    ),
                    GestureDetector(
                      onTap: _showPrivacyPolicy,
                      child: Text(
                        "I agree to the SUYO ${_userType} Privacy Policy",
                        style: TextStyle(color: Color(0xFF4B2EFF)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  width: MediaQuery.of(context).size.width * 0.55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Register", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4B2EFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text.rich(
                    TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: "Login",
                          style: TextStyle(color: Color(0xFFF56D16), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
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