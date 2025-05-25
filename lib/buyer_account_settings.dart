import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BuyerAccountSettings extends StatefulWidget {
  final String userId;

  const BuyerAccountSettings({Key? key, required this.userId}) : super(key: key);

  @override
  _BuyerAccountSettingsState createState() => _BuyerAccountSettingsState();
}

class _BuyerAccountSettingsState extends State<BuyerAccountSettings> {
  late Map<String, dynamic> _userData = {
    'username': 'Loading...',
    'email': 'Loading...',
    'province': 'Loading...',
    'municipal': 'Loading...',
    'barangay': 'Loading...',
    'contact_number': 'Loading...',
  };
  bool _isLoading = true;
  bool _isEditing = false;
  String _errorMessage = '';
  
  // Controllers for editable fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _municipalController = TextEditingController();
  final TextEditingController _barangayController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.254.110:5000/buyer/account-settings?user_id=${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          setState(() {
            _userData = jsonResponse['data'];
            // Initialize controllers with fetched data
            _usernameController.text = _userData['username'] ?? '';
            _emailController.text = _userData['email'] ?? '';
            _provinceController.text = _userData['province'] ?? '';
            _municipalController.text = _userData['municipal'] ?? '';
            _barangayController.text = _userData['barangay'] ?? '';
            _contactController.text = _userData['contact_number'] ?? '';
            _isLoading = false;
          });
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load user data');
        }
      } else {
        throw Exception('Server responded with ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _showErrorSnackbar(_errorMessage);
    }
  }

  Future<void> _updateUserData() async {
    // Basic validation
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty) {
      _showErrorSnackbar('Username and email are required');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.254.110:5000/buyer/account-settings/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'username': _usernameController.text,
          'email': _emailController.text,
          'province': _provinceController.text,
          'municipal': _municipalController.text,
          'barangay': _barangayController.text,
          'contact_number': _contactController.text,
        }),
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse['status'] == 'success') {
          // Update successful
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ), // <-- Missing closing parenthesis was here
          );
        // Update local state with new data
        setState(() {
          _userData = {
            'username': _usernameController.text,
            'email': _emailController.text,
            'province': _provinceController.text,
            'municipal': _municipalController.text,
            'barangay': _barangayController.text,
            'contact_number': _contactController.text,
          };
          _isEditing = false;
          _isLoading = false;
        });
      } else {
        // Handle server-side validation errors
        throw Exception(jsonResponse['message'] ?? 'Failed to update user data');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _showErrorSnackbar(_errorMessage);
    }
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      // Reset to original values if cancelling edit
      if (!_isEditing) {
        _usernameController.text = _userData['username'];
        _emailController.text = _userData['email'];
        _provinceController.text = _userData['province'];
        _municipalController.text = _userData['municipal'];
        _barangayController.text = _userData['barangay'];
        _contactController.text = _userData['contact_number'];
      }
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Account Settings',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: _toggleEditing,
            tooltip: _isEditing ? 'Cancel' : 'Edit',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading data',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _fetchUserData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // User ID display
                      _buildInfoCard('User ID', widget.userId, Icons.person_pin),
                      const SizedBox(height: 20),
                      
                      // Account Information
                      _buildSectionTitle('Account Information'),
                      _buildEditableTextField('Username', _usernameController),
                      _buildEditableTextField('Email', _emailController),
                      
                      const SizedBox(height: 24),
                      
                      // Address Information
                      _buildSectionTitle('Address Information'),
                      _buildEditableTextField('Province', _provinceController),
                      _buildEditableTextField('Municipality', _municipalController),
                      _buildEditableTextField('Barangay', _barangayController),
                      
                      const SizedBox(height: 24),
                      
                      // Contact Information
                      _buildSectionTitle('Contact Information'),
                      _buildEditableTextField('Contact Number', _contactController),
                      
                      // Update Button (only shown when editing)
                      if (_isEditing) ...[
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateUserData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Update Information',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.purple),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.purple),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.purple),
          ),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        readOnly: !_isEditing,
        style: const TextStyle(color: Colors.black, fontSize: 16),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _provinceController.dispose();
    _municipalController.dispose();
    _barangayController.dispose();
    _contactController.dispose();
    super.dispose();
  }
}