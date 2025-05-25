import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _provinceController = TextEditingController();
  final _municipalController = TextEditingController();
  final _barangayController = TextEditingController();
  final _contactNumberController = TextEditingController();

  String? _selectedRole;
  final List<String> _roles = ['rider', 'buyer'];
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Color scheme
  static const Color _primaryColor = Colors.white;
  static const Color _secondaryColor = Color(0xFF6A1B9A); // Deep purple
  static const Color _textColor = Colors.black;
  static const Color _hintTextColor = Colors.black54;
  static const Color _errorColor = Colors.red;

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.254.110:5000/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'confirm_password': _confirmPasswordController.text.trim(),
          'role': _selectedRole,
          'province': _provinceController.text.trim(),
          'municipal': _municipalController.text.trim(),
          'barangay': _barangayController.text.trim(),
          'contact_number': _contactNumberController.text.trim(),
        }),
      );

      if (!mounted) return;

      final data = json.decode(response.body);

      if (response.statusCode == 201) { // Changed from 200 to 201 to match your Python code
        _showSuccessDialog();
      } else {
        final errorField = data['data']?['field']?.toString();
        final errorMessage = data['message'] ?? 'Registration failed';
        
        if (errorField != null) {
          _scrollToError(errorField);
        }
        _showErrorSnackbar(errorMessage);
      }
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToError(String fieldName) {
    // You would need to implement scroll logic based on your form fields
    // This is a placeholder for the actual implementation
    debugPrint('Scroll to field: $fieldName');
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Registration Successful', style: TextStyle(color: _secondaryColor)),
        content: const Text('You can now login with your credentials.', style: TextStyle(color: _textColor)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('OK', style: TextStyle(color: _secondaryColor)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: _primaryColor,
        elevation: 8,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: _primaryColor,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _secondaryColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: _secondaryColor.withOpacity(0.2), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.asset(
                      'assets/img/logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Create Your Account',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fill in your details to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: _hintTextColor,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Username
                TextFormField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: _hintTextColor),
                    hintText: 'At least 4 characters (letters, numbers, _)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _secondaryColor, width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.person_outline, color: _hintTextColor),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length < 4) {
                      return 'Username must be at least 4 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                      return 'Only letters, numbers and underscore allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: _hintTextColor),
                    hintText: 'example@domain.com',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _secondaryColor, width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.email_outlined, color: _hintTextColor),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: _hintTextColor),
                    hintText: '8+ chars, uppercase, lowercase, number, special',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _secondaryColor, width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: _hintTextColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: _hintTextColor,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      return 'Needs at least one uppercase letter';
                    }
                    if (!RegExp(r'[a-z]').hasMatch(value)) {
                      return 'Needs at least one lowercase letter';
                    }
                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                      return 'Needs at least one number';
                    }
                    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                      return 'Needs at least one special character';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(color: _hintTextColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _secondaryColor, width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: _hintTextColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: _hintTextColor,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Role Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    labelStyle: TextStyle(color: _hintTextColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _secondaryColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  hint: const Text('Select your role', style: TextStyle(color: _hintTextColor)),
                  items: _roles.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(color: _textColor)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() => _selectedRole = newValue);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a role';
                    }
                    return null;
                  },
                  style: TextStyle(color: _textColor),
                  dropdownColor: _primaryColor,
                  isExpanded: true,
                ),
                const SizedBox(height: 16),
                
                // Address Fields
                TextFormField(
                  controller: _provinceController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Province',
                    labelStyle: TextStyle(color: _hintTextColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _secondaryColor, width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.location_on_outlined, color: _hintTextColor),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your province';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _municipalController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Municipality',
                    labelStyle: TextStyle(color: _hintTextColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _secondaryColor, width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.location_city_outlined, color: _hintTextColor),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your municipality';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _barangayController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Barangay',
                    labelStyle: TextStyle(color: _hintTextColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _secondaryColor, width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.house_outlined, color: _hintTextColor),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your barangay';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Contact Number
                TextFormField(
                  controller: _contactNumberController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Contact Number',
                    labelStyle: TextStyle(color: _hintTextColor),
                    hintText: 'Must start with 09 and 11 digits only',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _secondaryColor, width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.phone_outlined, color: _hintTextColor),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your contact number';
                    }
                    if (!value.startsWith('09')) {
                      return 'Must start with 09';
                    }
                    if (value.length != 11) {
                      return 'Must be exactly 11 digits';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Only numbers allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _secondaryColor,
                      foregroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                      shadowColor: _secondaryColor.withOpacity(0.3),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?', style: TextStyle(color: _hintTextColor)),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        'Login here',
                        style: TextStyle(
                          color: _secondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _provinceController.dispose();
    _municipalController.dispose();
    _barangayController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }
}