import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'cart.dart';
import 'order.dart';
import 'buyer_account_settings.dart';
import 'login.dart';
import 'dart:async';

class Flashcard {
  final String imageName;
  final String imageUrl;
  final String productPrice;
  final int quantityStatus;
  final String description;
  final int productId;
  final String category;

  Flashcard({
    required this.imageName,
    required this.imageUrl,
    required this.productPrice,
    required this.quantityStatus,
    required this.description,
    required this.productId,
    required this.category,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      imageName: json['image_name'],
      imageUrl: json['image_url'] ?? '',
      productPrice: json['product_price'] ?? '0.00',
      quantityStatus: json['quantity_status'] is int
          ? json['quantity_status']
          : int.tryParse(json['quantity_status']) ?? 0,
      description: json['description'] ?? '',
      productId: json['product_id'] ?? 0,
      category: json['category'] ?? '',
    );
  }
}

class BuyerDashboard extends StatefulWidget {
  final String username;
  final String role;
  final String userId;

  const BuyerDashboard({
    super.key,
    required this.username,
    required this.role,
    required this.userId,
  });

  @override
  _BuyerDashboardState createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  List<Flashcard> flashcards = [];
  List<Flashcard> filteredFlashcards = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentIndex = 0;
  TextEditingController searchController = TextEditingController();
  String selectedCategory = 'All Categories';
  List<String> categories = [
    'All Categories',
    'baby_clothes_accessories',
    'educational_materials',
    'nursery_furniture',
    'safety_and_health',
    'strollers_gears',
    'toys_and_games'
  ];
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    fetchFlashcards();
    searchController.addListener(_filterProducts);
    
    // Set up silent refresh every 1 second
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _silentRefresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _silentRefresh() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.254.110:5000/get_flashcards'));
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = json.decode(response.body);
        final newFlashcards = data.map((json) => Flashcard.fromJson(json)).toList();
        
        // Only update if there are actual changes
        if (!_areListsEqual(flashcards, newFlashcards)) {
          setState(() {
            flashcards = newFlashcards;
            _filterProducts(); // Re-apply filters
          });
        }
      }
    } catch (e) {
      // Silent fail for background refresh
    }
  }

  bool _areListsEqual(List<Flashcard> list1, List<Flashcard> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].productId != list2[i].productId ||
          list1[i].quantityStatus != list2[i].quantityStatus) {
        return false;
      }
    }
    return true;
  }

  Future<void> fetchFlashcards() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.254.110:5000/get_flashcards'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            flashcards = data.map((json) => Flashcard.fromJson(json)).toList();
            filteredFlashcards = List.from(flashcards);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load products. Please try again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  void _filterProducts() {
    final searchQuery = searchController.text.toLowerCase();
    setState(() {
      filteredFlashcards = flashcards.where((flashcard) {
        final matchesSearch = flashcard.imageName.toLowerCase().contains(searchQuery);
        final matchesCategory = selectedCategory == 'All Categories' || 
                              flashcard.category == selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Uint8List? decodeBase64Image(String base64Str) {
    try {
      return base64Decode(base64Str);
    } catch (e) {
      print('Failed to decode image: $e');
      return null;
    }
  }

  void _viewProductDetails(Flashcard flashcard) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(
          flashcard: flashcard,
          userId: widget.userId,
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Confirm Logout',
            style: TextStyle(color: Colors.black),
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to logout?',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'No',
                style: TextStyle(color: Colors.purple),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.purple),
              ),
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

  Widget _buildProductCard(Flashcard flashcard) {
    final imageBytes = decodeBase64Image(flashcard.imageUrl);
    final isOutOfStock = flashcard.quantityStatus <= 0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _viewProductDetails(flashcard),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container with fixed aspect ratio
              AspectRatio(
                aspectRatio: 1.2, // Slightly taller aspect ratio
                child: Container(
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
                      : const Center(child: Icon(Icons.broken_image, size: 50)),
                ),
              ),
              const SizedBox(height: 16),
              // Product name
              Text(
                flashcard.imageName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Price
              Text(
                '₱${flashcard.productPrice}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 12),
              // Stock status row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isOutOfStock ? Colors.red[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOutOfStock ? Icons.cancel : Icons.check_circle,
                          color: isOutOfStock ? Colors.red : Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOutOfStock ? 'Out of stock' : 'In stock',
                          style: TextStyle(
                            fontSize: 14,
                            color: isOutOfStock ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (!isOutOfStock)
                    Text(
                      '${flashcard.quantityStatus} left',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // View Details button
              SizedBox(
                width: double.infinity,
                height: 48, // Fixed height for button
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isOutOfStock ? null : () => _viewProductDetails(flashcard),
                  child: const Text(
                    'View Details',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Marketplace',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Search and filter section
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      color: Colors.white,
                      child: Column(
                        children: [
                          // Search bar
                          TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText: 'Search products...',
                              hintStyle: const TextStyle(color: Colors.black54),
                              prefixIcon: const Icon(Icons.search, color: Colors.purple),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                          const SizedBox(height: 12),
                          // Category dropdown
                          SizedBox(
                            height: 50,
                            child: DropdownButtonFormField<String>(
                              value: selectedCategory,
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              items: categories.map((String category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(
                                    category.replaceAll('_', ' ').toUpperCase(),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedCategory = newValue!;
                                  _filterProducts();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Product list (now single column)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: filteredFlashcards.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No products found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try a different search or category',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 16),
                                itemCount: filteredFlashcards.length,
                                itemBuilder: (context, index) {
                                  return _buildProductCard(filteredFlashcards[index]);
                                },
                              ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            selectedItemColor: Colors.purple,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            elevation: 10,
            type: BottomNavigationBarType.fixed,
            iconSize: 24,
            selectedLabelStyle: const TextStyle(fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_outlined),
                activeIcon: Icon(Icons.shopping_cart),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Account',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.logout_outlined),
                activeIcon: Icon(Icons.logout),
                label: 'Logout',
              ),
            ],
            onTap: (index) {
              setState(() => _currentIndex = index);

              if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderScreen(userId: widget.userId),
                  ),
                );
              } else if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BuyerAccountSettings(userId: widget.userId),
                  ),
                );
              } else if (index == 3) {
                _showLogoutConfirmation();
              }
            },
          ),
        ),
      ),
    );
  }
}