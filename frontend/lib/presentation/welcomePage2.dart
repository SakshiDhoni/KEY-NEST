import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// Add these Firebase imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  final _contactCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  bool _isSending = false;
  bool _isFirebaseInitialized = false;
  
  // Firebase Firestore instance - will be initialized after Firebase.initializeApp()
  FirebaseFirestore? _firestore;
  
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _bounceController;
  late AnimationController _rotateController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _scaleAnimation;

  // State Variables
  String _selectedTab = 'Properties'; // Properties or Cars
  String _selectedUserType = 'Customer'; // Customer or Contractor (for Properties)
  String _selectedPropertyType = '';
  String _selectedCarBrand = '';

  // Data
  final List<String> _propertyTypes = [
    'Land', 'Bungalow', 'Flat', 'Villa', 'Plot', 'Farmhouse', 'Commercial'
  ];
  
  final List<String> _carBrands = [
    'Maruti Suzuki', 'Hyundai', 'Tata', 'Mahindra', 'Honda', 'Toyota', 
    'Ford', 'Renault', 'Nissan', 'Volkswagen', 'BMW', 'Mercedes', 'Audi'
  ];

  static const _notifyUrl = 'http://localhost:3000/api/notify';

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _initializeAnimations();
    _startAnimations();
  }

  // Initialize Firebase
  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      _firestore = FirebaseFirestore.instance;
      setState(() {
        _isFirebaseInitialized = true;
      });
      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('❌ Error initializing Firebase: $e');
      // Continue without Firebase functionality
    }
  }

  // Firebase: Store user data in Firestore
  Future<void> _storeUserData({
    required String contact,
    required String city,
    required String category, // Properties or Cars
    String? propertyType,
    String? carBrand,
    String? userType,
  }) async {
    // Check if Firebase is initialized
    if (!_isFirebaseInitialized || _firestore == null) {
      print('⚠️ Firebase not initialized, skipping data storage');
      return;
    }

    try {
      // Create user data map
      Map<String, dynamic> userData = {
        'contact': contact,
        'city': city,
        'category': category,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Add category-specific data
      if (category == 'Properties') {
        userData['propertyType'] = propertyType;
        userData['userType'] = userType;
      } else if (category == 'Cars') {
        userData['carBrand'] = carBrand;
      }

      // Determine contact type
      final isEmail = contact.contains('@');
      userData['contactType'] = isEmail ? 'email' : 'phone';

      // Store in Firestore
      await _firestore!.collection('user_inquiries').add(userData);
      
      print('✅ User data stored successfully in Firebase');
    } catch (e) {
      print('❌ Error storing user data in Firebase: $e');
      // Don't throw error to avoid disrupting the user flow
    }
  }

  Future<void> _sendWelcome() async {
    final contact = _contactCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final isPhone = contact.startsWith('+');
    final isEmail = contact.contains('@');

    if (!isPhone && !isEmail) {
      _showSnack('Enter a valid phone number (+91…) or email address.');
      return;
    }

    if (city.isEmpty) {
      _showSnack('Please enter your city.');
      return;
    }

    if (_selectedTab == 'Properties' && _selectedPropertyType.isEmpty) {
      _showSnack('Please select a property type.');
      return;
    }

    if (_selectedTab == 'Cars' && _selectedCarBrand.isEmpty) {
      _showSnack('Please select a car brand.');
      return;
    }

    setState(() => _isSending = true);

    try {
      // Store user data in Firebase first
      await _storeUserData(
        contact: contact,
        city: city,
        category: _selectedTab,
        propertyType: _selectedTab == 'Properties' ? _selectedPropertyType : null,
        carBrand: _selectedTab == 'Cars' ? _selectedCarBrand : null,
        userType: _selectedTab == 'Properties' ? _selectedUserType : null,
      );

      String message = _selectedTab == 'Properties' 
        ? '🏠 Welcome to CtoC Broker! You\'re interested in $_selectedPropertyType as a $_selectedUserType in $city. We\'ll connect you soon!'
        : '🚗 Welcome to CtoC Broker! You\'re interested in $_selectedCarBrand in $city. We\'ll connect you soon!';

      // Send notifications (existing code)
      if (isPhone) {
        final smsResp = await http.post(
          Uri.parse(_notifyUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'to': contact,
            'text': message,
            'channel': 'whatsapp',
          }),
        );
        if (smsResp.statusCode != 200) {
          throw 'WhatsApp error: ${smsResp.statusCode}';
        }
      }
      
      if (isEmail) {
        final emailResp = await http.post(
          Uri.parse(_notifyUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'to': contact,
            'text': message,
            'channel': 'email',
          }),
        );
        if (emailResp.statusCode != 200) {
          throw 'Email error: ${emailResp.statusCode}';
        }
      }

      _showSnack('Welcome message sent successfully! We\'ll be in touch soon.');
      _resetForm();
    } catch (e) {
      _showSnack('Failed to send welcome: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  // Firebase: Get user inquiries (optional - for admin dashboard)
  Stream<QuerySnapshot>? getUserInquiries() {
    if (!_isFirebaseInitialized || _firestore == null) {
      return null;
    }
    return _firestore!
        .collection('user_inquiries')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Firebase: Get inquiries by category
  Stream<QuerySnapshot>? getInquiriesByCategory(String category) {
    if (!_isFirebaseInitialized || _firestore == null) {
      return null;
    }
    return _firestore!
        .collection('user_inquiries')
        .where('category', isEqualTo: category)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Firebase: Search inquiries by city
  Future<List<QueryDocumentSnapshot>?> getInquiriesByCity(String city) async {
    if (!_isFirebaseInitialized || _firestore == null) {
      return null;
    }
    
    try {
      QuerySnapshot snapshot = await _firestore!
          .collection('user_inquiries')
          .where('city', isEqualTo: city)
          .get();
      
      return snapshot.docs;
    } catch (e) {
      print('❌ Error fetching inquiries by city: $e');
      return null;
    }
  }

  // Rest of your existing code remains the same...
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _rotateController = AnimationController(
      duration: Duration(seconds: 30),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));
    
    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    
    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.elasticOut),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _bounceController.forward();
    _rotateController.repeat();
  }

  void _resetForm() {
    _contactCtrl.clear();
    _cityCtrl.clear();
    setState(() {
      _selectedPropertyType = '';
      _selectedCarBrand = '';
      _selectedUserType = 'Customer';
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _bounceController.dispose();
    _rotateController.dispose();
    _contactCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  // Add all your existing UI methods here (_buildTopNavigation, _buildHeroSection, etc.)
  // The UI code remains exactly the same...
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            child: Column(
              children: [
                _buildTopNavigation(),
                _buildHeroSection(),
                _buildFeaturesSection(),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopNavigation() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Animated Logo
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF2563EB).withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.business_center_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'CtoC Broker',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Navigation Items
            FadeTransition(
              opacity: _fadeAnimation,
              child: Row(
                children: [
                  _buildNavItem('Properties'),
                  _buildNavItem('Cars'),
                  SizedBox(width: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: TextButton(
        onPressed: () {
          if (title == 'Properties' || title == 'Cars') {
            setState(() {
              _selectedTab = title;
              _selectedPropertyType = '';
              _selectedCarBrand = '';
            });
          }
        },
        child: Text(
          title,
          style: TextStyle(
            color: _selectedTab == title ? Color(0xFF2563EB) : Color(0xFF6B7280),
            fontSize: 16,
            fontWeight: _selectedTab == title ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

Widget _buildHeroSection() {
  return Container(
    height: 900,
    child: Stack(
      children: [
        // Background Image with Overlay
        Positioned.fill(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(_selectedTab == 'Properties' 
                    ? 'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1920&q=80'
                    : 'https://images.unsplash.com/photo-1502877338535-766e1452684a?auto=format&fit=crop&w=1920&q=80'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.3),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Content - Column layout as requested
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            children: [
              // Top Content - Text Section
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      //SizedBox(height: 10),
                      Text(
                        'Let\'s Find Your ${_selectedTab == 'Properties' ? 'Dream Property' : 'Perfect Car'}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 30),
                      Container(
                        constraints: BoxConstraints(maxWidth: 800),
                        child: Text(
                          _selectedTab == 'Properties' 
                            ? 'Welcome to CtoC Broker – one of India\'s top real estate platforms where you can easily search, buy, sell, or rent your next property. We connect buyers, sellers, and agents with trusted listings and user-friendly tools, making your property journey smooth and enjoyable.'
                            : 'Welcome to CtoC Broker – your trusted platform for buying and selling cars. We connect car buyers and sellers directly, making your car buying or selling experience smooth, transparent, and hassle-free.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 40),
              
              // Bottom Form Card
              SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack)),
                child: ScaleTransition(
                  scale: _bounceAnimation,
                  child: Center(
                    child: _buildFormCard(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildFormCard() {
  return Container(
    constraints: BoxConstraints(
      minHeight: 280, 
      minWidth: 300, 
      maxHeight: 500, 
      maxWidth: 400
    ),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      // Increased opacity for better text visibility
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
      // Added backdrop blur effect for better readability
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 30,
          offset: Offset(0, 15),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.1),
          blurRadius: 10,
          offset: Offset(0, -5),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Form content
        Flexible(
          child: _selectedTab == 'Properties'
              ? _buildPropertyForm()
              : _buildCarForm(),
        ),
        const SizedBox(height: 24),
        // Submit button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF2563EB).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _canSubmit() && !_isSending ? _sendWelcome : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSending
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Connecting...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 12),
                        Text(
                          'Send',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    ),
  );
}
  Widget _buildTabButton(String title) {
    final isSelected = _selectedTab == title;  
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = title;
            _selectedPropertyType = '';
            _selectedCarBrand = '';
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPropertyType.isEmpty ? null : _selectedPropertyType,
              hint: Text('Select Property Type', style: TextStyle(color: Colors.white.withOpacity(1))),
              isExpanded: true,
              padding: EdgeInsets.symmetric(horizontal: 16),
              dropdownColor: Color(0xFF1F2937),
              style: TextStyle(color: Colors.white),
              icon: Icon(Icons.arrow_drop_down, color: Colors.white),
              items: _propertyTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPropertyType = value ?? '';
                });
              },
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // User Type Selection (Customer/Contractor)
        Text(
          'I am a',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            _buildUserTypeButton('Customer'),
            SizedBox(width: 12),
            _buildUserTypeButton('Contractor'),
          ],
        ),
        
        SizedBox(height: 16),
        
        _buildContactField(),
        SizedBox(height: 16),
        _buildCityField(),
      ],
    );
  }

  Widget _buildCarForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Car Brand',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCarBrand.isEmpty ? null : _selectedCarBrand,
              hint: Text('Select Car Brand', style: TextStyle(color: Colors.white.withOpacity(1))),
              isExpanded: true,
              padding: EdgeInsets.symmetric(horizontal: 16),
              dropdownColor: Color(0xFF1F2937),
              style: TextStyle(color: Colors.white),
              icon: Icon(Icons.arrow_drop_down, color: Colors.white),
              items: _carBrands.map((brand) {
                return DropdownMenuItem<String>(
                  value: brand,
                  child: Text(brand, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCarBrand = value ?? '';
                });
              },
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        _buildContactField(),
        SizedBox(height: 16),
        _buildCityField(),
      ],
    );
  }

  Widget _buildUserTypeButton(String type) {
    final isSelected = _selectedUserType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedUserType = type;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF2563EB).withOpacity(0.5) : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Color(0xFF2563EB) : Colors.white.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            type,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number or Email',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _contactCtrl,
          keyboardType: TextInputType.text,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '+91XXXXXXXXXX or email@example.com',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            prefixIcon: Icon(
              _contactCtrl.text.contains('@') ? Icons.email : Icons.phone,
              color: Colors.white,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white, width: 2),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildCityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'City',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _cityCtrl,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your city',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            prefixIcon: Icon(Icons.location_city, color: Colors.white),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white, width: 2),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  bool _canSubmit() {
    final contact = _contactCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final isValidContact = contact.startsWith('+') || contact.contains('@');
    
    if (_selectedTab == 'Properties') {
      return isValidContact && city.isNotEmpty && _selectedPropertyType.isNotEmpty;
    } else {
      return isValidContact && city.isNotEmpty && _selectedCarBrand.isNotEmpty;
    }
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 100, horizontal: 40),
      color: Colors.grey[50],
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Text(
              'Why Choose CtoC Broker?',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB) ,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'We connect buyers and sellers directly, making property and car transactions seamless',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 80),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFeatureCard(
                  Icons.handshake_rounded,
                  'Direct Connection',
                  'Connect directly with property owners and car sellers without intermediaries',
                ),
                _buildFeatureCard(
                  Icons.verified_user_rounded,
                  'Verified Listings',
                  'All properties and cars are verified for authenticity and quality',
                ),
                _buildFeatureCard(
                  Icons.support_agent_rounded,
                  '24/7 Support',
                  'Round-the-clock customer support to assist you at every step',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return ScaleTransition(
      scale: _bounceAnimation,
      child: Container(
        width: 280,
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:  Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 40,
              ),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color:Color(0xFF2563EB) ,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

Widget _buildFooter() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Phone
              Row(
                children: [
                  Icon(Icons.phone, color: Colors.white.withOpacity(0.8), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '+91 98765 43210',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              // Email
              Row(
                children: [
                  Icon(Icons.email, color: Colors.white.withOpacity(0.8), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'info@ctocbroker.com',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              // Address
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white.withOpacity(0.8), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Nashik, Maharashtra  - 201309',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 8),
          Text(
            '© 2025 CtoC Broker. All rights reserved.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}
}