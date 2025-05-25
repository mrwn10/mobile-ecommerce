import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'login.dart';
import 'rider_deliveries.dart';
import 'rider_account_settings.dart';
import 'rider_leaderboards.dart'; // Add this import

class RiderDashboard extends StatefulWidget {
  final String username;
  final String role;
  final String userId;

  const RiderDashboard({
    super.key,
    required this.username,
    required this.role,
    required this.userId,
  });

  @override
  _RiderDashboardState createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> shippedOrders = [];
  bool _isLoading = false;
  bool _isMarkingDelivered = false;
  String _errorMessage = '';
  bool _showSuccessAnimation = false;
  late Timer _timer;
  
  // Rider stats variables
  double _earnings = 0.0;
  int _totalOrders = 0;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    // Set up auto-refresh every 1 seconds
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchData(silent: true);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _fetchData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      await Future.wait([
        _fetchShippedOrders(silent: silent),
        _fetchRiderStats(silent: silent),
      ]);
    } finally {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchShippedOrders({bool silent = false}) async {
    if (!mounted) return;
    
    try {
      final response = await http.get(
        Uri.parse('http://192.168.254.110:5000/api/shipped-orders'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (!mounted) return;
          setState(() {
            shippedOrders = _transformApiData(data['data']);
          });
        } else {
          if (!silent && mounted) {
            setState(() {
              _errorMessage = data['error'] ?? 'Failed to load shipped orders';
            });
          }
        }
      } else if (!silent && mounted) {
        setState(() {
          _errorMessage = 'Failed to load shipped orders: ${response.statusCode}';
        });
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _fetchRiderStats({bool silent = false}) async {
    if (!mounted) return;
    
    if (!silent) {
      setState(() {
        _isLoadingStats = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.254.110:5000/api/rider-stats/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (!mounted) return;
          setState(() {
            _earnings = data['data']['earnings']?.toDouble() ?? 0.0;
            _totalOrders = data['data']['total_orders'] ?? 0;
            if (!silent) _isLoadingStats = false;
          });
        }
      }
    } catch (e) {
      // Silent fail for background refresh
      if (!silent && mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _markOrderDelivered(Map<String, dynamic> order) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: const Text('Mark this order as delivered?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isMarkingDelivered = true);
              
              try {
                final response = await http.post(
                  Uri.parse('http://192.168.254.110:5000/api/mark-delivered'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({
                    'order_id': order['order_id'],
                    'rider_id': widget.userId,
                  }),
                );

                final responseData = json.decode(response.body);
                
                if (response.statusCode == 200 && responseData['success']) {
                  setState(() => _showSuccessAnimation = true);
                  await Future.delayed(const Duration(seconds: 2));
                  setState(() => _showSuccessAnimation = false);
                  await _fetchData();
                } else {
                  throw Exception(responseData['error'] ?? 'Failed to mark order as delivered');
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (!mounted) return;
                setState(() => _isMarkingDelivered = false);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _transformApiData(List<dynamic> apiData) {
    return apiData.map((order) {
      return {
        'order_id': order['order_id'],
        'customer': order['username'],
        'address': '${order['barangay']}, ${order['municipal']}, ${order['province']}',
        'status': order['order_status'],
        'items': '${order['quantity']} item${order['quantity'] > 1 ? 's' : ''}',
        'amount': '₱${order['price_at_add']?.toStringAsFixed(2) ?? '0.00'}',
        'contact_number': order['contact_number'],
        'ordered_at': order['ordered_at'],
      };
    }).toList();
  }

  Future<void> _showLogoutConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to logout?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({required IconData icon, required String value, required String label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 30, color: Colors.purple),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Card(
      key: ValueKey(order['order_id']), // Important for animations
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order['order_id']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'SHIPPED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Customer: ${order['customer']}', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            Text('Contact: ${order['contact_number']}', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            Text('Address: ${order['address']}', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            Text('Items: ${order['items']}', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            Text(
              'Amount: ${order['amount']}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Ordered: ${order['ordered_at']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle, size: 20, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isMarkingDelivered ? null : () => _markOrderDelivered(order),
                label: _isMarkingDelivered
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'ORDER DELIVERED',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Dashboard'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card with Stats
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.delivery_dining, size: 40, color: Colors.purple),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${widget.username}!',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Your delivery stats',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _isLoadingStats
                          ? const Center(child: CircularProgressIndicator())
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatCard(
                                  icon: Icons.attach_money,
                                  value: '₱${_earnings.toStringAsFixed(2)}',
                                  label: 'Earnings',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RiderLeaderboards(
                                          userId: widget.userId,
                                          username: widget.username,
                                          initialSort: 'earnings',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                _buildStatCard(
                                  icon: Icons.local_shipping,
                                  value: _totalOrders.toString(),
                                  label: 'Delivered',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RiderLeaderboards(
                                          userId: widget.userId,
                                          username: widget.username,
                                          initialSort: 'total_orders',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Shipped Orders Section
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage.isNotEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                                  const SizedBox(height: 20),
                                  Text(
                                    _errorMessage,
                                    style: const TextStyle(fontSize: 18, color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: _fetchData,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : shippedOrders.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.directions_bike,
                                        size: 60,
                                        color: Colors.purple.withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        'No shipped deliveries yet',
                                        style: TextStyle(fontSize: 18, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : AnimatedList(
                                  key: ValueKey(shippedOrders.length), // Force rebuild when length changes
                                  initialItemCount: shippedOrders.length,
                                  itemBuilder: (context, index, animation) {
                                    return SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.1),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOut,
                                      )),
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: _buildOrderCard(shippedOrders[index]),
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
          
          // Success Animation Overlay
          if (_showSuccessAnimation)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 80),
                      const SizedBox(height: 20),
                      const Text(
                        'Order Delivered Successfully!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '₱50 has been added to your earnings',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        iconSize: 28,
        selectedLabelStyle: const TextStyle(fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Deliveries'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Leaderboards'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Account'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RiderDeliveries(
                  userId: widget.userId,
                  username: widget.username,
                ),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RiderLeaderboards(
                  userId: widget.userId,
                  username: widget.username,
                ),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RiderAccountSettings(userId: widget.userId),
              ),
            );
          } else if (index == 4) {
            _showLogoutConfirmation();
          }
        },
      ),
    );
  }
}