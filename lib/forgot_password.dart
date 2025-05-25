import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:async';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  String? _errorMessage;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    setState(() {
      _cooldown = seconds;
    });
    
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown > 0) {
        setState(() {
          _cooldown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _requestOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.254.110:5000/request_otp'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'email': email}),
      );

      if (!mounted) return;

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        setState(() {
          _otpSent = true;
        });
        _startCooldown(60); // 1 minute cooldown
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );
      } else if (response.statusCode == 429) {
        setState(() {
          _errorMessage = responseData['message'];
        });
        _startCooldown(responseData['remaining'] ?? 60);
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Failed to send OTP';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    if (email.isEmpty || otp.isEmpty) {
      setState(() {
        _errorMessage = 'Email and OTP are required';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.254.110:5000/verify_otp'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      if (!mounted) return;

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        setState(() {
          _otpVerified = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'OTP verification failed';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
        _isLoading = false;
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a new password';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.254.110:5000/reset_password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'new_password': password,
        }),
      );

      if (!mounted) return;

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Password reset failed';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildEmailInput() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email, color: Colors.black),
            labelStyle: TextStyle(color: Colors.black),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.purple),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
          enabled: !_otpSent,
          style: const TextStyle(color: Colors.black),
        ),
        const SizedBox(height: 16),
        if (_cooldown > 0)
          Text(
            'Resend OTP in $_cooldown seconds',
            style: const TextStyle(color: Colors.grey),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isLoading || _cooldown > 0 ? null : _requestOTP,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Send OTP', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPInput() {
    return Column(
      children: [
        PinCodeTextField(
          appContext: context,
          length: 6,
          controller: _otpController,
          keyboardType: TextInputType.number,
          textStyle: const TextStyle(color: Colors.black),
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(5),
            fieldHeight: 50,
            fieldWidth: 40,
            activeFillColor: Colors.white,
            activeColor: Colors.purple,
            selectedColor: Colors.purple,
            inactiveColor: Colors.grey,
            selectedFillColor: Colors.white,
            inactiveFillColor: Colors.white,
          ),
          onChanged: (value) {},
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isLoading ? null : _verifyOTP,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Verify OTP', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordInput() {
    return Column(
      children: [
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock, color: Colors.black),
            labelStyle: TextStyle(color: Colors.black),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.purple),
            ),
          ),
          obscureText: true,
          style: const TextStyle(color: Colors.black),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          decoration: const InputDecoration(
            labelText: 'Confirm New Password',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock, color: Colors.black),
            labelStyle: TextStyle(color: Colors.black),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.purple),
            ),
          ),
          obscureText: true,
          style: const TextStyle(color: Colors.black),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isLoading ? null : _resetPassword,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Reset Password', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_reset,
                  size: 60,
                  color: Colors.purple,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Reset your password',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                if (!_otpSent && !_otpVerified)
                  const Text(
                    'Enter your email address to receive an OTP for password reset.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                if (_otpSent && !_otpVerified)
                  const Text(
                    'Enter the 6-digit OTP sent to your email.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                if (_otpVerified)
                  const Text(
                    'Enter your new password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                if (_errorMessage != null) const SizedBox(height: 16),
                if (!_otpSent && !_otpVerified) _buildEmailInput(),
                if (_otpSent && !_otpVerified) _buildOTPInput(),
                if (_otpVerified) _buildPasswordInput(),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Login', 
                    style: TextStyle(color: Colors.purple)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}