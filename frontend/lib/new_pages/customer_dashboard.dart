// lib/presentation/dashboard_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';


class DashboardPage extends StatefulWidget {
  final String initialTab;
  final String initialLocation;
  final String username;
  final String initialFilter;
  final String email;

  const DashboardPage({
    super.key,
    required this.initialTab,
    required this.initialLocation,
    required this.username,
    required this.initialFilter,
    required this.email,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _propLocationCtr;
  late TextEditingController _propTypeCtr;
  late TextEditingController _carLocCtr;
  late TextEditingController _carModelCtr;

  List<dynamic> _properties = [];
  List<dynamic> _cars = [];
  List<dynamic> _bookedItems = [];
  bool _loading = false;

  // User data from widget parameters
  late String _userName;
  late String _userEmail;

  // Stats for overview
  int _totalBookings = 0;
  int _totalSaved = 0;
  int _availableProperties = 0;
  int _availableCars = 0;
  double _totalSpent = 0.0;

  @override
  void initState() {
    super.initState();
    
    _userName = widget.username;
    _userEmail = widget.email;
    
    _tabController = TabController(length: 4, vsync: this) // Changed to 4 tabs for Overview
      ..addListener(() => setState(() {}));
    _propLocationCtr = TextEditingController(
      text: widget.initialTab == 'Properties' ? widget.initialLocation : '',
    );
    _propTypeCtr = TextEditingController(
      text: widget.initialTab == 'Properties' ? widget.initialFilter : '',
    );
    _carLocCtr = TextEditingController(
      text: widget.initialTab == 'Cars' ? widget.initialLocation : '',
    );
    _carModelCtr = TextEditingController(
      text: widget.initialTab == 'Cars' ? widget.initialFilter : '',
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always start with Overview tab (index 0)
      _tabController.index = 0;
      
      // Load initial data for overview
      _loadBookedItems();
      _searchProperties();
      _searchCars();
    
      if (widget.initialTab == 'Properties') {
      } else if (widget.initialTab == 'Cars') {
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _propLocationCtr.dispose();
    _propTypeCtr.dispose();
    _carLocCtr.dispose();
    _carModelCtr.dispose();
    super.dispose();
  }

  Future<void> _loadBookedItems() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/booked-items/${_userEmail}'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _bookedItems = data['bookedItems'] ?? [];
        });
        _calculateStats();
      }
    } catch (e) {
      print('Error loading booked items: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _calculateStats() {
    _totalBookings = _bookedItems.length;
    _availableProperties = _properties.length;
    _availableCars = _cars.length;
    
    _totalSpent = 0.0;
    for (var item in _bookedItems) {
      _totalSpent += (item['amount'] ?? 0.0);
    }
  }

  Future<void> _searchProperties() async {
    setState(() => _loading = true);
    final uri = Uri.parse('http://localhost:3000/api/properties').replace(
      queryParameters: {
        'location': _propLocationCtr.text.isNotEmpty ? _propLocationCtr.text : 'jalgoan',
        'name': _propTypeCtr.text.isNotEmpty ? _propTypeCtr.text : 'Villa',
        'includeBooked': 'false',
      },
    );
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['properties'] as List<dynamic>;
        setState(() {
          _properties = data;
          _availableProperties = data.length;
          _loading = false;
        });
      } else {
        throw Exception('Failed to load properties');
      }
    } catch (e) {
      print('Error searching properties: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _searchCars() async {
    setState(() => _loading = true);
    final uri = Uri.parse('http://localhost:3000/api/cars').replace(
      queryParameters: {
        'location': _carLocCtr.text,
        'model': _carModelCtr.text,
        'includeBooked': 'false',
      },
    );
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['cars'] as List<dynamic>;
        setState(() {
          _cars = data;
          _availableCars = data.length;
          _loading = false;
        });
      } else {
        throw Exception('Failed to load cars');
      }
    } catch (e) {
      print('Error searching cars: $e');
      setState(() => _loading = false);
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
               FirebaseAuth.instance.signOut();
             Navigator.pushReplacementNamed(context, '/welcome');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _changeProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Profile'),
        content: const Text('Profile change functionality will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _bookItem(dynamic item, bool isProperty) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => PaymentDialog(
        item: item, 
        isProperty: isProperty,
        userEmail: _userEmail,
        username: _userName,
      ),
    );
    
    if (result == true) {
      setState(() {
        if (isProperty) {
          _properties.removeWhere((p) => p['id'] == item['id']);
        } else {
          _cars.removeWhere((c) => c['id'] == item['id']);
        }
      });
      
      await _loadBookedItems();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${isProperty ? 'Property' : 'Car'} "${isProperty ? item['name'] : '${item['brand']} ${item['model']}'}" booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[700]!],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.business_center,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Customer Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue[600],
                    child: Text(
                      _userName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Customer',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 20),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('Change Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              } else if (value == 'profile') {
                _changeProfile();
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.blue[600],
              indicatorWeight: 3,
              labelColor: Colors.blue[600],
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Properties'),
                Tab(text: 'Cars'),
                Tab(text: 'My Bookings'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_tabController.index > 0 && _tabController.index < 3) _buildSearchBar(),
          if (_loading) 
            LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildGrid(_properties, true, false),
                _buildGrid(_cars, false, false),
                _buildBookedItemsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${_userName}! 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Find your perfect property or car today',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Bookings',
                  _totalBookings.toString(),
                  Icons.bookmark,
                  Colors.green[600]!,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Spent',
                  '₹${_totalSpent.toInt()}',
                  Icons.currency_rupee,
                  Colors.orange[600]!,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Properties Found',
                  _availableProperties.toString(),
                  Icons.home,
                  Colors.blue[600]!,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Cars Found',
                  _availableCars.toString(),
                  Icons.directions_car,
                  Colors.purple[600]!,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 24),
          
          // Quick Actions
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Search Properties',
                  'Find your dream home or office',
                  Icons.search,
                  Colors.blue[600]!,
                  () {
                    _tabController.index = 1;
                    _searchProperties();
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  'Search Cars',
                  'Discover your perfect vehicle',
                  Icons.search,
                  Colors.purple[600]!,
                  () {
                    _tabController.index = 2;
                    _searchCars();
                  },
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'My Bookings',
                  'View your booked items',
                  Icons.bookmark,
                  Colors.green[600]!,
                  () => _tabController.index = 3,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  'Refresh Data',
                  'Update latest listings',
                  Icons.refresh,
                  Colors.orange[600]!,
                  () {
                    _searchProperties();
                    _searchCars();
                    _loadBookedItems();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isProp = _tabController.index == 1;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                color: Colors.grey[50],
              ),
              child: TextField(
                controller: isProp ? _propLocationCtr : _carLocCtr,
                decoration: InputDecoration(
                  labelText: 'Location',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.location_on_outlined, 
                    color: Colors.grey[500], size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                color: Colors.grey[50],
              ),
              child: TextField(
                controller: isProp ? _propTypeCtr : _carModelCtr,
                decoration: InputDecoration(
                  labelText: isProp ? 'Property Type' : 'Model',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(isProp ? Icons.home_outlined : Icons.directions_car_outlined,
                    color: Colors.grey[500], size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[700]!],
              ),
            ),
            child: ElevatedButton(
              onPressed: isProp ? _searchProperties : _searchCars,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, color: Colors.white, size: 20),
                  SizedBox(width: 4),
                  Text('Search', 
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookedItemsTab() {
    if (_bookedItems.isEmpty && !_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No bookings yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Book your first property or car to see it here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 
                      MediaQuery.of(context).size.width > 800 ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.70,
      ),
      itemCount: _bookedItems.length,
      itemBuilder: (_, i) => ListingCard(
        data: _bookedItems[i],
        isProperty: _bookedItems[i]['itemType'] == 'property',
        isBooked: true,
        onBook: null,
      ),
    );
  }

  Widget _buildGrid(List<dynamic> items, bool isProperty, bool isBooked) {
    if (items.isEmpty && !_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isProperty ? Icons.home_outlined : Icons.directions_car_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${isProperty ? 'properties' : 'cars'} found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 
                      MediaQuery.of(context).size.width > 800 ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.70,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => ListingCard(
        data: items[i],
        isProperty: isProperty,
        isBooked: isBooked,
        onBook: !isBooked ? () => _bookItem(items[i], isProperty) : null,
      ),
    );
  }
}

// Keep all your existing PaymentDialog and ListingCard classes exactly the same
class PaymentDialog extends StatefulWidget {
  final dynamic item;
  final bool isProperty;
  final String userEmail;
  final String username;

  const PaymentDialog({
    super.key, 
    required this.item, 
    required this.isProperty,
    required this.userEmail,
    required this.username,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  bool _isProcessing = false;

  Future<void> _processPayment(String paymentMethod) async {
    setState(() => _isProcessing = true);
    
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/book-item'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userEmail': widget.userEmail,
          'username': widget.username,
          'itemId': widget.item['id'],
          'itemType': widget.isProperty ? 'property' : 'car',
          'itemName': widget.isProperty 
            ? widget.item['name'] 
            : '${widget.item['brand']} ${widget.item['model']}',
          'itemLocation': widget.item['location'],
          'amount': widget.item[widget.isProperty ? 'amount' : 'price'],
          'paymentMethod': paymentMethod,
        }),
      );

      if (response.statusCode == 201) {
        setState(() => _isProcessing = false);
        Navigator.of(context).pop(true);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Booking failed');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.item[widget.isProperty ? 'amount' : 'price'] ?? 0;
    final itemName = widget.isProperty 
      ? widget.item['name'] 
      : '${widget.item['brand']} ${widget.item['model']}';
    
    return AlertDialog(
      title: Text('Confirm ${widget.isProperty ? 'Property' : 'Car'} Booking'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.isProperty ? 'Property' : 'Car'}: $itemName'),
          Text('Location: ${widget.item['location']}'),
          const SizedBox(height: 16),
          Text(
            'Amount: ₹$amount',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Choose payment method:'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : () => _processPayment('UPI'),
                  icon: const Icon(Icons.payment),
                  label: const Text('UPI'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : () => _processPayment('Card'),
                  icon: const Icon(Icons.credit_card),
                  label: const Text('Card'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        if (_isProcessing)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Processing...'),
              ],
            ),
          ),
      ],
    );
  }
}

class ListingCard extends StatefulWidget {
  final dynamic data;
  final bool isProperty;
  final bool isBooked;
  final VoidCallback? onBook;
  
  const ListingCard({
    super.key, 
    required this.data, 
    required this.isProperty,
    required this.isBooked,
    this.onBook,
  });

  @override
  State<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<ListingCard> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _scaleController;
  int _currentPage = 0;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _nextPage(int totalImages) {
    if (totalImages > 1) {
      setState(() {
        _currentPage = (_currentPage + 1) % totalImages;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _previousPage(int totalImages) {
    if (totalImages > 1) {
      setState(() {
        _currentPage = (_currentPage - 1 + totalImages) % totalImages;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> images =
        (widget.data['imageUrls'] ?? widget.data['images'] ?? []).cast<String>();
    final title = widget.isProperty
        ? widget.data['name'] ?? 'No Name'
        : '${widget.data['brand'] ?? ''} ${widget.data['model'] ?? ''}';
    final location = widget.data['location'] ?? 'Unknown';
    final price = widget.isProperty
        ? '₹${widget.data['amount'] ?? 'N/A'}'
        : '₹${widget.data['price'] ?? 'N/A'}';

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _scaleController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _scaleController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_scaleController.value * 0.02),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.08),
                    blurRadius: _isHovered ? 20 : 10,
                    offset: Offset(0, _isHovered ? 8 : 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: images.isNotEmpty
                                ? PageView.builder(
                                    controller: _pageController,
                                    itemCount: images.length,
                                    itemBuilder: (context, index) {
                                      return Image.network(
                                        images[index],
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey[200],
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.grey[400],
                                            size: 40,
                                          ),
                                        ),
                                        loadingBuilder: (_, child, loadingProgress) =>
                                            loadingProgress == null
                                                ? child
                                                : Container(
                                                    color: Colors.grey[100],
                                                    child: const Center(
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                    ),
                                                  ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      widget.isProperty ? Icons.home : Icons.directions_car,
                                      color: Colors.grey[400],
                                      size: 40,
                                    ),
                                  ),
                          ),
                        ),
                        
                        if (widget.isBooked)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'BOOKED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        
                        if (images.length > 1 && _isHovered) ...[
                          Positioned(
                            left: 8,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: _navButton(
                                Icons.chevron_left,
                                () => _previousPage(images.length),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: _navButton(
                                Icons.chevron_right,
                                () => _nextPage(images.length),
                              ),
                            ),
                          ),
                        ],
                        
                        if (images.length > 1)
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                images.length,
                                (index) => Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index == _currentPage
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                price,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green[600],
                                ),
                              ),
                              if (widget.onBook != null) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  height: 32,
                                  child: ElevatedButton(
                                    onPressed: widget.onBook,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[600],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: const Text(
                                      'Book Now',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.6),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}
