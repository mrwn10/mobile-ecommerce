import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async';

class RiderDeliveries extends StatefulWidget {
  final String userId;
  final String username;

  const RiderDeliveries({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  _RiderDeliveriesState createState() => _RiderDeliveriesState();
}

class _RiderDeliveriesState extends State<RiderDeliveries> {
  List<Map<String, dynamic>> deliveries = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _fetchDeliveries();
    // Set up silent auto-refresh every 1 second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchDeliveries(silent: true);
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> _fetchDeliveries({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.254.110:5000/api/user-orders'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              deliveries = _transformApiData(data['data']);
              if (!silent) _isLoading = false;
            });
          }
        } else {
          if (!silent && mounted) {
            setState(() {
              _errorMessage = data['error'] ?? 'Failed to load deliveries';
              _isLoading = false;
            });
          }
        }
      } else {
        if (!silent && mounted) {
          setState(() {
            _errorMessage = 'Failed to load deliveries: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _transformApiData(List<dynamic> apiData) {
    return apiData
        .where((order) => order['order_status'] == 'pending')
        .map((order) {
      return {
        'order_id': order['order_id'],
        'customer': order['username'],
        'address': '${order['barangay']}, ${order['municipal']}, ${order['province']}',
        'status': order['order_status'],
        'items': '${order['quantity']} item${order['quantity'] > 1 ? 's' : ''}',
        'amount': '₱${order['price_at_add']?.toStringAsFixed(2) ?? '0.00'}',
        'contact_number': order['contact_number'],
        'ordered_at': _formatDateTime(order['ordered_at']),
      };
    }).toList();
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    await _fetchDeliveries();
  }

  Future<void> _acceptDelivery(Map<String, dynamic> delivery) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Accept Delivery',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm acceptance of order from ${delivery['customer']}?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Order ID: ${delivery['order_id']}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final response = await http.post(
                  Uri.parse('http://192.168.254.110:5000/api/accept-delivery'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({
                    'order_id': delivery['order_id'],
                    'rider_id': widget.userId,
                  }),
                );

                final responseData = json.decode(response.body);
                
                if (response.statusCode == 200 && responseData['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Delivery accepted successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  await _refreshData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(responseData['error'] ?? 'Failed to accept delivery'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Available Deliveries',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
            SizedBox(height: 16),
            Text(
              'Loading deliveries...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: Colors.red[400],
              ),
              const SizedBox(height: 20),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _refreshData,
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (deliveries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_bike_rounded,
                size: 80,
                color: Colors.purple.withOpacity(0.2),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Pending Deliveries',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Check back later for new delivery requests',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _refreshData,
      color: Colors.purple,
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 40,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: deliveries.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final delivery = deliveries[index];
          return _buildDeliveryCard(delivery);
        },
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Potential future enhancement: Show delivery details
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with customer and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      delivery['customer'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(delivery['status']),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      delivery['status'].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Order ID
              Text(
                'Order #${delivery['order_id']}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              
              // Delivery details in a clean layout
              _buildDetailRow(Icons.phone_rounded, delivery['contact_number']),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.location_on_rounded, delivery['address']),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.shopping_bag_rounded, delivery['items']),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.attach_money_rounded, delivery['amount']),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.access_time_rounded, delivery['ordered_at']),
              const SizedBox(height: 16),
              
              // Accept button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delivery_dining, size: 20, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _acceptDelivery(delivery),
                  label: const Text(
                    'ACCEPT DELIVERY',
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
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.purple.withOpacity(0.8),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    return Colors.orange;
  }
}