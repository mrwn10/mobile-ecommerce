import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CancelOrderScreen extends StatefulWidget {
  final String orderId;
  final String userId;

  const CancelOrderScreen({
    Key? key,
    required this.orderId,
    required this.userId,
  }) : super(key: key);

  @override
  _CancelOrderScreenState createState() => _CancelOrderScreenState();
}

class _CancelOrderScreenState extends State<CancelOrderScreen> {
  Map<String, dynamic>? orderDetails;
  bool isLoading = true;
  String errorMessage = '';
  bool isCancelling = false;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    final url = Uri.parse('http://192.168.254.110:5000/get_cart_orders?user_id=${widget.userId}');

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final orders = data['orders'] as List;
        
        final item = orders.firstWhere(
          (item) => item['order_id'].toString() == widget.orderId,
          orElse: () => null,
        );

        if (item != null) {
          setState(() {
            orderDetails = item;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Order not found';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load order details';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _cancelOrder() async {
    setState(() {
      isCancelling = true;
    });

    try {
      final url = Uri.parse('http://192.168.254.110:5000/cancel_order_item');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_id': widget.orderId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Return to previous screen with success status
        Navigator.pop(context, true);
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${errorData['error'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isCancelling = false;
      });
    }
  }

  String _calculateTotalPrice() {
    if (orderDetails == null) return '0.00';
    
    final price = double.tryParse(orderDetails?['price_at_add']?.toString() ?? '0') ?? 0;
    final quantity = int.tryParse(orderDetails?['quantity']?.toString() ?? '1') ?? 1;
    
    return (price * quantity).toStringAsFixed(2);
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'shipped':
        return Colors.blue[800]!;
      case 'delivered':
        return Colors.green[800]!;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if order is shipped or delivered
    final orderStatus = orderDetails?['order_status']?.toString().toLowerCase() ?? '';
    final isShippedOrDelivered = orderStatus == 'shipped' || orderStatus == 'delivered';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.purple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (orderDetails?['image_url'] != null)
                                Container(
                                  height: 180,
                                  width: 180,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[100],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      base64Decode(orderDetails!['image_url']),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              Text(
                                orderDetails?['product_name'] ?? 'No product name',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Order ID: ${orderDetails?['order_id'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Divider(color: Colors.grey[300]),
                              const SizedBox(height: 10),
                              // Order Details
                              _buildDetailCard(
                                children: [
                                  _buildDetailRow('Quantity:', orderDetails?['quantity'].toString() ?? 'N/A'),
                                  _buildDetailRow('Unit Price:', '₱${orderDetails?['price_at_add'] ?? '0.00'}'),
                                  _buildDetailRow(
                                    'Total Price:',
                                    '₱${_calculateTotalPrice()}',
                                    isBold: true,
                                    textColor: Colors.purple,
                                  ),
                                  _buildStatusRow(orderDetails?['order_status'] ?? 'N/A'),
                                  _buildDetailRow('Ordered on:', _formatDate(orderDetails?['ordered_at'])),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Only show buttons if order is not shipped or delivered
                      if (!isShippedOrDelivered) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isCancelling ? null : _cancelOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: isCancelling
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Cancel Order',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Colors.purple),
                            ),
                            child: const Text(
                              'Keep Order',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                        ),
                      ] else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'This order has been ${orderStatus}. No further actions available.',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? textColor}) {
    if (label == 'Ordered on:') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: textColor ?? Colors.black,
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: textColor ?? Colors.black,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatusRow(String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            'Status:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}