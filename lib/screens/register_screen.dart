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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
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
                      child: Icon(Icons.location_on, size: 48, color: Color(0xFFF56D16)),
                    ),
                  ],
                ),
              ),
            ],
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
                if (_userType == "Customer" || (_userType == "Service Provider" && !_isBusinessNameRequired)) ...[
                  _buildTextField(Icons.person_outline, "First Name", _firstNameController),
                  SizedBox(height: 16),
                  _buildTextField(Icons.person_outline, "Last Name", _lastNameController),
                ] else if (_isBusinessNameRequired) ...[
                  _buildTextField(Icons.store_mall_directory_outlined, "Business Name", _businessNameController),
                ],
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
                      onSelected: (_) {
                        setState(() {
                          _userType = "Customer";
                          _selectedServiceCategory = null;
                        });
                      },
                      selectedColor: Color(0xFFF56D16),
                      labelStyle: TextStyle(color: Colors.white),
                      backgroundColor: Color(0xFF3A22CC),
                    ),
                    SizedBox(width: 12),
                    ChoiceChip(
                      label: Text('Service Provider'),
                      selected: _userType == "Service Provider",
                      onSelected: (_) => setState(() => _userType = "Service Provider"),
                      selectedColor: Color(0xFFF56D16),
                      labelStyle: TextStyle(color: Colors.white),
                      backgroundColor: Color(0xFF3A22CC),
                    ),
                  ],
                ),
                if (_userType == "Service Provider") ...[
                  SizedBox(height: 16),
                  InputDecorator(
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 12.0),
                        child: Icon(Icons.business_center, color: Color(0xFFF56D16)),
                      ),
                      filled: true,
                      fillColor: Color(0xFF3A22CC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedServiceCategory,
                        isExpanded: true,
                        iconEnabledColor: Colors.white70,
                        dropdownColor: Color(0xFF3A22CC),
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        hint: Text("Select Service Category", style: TextStyle(color: Colors.white70)),
                        items: _serviceCategories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedServiceCategory = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
                if (_needsLocationPin) ...[
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickLocationOnMap,
                    icon: Icon(Icons.location_pin, color: Colors.white),
                    label: Text(
                      _selectedLocation == null ? 'Set Location' : 'Change Location',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF56D16),
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
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

  void _register() async {
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

  Widget _buildTextField(IconData icon, String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 12.0),
          child: Icon(icon, color: Color(0xFFF56D16)),
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
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 12.0),
          child: Icon(icon, color: Color(0xFFF56D16)),
        ),
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
