import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RiderLeaderboards extends StatefulWidget {
  final String userId;
  final String username;
  final String? initialSort;

  const RiderLeaderboards({
    super.key,
    required this.userId,
    required this.username,
    this.initialSort,
  });

  @override
  _RiderLeaderboardsState createState() => _RiderLeaderboardsState();
}

class _RiderLeaderboardsState extends State<RiderLeaderboards> {
  List<dynamic> _riders = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _sortBy = 'earnings';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _sortBy = widget.initialSort ?? 'earnings';
    _fetchLeaderboardData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeaderboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.254.110:5000/api/leaderboards/riders?sort_by=$_sortBy'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _riders = data['data'];
          });
          // Scroll to current user if exists
          if (widget.username.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final index = _riders.indexWhere((r) => r['username'] == widget.username);
              if (index != -1 && _scrollController.hasClients) {
                _scrollController.animateTo(
                  index * 80.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              }
            });
          }
        } else {
          setState(() {
            _errorMessage = data['error'] ?? 'Failed to load leaderboard data';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load leaderboard: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildLeaderboardItem(int index, Map<String, dynamic> rider) {
    final isCurrentUser = rider['username'] == widget.username;
    final isTopThree = index < 3;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (isCurrentUser)
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Card(
        elevation: isCurrentUser ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isCurrentUser ? Colors.purple : Colors.grey.withOpacity(0.2),
            width: isCurrentUser ? 1.5 : 0.5,
          ),
        ),
        color: isCurrentUser ? Colors.purple.withOpacity(0.05) : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isTopThree
                        ? [Colors.amber, Colors.grey, Colors.brown][index]
                        : Colors.purple.withOpacity(0.7),
                  ),
                  child: Text(
                    (index + 1).toString(),
                    style: TextStyle(
                      color: isTopThree ? Colors.white : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isTopThree ? 18 : 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rider['username'],
                        style: TextStyle(
                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                          fontSize: 16,
                          color: isCurrentUser ? Colors.purple : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${rider['barangay']}, ${rider['municipal']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₱${double.parse(rider['earnings'].toString()).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.purple[800],
                      ),
                    ),
                    Text(
                      '${rider['total_orders']} ${rider['total_orders'] == 1 ? 'delivery' : 'deliveries'}',
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
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.sort, color: Colors.purple),
        onSelected: (value) {
          setState(() {
            _sortBy = value;
          });
          _fetchLeaderboardData();
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'earnings',
            child: Row(
              children: [
                Icon(Icons.attach_money, color: Colors.purple),
                const SizedBox(width: 8),
                const Text('Sort by Earnings'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'total_orders',
            child: Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.purple),
                const SizedBox(width: 8),
                const Text('Sort by Deliveries'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _sortBy == 'earnings' ? 'Top Earners' : 'Most Deliveries',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          _buildSortButton(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Rider Leaderboards'),
        backgroundColor: Colors.purple,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLeaderboardData,
        color: Colors.purple,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                ),
              )
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.purple[300]),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _fetchLeaderboardData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _riders.length,
                          itemBuilder: (context, index) {
                            return _buildLeaderboardItem(index, _riders[index]);
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}