import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'buyer_dashboard.dart';

class CartScreen extends StatefulWidget {
  final Flashcard flashcard;
  final String userId;

  const CartScreen({
    super.key,
    required this.flashcard,
    required this.userId,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int quantity = 1;
  bool isLoading = false;
  bool isBuying = false;

  void incrementQuantity() {
    if (quantity < widget.flashcard.quantityStatus) {
      setState(() {
        quantity++;
      });
    }
  }

  void decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  Future<void> _addToCart() async {
    setState(() {
      isLoading = true;
    });

    try {
      final price = double.tryParse(widget.flashcard.productPrice) ?? 0.0;

      final response = await http.post(
        Uri.parse('http://192.168.254.110:5000/cart/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'product_id': widget.flashcard.productId,
          'quantity': quantity,
          'price': price.toStringAsFixed(2),
        }),
      );

      debugPrint('Add to Cart Response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.body.isEmpty) {
        throw FormatException('Server returned empty response');
      }

      dynamic responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        throw FormatException('Invalid server response: ${e.toString()}');
      }

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Added to cart successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                responseData['error'] ?? 'Failed to add to cart (Status ${response.statusCode})'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _buyNow() async {
    setState(() {
      isBuying = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.254.110:5000/order/buy'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'product_id': widget.flashcard.productId,
          'quantity': quantity,
        }),
      );

      debugPrint('Buy Now Response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.body.isEmpty) {
        throw FormatException('Server returned empty response');
      }

      dynamic responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        throw FormatException('Invalid server response: ${e.toString()}');
      }

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Order placed successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // Optionally navigate to orders screen or refresh
        Navigator.pop(context); // Go back to previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                responseData['error'] ?? 'Failed to place order (Status ${response.statusCode})'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isBuying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    try {
      imageBytes = base64Decode(widget.flashcard.imageUrl);
    } catch (e) {
      debugPrint('Image decode failed: $e');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[100],
                        ),
                        child: imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  imageBytes,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.broken_image,
                                    size: 60, color: Colors.grey),
                              ),
                      ),
                      const SizedBox(height: 20),
                      // Product Name and Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.flashcard.imageName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '₱${widget.flashcard.productPrice}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stock Status
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.flashcard.quantityStatus > 0
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.flashcard.quantityStatus > 0
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: widget.flashcard.quantityStatus > 0
                                      ? Colors.green
                                      : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.flashcard.quantityStatus > 0
                                          ? 'In Stock'
                                          : 'Out of Stock',
                                      style: TextStyle(
                                        color: widget.flashcard.quantityStatus > 0
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (widget.flashcard.quantityStatus > 0)
                                      Text(
                                        '${widget.flashcard.quantityStatus} available',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Description
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.flashcard.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Quantity Selector
                      const Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Decrement Button
                          Container(
                            decoration: BoxDecoration(
                              color: quantity > 1
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1)
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: decrementQuantity,
                              icon: Icon(
                                Icons.remove,
                                color: quantity > 1
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            quantity.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Increment Button
                          Container(
                            decoration: BoxDecoration(
                              color: quantity < widget.flashcard.quantityStatus
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1)
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: incrementQuantity,
                              icon: Icon(
                                Icons.add,
                                color: quantity < widget.flashcard.quantityStatus
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // Action Buttons
                      Row(
                        children: [
                          // Buy Now Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isBuying ? null : _buyNow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: isBuying
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Buy Now',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Add to Cart Button
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isLoading ? null : _addToCart,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(Colors.blue),
                                      ),
                                    )
                                  : Text(
                                      'Add to Cart',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}