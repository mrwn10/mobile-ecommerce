import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CancelCartScreen extends StatefulWidget {
  final String cartId;
  final String userId;

  const CancelCartScreen({
    Key? key,
    required this.cartId,
    required this.userId,
  }) : super(key: key);

  @override
  _CancelCartScreenState createState() => _CancelCartScreenState();
}

class _CancelCartScreenState extends State<CancelCartScreen> {
  Map<String, dynamic>? cartItemDetails;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCartItemDetails();
  }

  Future<void> _fetchCartItemDetails() async {
    final url = Uri.parse('http://192.168.254.110:5000/get_cart_orders?user_id=${widget.userId}');

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cartItems = data['cart'] as List;
        
        final item = cartItems.firstWhere(
          (item) => item['cart_id'].toString() == widget.cartId,
          orElse: () => null,
        );

        if (item != null) {
          setState(() {
            cartItemDetails = item;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Cart item not found';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load cart details';
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

  Future<void> cancelCartItem() async {
    final url = Uri.parse('http://192.168.254.110:5000/cancel_cart_item');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cart_id': widget.cartId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item removed from cart successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
        });
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${data['error'] ?? 'Unknown error'}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> checkoutItem() async {
    final url = Uri.parse('http://192.168.254.110:5000/checkout_cart');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'cart_ids': [widget.cartId]
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item checked out successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
        });
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${data['error'] ?? 'Unknown error'}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart Item Details'),
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
                              if (cartItemDetails?['image_url'] != null)
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
                                      base64Decode(cartItemDetails!['image_url']),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              Text(
                                cartItemDetails?['product_name'] ?? 'No product name',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                cartItemDetails?['description'] ?? 'No description',
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
                                  _buildDetailRow('Quantity:', cartItemDetails?['quantity'].toString() ?? 'N/A'),
                                  _buildDetailRow('Unit Price:', '₱${cartItemDetails?['price_at_add'] ?? '0.00'}'),
                                  _buildDetailRow(
                                    'Total Price:',
                                    '₱${_calculateTotalPrice()}',
                                    isBold: true,
                                    textColor: Colors.purple,
                                  ),
                                  _buildDetailRow('Added on:', _formatDate(cartItemDetails?['added_at'])),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Action Buttons
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: checkoutItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Checkout This Item',
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
                        child: ElevatedButton(
                          onPressed: cancelCartItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Remove from Cart',
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
                            'Keep in Cart',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.purple,
                            ),
                          ),
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
    if (label == 'Added on:') {
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

  String _calculateTotalPrice() {
    if (cartItemDetails == null) return '0.00';
    
    final price = double.tryParse(cartItemDetails?['price_at_add']?.toString() ?? '0') ?? 0;
    final quantity = int.tryParse(cartItemDetails?['quantity']?.toString() ?? '1') ?? 1;
    
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
}