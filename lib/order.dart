import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cancel_order.dart';
import 'cancel_cart.dart';
import 'dart:async';

class OrderScreen extends StatefulWidget {
  final String userId;

  const OrderScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _cart = [];
  bool _showCart = false;
  final Color _primaryColor = Colors.purple; // Purple theme color

  @override
  void initState() {
    super.initState();
    _fetchOrdersAndCart();
  }

  Future<void> _fetchOrdersAndCart() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.get(
        Uri.parse('http://192.168.254.110:5000/get_cart_orders?user_id=${widget.userId}'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        
        setState(() {
          _orders = List<Map<String, dynamic>>.from(data['orders']);
          _cart = List<Map<String, dynamic>>.from(data['cart']);
          _isLoading = false;
        });
        debugPrint('Data loaded in ${stopwatch.elapsedMilliseconds}ms');
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Failed to load orders and cart. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is TimeoutException 
            ? 'Request timed out. Please check your connection.'
            : 'Network error. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final imageBytes = order['image_url'] != null ? base64Decode(order['image_url']) : null;

    double priceAtAdd = double.tryParse(order['price_at_add']?.toString() ?? '0') ?? 0;
    int quantity = order['quantity'] ?? 0;
    double totalPrice = priceAtAdd * quantity;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image - Using cached network image would be better
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[100],
                  ),
                  child: imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            imageBytes,
                            fit: BoxFit.cover,
                            cacheWidth: 160, // Optimize image size
                          ),
                        )
                      : const Center(child: Icon(Icons.image, size: 30, color: Colors.grey)),
                ),
                const SizedBox(width: 12),
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['product_name'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${priceAtAdd.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey[200]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Price',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '₱${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusBackgroundColor(order['order_status'] ?? ''),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order['order_status'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusTextColor(order['order_status'] ?? ''),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Ordered on ${order['ordered_at'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CancelOrderScreen(
                        orderId: order['order_id'].toString(),
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartCard(Map<String, dynamic> cartItem) {
    final imageBytes = cartItem['image_url'] != null ? base64Decode(cartItem['image_url']) : null;

    double price = double.tryParse(cartItem['product_price']?.toString() ?? '0') ?? 0;
    int quantity = cartItem['quantity'] ?? 0;
    double totalPrice = price * quantity;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[100],
                  ),
                  child: imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            imageBytes,
                            fit: BoxFit.cover,
                            cacheWidth: 160, // Optimize image size
                          ),
                        )
                      : const Center(child: Icon(Icons.image, size: 30, color: Colors.grey)),
                ),
                const SizedBox(width: 12),
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cartItem['product_name'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey[200]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Price',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '₱${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Added on ${cartItem['added_at'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CancelCartScreen(
                        cartId: cartItem['cart_id'].toString(),
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange[100]!;
      case 'shipped':
        return Colors.blue[100]!;
      case 'delivered':
        return Colors.green[100]!;
      case 'cancelled':
        return Colors.red[100]!;
      default:
        return Colors.grey[200]!;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange[800]!;
      case 'shipped':
        return Colors.blue[800]!;
      case 'delivered':
        return Colors.green[800]!;
      case 'cancelled':
        return Colors.red[800]!;
      default:
        return Colors.grey[800]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders & Cart'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Segmented Control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _showCart = false;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_showCart ? _primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'My Orders',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: !_showCart ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _showCart = true;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _showCart ? _primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'My Cart',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _showCart ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Loading or Error
          if (_isLoading || _errorMessage.isNotEmpty)
            Expanded(
              child: Center(
                child: _isLoading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading your ${_showCart ? 'cart' : 'orders'}...',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryColor,
                                side: BorderSide(color: _primaryColor),
                              ),
                              onPressed: _fetchOrdersAndCart,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          // Main Content
          if (!_isLoading && _errorMessage.isEmpty)
            Expanded(
              child: RefreshIndicator(
                color: _primaryColor,
                onRefresh: _fetchOrdersAndCart,
                child: _showCart
                    ? _cart.isEmpty
                        ? _buildEmptyState('Your cart is empty', Icons.shopping_cart_outlined)
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: _cart.length,
                            itemBuilder: (context, index) => _buildCartCard(_cart[index]),
                          )
                    : _orders.isEmpty
                        ? _buildEmptyState('No orders yet', Icons.receipt_long_outlined)
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: _orders.length,
                            itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
                          ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: _fetchOrdersAndCart,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: _primaryColor,
                  ),
                  onPressed: () {},
                  child: const Text('Browse Products'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}