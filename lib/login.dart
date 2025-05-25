import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

import 'buyer_dashboard.dart';
import 'rider_dashboard.dart';
import 'register.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int? _remainingAttempts;

  // Enhanced color scheme
  final Color _primaryColor = Colors.white;
  final Color _secondaryColor = Color(0xFF6A1B9A); // Deep purple
  final Color _textColor = Colors.black;
  final Color _hintTextColor = Colors.black54;

  Future<void> login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _remainingAttempts = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showErrorDialog('Please enter both username and password');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse('http://192.168.254.110:5000/login'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _handleSuccessfulLogin(responseData, username);
      } else {
        _handleErrorResponse(responseData);
      }
    } on http.ClientException catch (e) {
      _showErrorDialog('Network error: ${e.message}');
    } on TimeoutException {
      _showErrorDialog('Request timed out. Please try again.');
    } on FormatException {
      _showErrorDialog('Invalid server response format.');
    } catch (e) {
      _showErrorDialog('An unexpected error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSuccessfulLogin(Map<String, dynamic> data, String username) {
    final role = data['role']?.toString() ?? '';
    final userId = data['userId']?.toString() ?? '';

    if (userId.isEmpty) {
      _showErrorDialog('User ID not provided in response');
      return;
    }

    Widget? nextPage;
    switch (role) {
      case 'buyer':
        nextPage = BuyerDashboard(username: username, role: role, userId: userId);
        break;
      case 'rider':
        nextPage = RiderDashboard(username: username, role: role, userId: userId);
        break;
      default:
        _showErrorDialog('Invalid user role');
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextPage!),
    );
  }

  void _handleErrorResponse(Map<String, dynamic> responseData) {
    final errorMessage = responseData['message'] ??
        (responseData['status'] == 'error' ? 'Login failed' : 'Unknown error occurred');

    final attemptRegex = RegExp(r'(\d+) attempts remaining');
    final match = attemptRegex.firstMatch(errorMessage);
    if (match != null) {
      setState(() {
        _remainingAttempts = int.tryParse(match.group(1) ?? '');
      });
    }

    _showErrorDialog(errorMessage);
  }

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
    setState(() => _errorMessage = message);
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error', style: TextStyle(color: _secondaryColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: TextStyle(color: _textColor)),
              if (_remainingAttempts != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Remaining attempts: $_remainingAttempts',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK', style: TextStyle(color: _secondaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: _primaryColor,
          elevation: 8,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 16,
                    spreadRadius: 4,
                    offset: const Offset(0, 6),
                  )
                ],
                border: Border.all(color: Colors.grey.shade200, width: 0.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo with improved styling
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
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please login to continue',
                    style: TextStyle(
                      fontSize: 14,
                      color: _hintTextColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: _hintTextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _secondaryColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                      prefixIcon: Icon(Icons.person_outline, color: _hintTextColor),
                    ),
                    style: TextStyle(color: _textColor),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: _hintTextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _secondaryColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                      prefixIcon: Icon(Icons.lock_outline, color: _hintTextColor),
                    ),
                    style: TextStyle(color: _textColor),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen()),
                        );
                      },
                      child: Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: 14,
                          color: _secondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : login,
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
                          : Text(
                              'Login',
                              style: TextStyle(
                                color: _primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  // Error message display below the login button
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_remainingAttempts != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Remaining attempts: $_remainingAttempts',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: _hintTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 14,
                          color: _hintTextColor,
                        ),
                        children: [
                          TextSpan(
                            text: 'Register here',
                            style: TextStyle(
                              color: _secondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
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
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}