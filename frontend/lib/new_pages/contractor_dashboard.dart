// lib/presentation/contractor_dashboard.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'contractor_property_form.dart';
import 'contractor_car_form.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContractorDashboard extends StatefulWidget {
  final String username;
  final String email;

  const ContractorDashboard({
    super.key,
    required this.username,
    required this.email,
  });

  @override
  State<ContractorDashboard> createState() => _ContractorDashboardState();
}

class _ContractorDashboardState extends State<ContractorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<dynamic> _myProperties = [];
  List<dynamic> _myCars = [];
  bool _loading = false;

  // Stats
  int _totalProperties = 0;
  int _totalCars = 0;
  double _totalRevenue = 0.0;
  double _totalListingFees = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Refresh data when switching to property or car tabs
      if (_tabController.index == 1 || _tabController.index == 2) {
        _loadMyListings();
      }
    });
    _loadMyListings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyListings() async {
    setState(() => _loading = true);
    
    try {
      // Load contractor's properties
      final propResponse = await http.get(
        Uri.parse('http://localhost:3000/api/contractor/properties/${widget.email}'),
      );
      
      // Load contractor's cars
      final carResponse = await http.get(
        Uri.parse('http://localhost:3000/api/contractor/cars/${widget.email}'),
      );

      if (propResponse.statusCode == 200) {
        final propData = jsonDecode(propResponse.body);
        setState(() {
          _myProperties = propData['properties'] ?? [];
        });
        print('✅ Loaded ${_myProperties.length} properties');
      } else {
        print('❌ Failed to load properties: ${propResponse.statusCode}');
      }

      if (carResponse.statusCode == 200) {
        final carData = jsonDecode(carResponse.body);
        setState(() {
          _myCars = carData['cars'] ?? [];
        });
        print('✅ Loaded ${_myCars.length} cars');
      } else {
        print('❌ Failed to load cars: ${carResponse.statusCode}');
      }

      _calculateStats();
      
    } catch (e) {
      print('❌ Error loading listings: $e');
      _showSnackBar('Failed to load listings: $e', isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _calculateStats() {
    _totalProperties = _myProperties.length;
    _totalCars = _myCars.length;
    
    _totalRevenue = 0.0;
    _totalListingFees = 0.0;
    
    // Calculate revenue from booked properties
    for (var prop in _myProperties) {
      if (prop['isBooked'] == true) {
        _totalRevenue += (prop['amount'] ?? 0.0).toDouble();
      }
      // Add listing fees (₹499 per property)
      _totalListingFees += 499.0;
    }
    
    // Calculate revenue from booked cars
    for (var car in _myCars) {
      if (car['isBooked'] == true) {
        _totalRevenue += (car['price'] ?? 0.0).toDouble();
      }
      // Add listing fees (₹299 per car)
      _totalListingFees += 299.0;
    }
  }

  void _logout() async {
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
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                }
              } catch (e) {
                print('Error during logout: $e');
                _showSnackBar('Logout failed: $e', isError: true);
              }
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

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.all(16),
      ),
    );
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
              'Contractor Dashboard',
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
                      (widget.username.isNotEmpty ? widget.username.substring(0, 1) : 'C').toUpperCase(),
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
                        widget.username.isNotEmpty ? widget.username : 'Contractor',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Contractor',
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
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'My Properties (${_totalProperties})'),
                Tab(text: 'My Cars (${_totalCars})'),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyListings,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildPropertiesTab(),
            _buildCarsTab(),
          ],
        ),
      ),
      floatingActionButton: _tabController.index != 0 ? FloatingActionButton.extended(
        onPressed: () async {
          if (_tabController.index == 1) {
            // Add Property
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ContractorPropertyFormPage(
                  username: widget.username,
                  email: widget.email,
                ),
              ),
            );
            // Refresh listings after returning from form
            if (result == true || result == null) {
              await _loadMyListings();
              _showSnackBar('Property listings refreshed!');
            }
          } else {
            // Add Car
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ContractorCarFormPage(
                  username: widget.username,
                  email: widget.email,
                ),
              ),
            );
            // Refresh listings after returning from form
            if (result == true || result == null) {
              await _loadMyListings();
              _showSnackBar('Car listings refreshed!');
            }
          }
        },
        backgroundColor: _tabController.index == 1 ? Colors.blue[600] : Colors.orange[600],
        icon: Icon(_tabController.index == 1 ? Icons.home_outlined : Icons.directions_car),
        label: Text(_tabController.index == 1 ? 'Add Property' : 'Add Car'),
      ) : null,
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadMyListings,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
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
                    'Welcome back, ${widget.username.isNotEmpty ? widget.username : 'Contractor'}! 👋',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage your property and car listings',
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
                    'Properties Listed',
                    _totalProperties.toString(),
                    Icons.home,
                    Colors.blue[600]!,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Cars Listed',
                    _totalCars.toString(),
                    Icons.directions_car,
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
                    'Total Revenue',
                    '₹${_totalRevenue.toInt()}',
                    Icons.currency_rupee,
                    Colors.green[600]!,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Listing Fees Paid',
                    '₹${_totalListingFees.toInt()}',
                    Icons.payment,
                    Colors.purple[600]!,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Quick Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _loadMyListings,
                  icon: Icon(Icons.refresh),
                  label: Text('Refresh'),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    'Add Property',
                    'List a new property for rent/sale',
                    Icons.home_outlined,
                    Colors.blue[600]!,
                    () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ContractorPropertyFormPage(
                            username: widget.username,
                            email: widget.email,
                          ),
                        ),
                      );
                      if (result == true || result == null) {
                        await _loadMyListings();
                      }
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    'Add Car',
                    'List a new car for sale',
                    Icons.directions_car,
                    Colors.orange[600]!,
                    () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ContractorCarFormPage(
                            username: widget.username,
                            email: widget.email,
                          ),
                        ),
                      );
                      if (result == true || result == null) {
                        await _loadMyListings();
                      }
                    },
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Recent Activity
            if (_myProperties.isNotEmpty || _myCars.isNotEmpty) ...[
              Text(
                'Recent Listings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              
              // Show recent properties and cars
              Column(
                children: [
                  ..._myProperties.take(2).map((prop) => _buildRecentListingCard(prop, true)),
                  ..._myCars.take(2).map((car) => _buildRecentListingCard(car, false)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentListingCard(dynamic item, bool isProperty) {
    final isBooked = item['isBooked'] == true;
    final images = item['imageUrls'] ?? [];
    final title = isProperty ? item['name'] : '${item['brand']} ${item['model']}';
    final price = isProperty ? item['amount'] : item['price'];
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 60,
              child: images.isNotEmpty
                  ? Image.network(
                      images[0],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: Icon(
                          isProperty ? Icons.home : Icons.directions_car,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Icon(
                        isProperty ? Icons.home : Icons.directions_car,
                        color: Colors.grey[400],
                      ),
                    ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  item['location'] ?? 'Unknown Location',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${price ?? 'N/A'}',
                style: TextStyle(
                  color: Colors.green[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isBooked ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isBooked ? 'Sold' : 'Listed',
                  style: TextStyle(
                    color: isBooked ? Colors.green : Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
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

  Widget _buildPropertiesTab() {
    return RefreshIndicator(
      onRefresh: _loadMyListings,
      child: _loading
          ? Center(child: CircularProgressIndicator(color: Colors.blue[600]))
          : _myProperties.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_outlined, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No properties listed yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the + button to add your first property',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContractorPropertyFormPage(
                                username: widget.username,
                                email: widget.email,
                              ),
                            ),
                          );
                          if (result == true || result == null) {
                            await _loadMyListings();
                          }
                        },
                        icon: Icon(Icons.add),
                        label: Text('Add First Property'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _myProperties.length,
                  itemBuilder: (context, index) {
                    final property = _myProperties[index];
                    return _buildPropertyCard(property);
                  },
                ),
    );
  }

  Widget _buildCarsTab() {
    return RefreshIndicator(
      onRefresh: _loadMyListings,
      child: _loading
          ? Center(child: CircularProgressIndicator(color: Colors.orange[600]))
          : _myCars.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No cars listed yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the + button to add your first car',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContractorCarFormPage(
                                username: widget.username,
                                email: widget.email,
                              ),
                            ),
                          );
                          if (result == true || result == null) {
                            await _loadMyListings();
                          }
                        },
                        icon: Icon(Icons.add),
                        label: Text('Add First Car'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _myCars.length,
                  itemBuilder: (context, index) {
                    final car = _myCars[index];
                    return _buildCarCard(car);
                  },
                ),
    );
  }

  Widget _buildPropertyCard(dynamic property) {
    final isBooked = property['isBooked'] == true;
    final images = property['imageUrls'] ?? [];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: images.isNotEmpty
                        ? Image.network(
                            images[0],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.home, size: 50, color: Colors.grey[400]),
                          ),
                  ),
                ),
                if (isBooked)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'BOOKED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Image count indicator
                if (images.length > 1)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${images.length} photos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property['name'] ?? 'Property',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property['location'] ?? 'Location',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${property['amount'] ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isBooked ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isBooked ? 'Sold' : 'Listed',
                          style: TextStyle(
                            color: isBooked ? Colors.green : Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildCarCard(dynamic car) {
    final isBooked = car['isBooked'] == true;
    final images = car['imageUrls'] ?? [];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: images.isNotEmpty
                        ? Image.network(
                            images[0],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.directions_car, size: 50, color: Colors.grey[400]),
                          ),
                  ),
                ),
                if (isBooked)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'SOLD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Image count indicator
                if (images.length > 1)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${images.length} photos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${car['brand'] ?? ''} ${car['model'] ?? ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          car['location'] ?? 'Location',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${car['price'] ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isBooked ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isBooked ? 'Sold' : 'Listed',
                          style: TextStyle(
                            color: isBooked ? Colors.green : Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
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
    );
  }
}
