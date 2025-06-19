// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class WelcomeScreen extends StatefulWidget {
//   const WelcomeScreen({super.key});
  
//   @override
//   State<WelcomeScreen> createState() => _WelcomeScreenState();
// }

// class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
//   final _contactCtrl = TextEditingController();
//   bool _isSending = false;
//   late AnimationController _fadeController;
//   late AnimationController _slideController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;

//   static const _notifyUrl = 'http://localhost:3000/api/notify';

//   @override
//   void initState() {
//     super.initState();
//     _fadeController = AnimationController(
//       duration: Duration(seconds: 2),
//       vsync: this,
//     );
//     _slideController = AnimationController(
//       duration: Duration(milliseconds: 1500),
//       vsync: this,
//     );
    
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
//     );
    
//     _slideAnimation = Tween<Offset>(
//       begin: Offset(0, 0.5),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
//     _fadeController.forward();
//     _slideController.forward();
//   }

//   Future<void> _sendWelcome() async {
//     final input = _contactCtrl.text.trim();
//     final isPhone = input.startsWith('+');
//     final isEmail = input.contains('@');

//     if (!isPhone && !isEmail) {
//       _showSnack('Enter a valid phone number (+91…) or email address.');
//       return;
//     }

//     setState(() => _isSending = true);

//     try {
//       if (isPhone) {
//         final smsResp = await http.post(
//           Uri.parse(_notifyUrl),
//           headers: {'Content-Type': 'application/json'},
//           body: jsonEncode({
//             'to': input,
//             'text': '👋 Welcome to CtoC Broker! Thanks for visiting.',
//             'channel': 'whatsapp',
//           }),
//         );
//         if (smsResp.statusCode != 200) {
//           throw 'WhatsApp error: ${smsResp.statusCode}';
//         }
//       }
      
//       if (isEmail) {
//         final emailResp = await http.post(
//           Uri.parse(_notifyUrl),
//           headers: {'Content-Type': 'application/json'},
//           body: jsonEncode({
//   'to': input,
//   'text': "👋 Hello! Welcome to CtoC Broker. We'll be in touch!",
//   'channel': 'email',
// }),);
//         if (emailResp.statusCode != 200) {
//           throw 'Email error: ${emailResp.statusCode}';
//         }
//       }

//       //Navigator.pushReplacementNamed(context, '/home');
//     } catch (e) {
//       _showSnack('Failed to send welcome: $e');
//     } finally {
//       setState(() => _isSending = false);
//     }
//   }

//   void _showSnack(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: Color(0xFF7C3AED),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _fadeController.dispose();
//     _slideController.dispose();
//     _contactCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final input = _contactCtrl.text.trim();
//     final isValid = input.startsWith('+') || input.contains('@');

//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Top Navigation Bar
//             _buildTopNavigation(),
            
//             // Hero Section with Contact Form
//             _buildHeroSection(isValid),
            
//             // Features Section
//             _buildFeaturesSection(),
            
//             // Footer
//             _buildFooter(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTopNavigation() {
//     return Container(
//       height: 80,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: EdgeInsets.symmetric(horizontal: 20),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             // Logo and Company Name
//             Row(
//               children: [
//                 Container(
//                   width: 50,
//                   height: 50,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(
//                     Icons.business_center,
//                     color: Colors.white,
//                     size: 30,
//                   ),
//                 ),
//                 SizedBox(width: 12),
//                 Text(
//                   'CtoC Broker',
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF4C1D95),
//                   ),
//                 ),
//               ],
//             ),
            
//             // Navigation Items
//             Row(
//               children: [
//                 //_buildNavItem('Home'),
//                 _buildNavItem('Properties'),
//                 _buildNavItem('Cars'),
//                 _buildNavItem('About'),
//                 SizedBox(width: 20),
//                 _buildLoginButton(),
//                 SizedBox(width: 10),
//                 _buildRegisterButton(),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem(String title) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 15),
//       child: TextButton(
//         onPressed: () {},
//         child: Text(
//           title,
//           style: TextStyle(
//             color: Color(0xFF374151),
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLoginButton() {
//     return OutlinedButton(
//       onPressed: () {},
//       style: OutlinedButton.styleFrom(
//         side: BorderSide(color: Color(0xFF7C3AED)),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       ),
//       child: Text(
//         'Login',
//         style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w600),
//       ),
//     );
//   }

//   Widget _buildRegisterButton() {
//     return ElevatedButton(
//       onPressed: () {},
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Color(0xFF7C3AED),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       ),
//       child: Text(
//         'Register',
//         style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//       ),
//     );
//   }

//   Widget _buildHeroSection(bool isValid) {
//     return Container(
//       height: 700,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Color(0xFF4C1D95).withOpacity(0.9),
//             Color(0xFF7C3AED).withOpacity(0.8),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//       child: Stack(
//         children: [
//           // Background Images with Animation
//           Positioned.fill(
//             child: FadeTransition(
//               opacity: _fadeAnimation,
//               child: Container(
//                 decoration: BoxDecoration(
//                   image: DecorationImage(
//                     image: NetworkImage('https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&w=1200&q=80'),
//                     fit: BoxFit.cover,
//                     opacity: 0.3,
//                   ),
//                 ),
//               ),
//             ),
//           ),
          
//           // Content
//           Center(
//             child: SlideTransition(
//               position: _slideAnimation,
//               child: FadeTransition(
//                 opacity: _fadeAnimation,
//                 child: Container(
//                   width: 600,
//                   padding: EdgeInsets.all(40),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.95),
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.2),
//                         blurRadius: 20,
//                         offset: Offset(0, 10),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Logo
//                       Container(
//                         width: 80,
//                         height: 80,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Icon(
//                           Icons.business_center,
//                           color: Colors.white,
//                           size: 40,
//                         ),
//                       ),
//                       SizedBox(height: 24),
                      
//                       Text(
//                         'Welcome to CtoC Broker',
//                         style: TextStyle(
//                           fontSize: 32,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF4C1D95),
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       SizedBox(height: 16),
//                       Text(
//                         'Your trusted platform for buying and selling properties & cars.\nEnter your phone number (+91…) or email to connect with us.',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey[600],
//                           height: 1.5,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       SizedBox(height: 32),
                      
//                       // Contact Input Field
//                       TextField(
//                         controller: _contactCtrl,
//                         keyboardType: TextInputType.text,
//                         decoration: InputDecoration(
//                           labelText: 'Phone number or Email',
//                           hintText: '+91XXXXXXXXXX or email@example.com',
//                          prefixIcon: Icon(
//   _contactCtrl.text.contains('@') ? Icons.email : Icons.phone,
//   color: Color(0xFF7C3AED),
// ),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide(color: Color(0xFF7C3AED), width: 2),
//                           ),
//                           filled: true,
//                           fillColor: Colors.grey[50],
//                         ),
//                         onChanged: (_) => setState(() {}),
//                       ),
//                       SizedBox(height: 24),
                      
//                       // Get Started Button
//                       SizedBox(
//                         width: double.infinity,
//                         height: 56,
//                         child: ElevatedButton(
//                           onPressed: isValid && !_isSending ? _sendWelcome : null,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Color(0xFF7C3AED),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             elevation: 4,
//                           ),
//                           child: _isSending
//                               ? Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     SizedBox(
//                                       width: 20,
//                                       height: 20,
//                                       child: CircularProgressIndicator(
//                                         color: Colors.white,
//                                         strokeWidth: 2,
//                                       ),
//                                     ),
//                                     SizedBox(width: 12),
//                                     Text(
//                                       'Connecting...',
//                                       style: TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.w600,
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                                   ],
//                                 )
//                               : Text(
//                                   'Get Started',
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                         ),
//                       ),
                      
//                       SizedBox(height: 16),
                      
//                       // Privacy Note
//                       Text(
//                         'We respect your privacy. Your information is secure with us.',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey[500],
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFeaturesSection() {
//     return Container(
//       padding: EdgeInsets.symmetric(vertical: 80, horizontal: 20),
//       color: Colors.grey[50],
//       child: Column(
//         children: [
//           Text(
//             'Why Choose CtoC Broker?',
//             style: TextStyle(
//               fontSize: 36,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF4C1D95),
//             ),
//           ),
//           SizedBox(height: 20),
//           Text(
//             'We connect buyers and sellers directly, making property and car transactions seamless',
//             style: TextStyle(
//               fontSize: 18,
//               color: Colors.grey[700],
//             ),
//             textAlign: TextAlign.center,
//           ),
//           SizedBox(height: 60),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildFeatureCard(
//                 Icons.handshake,
//                 'Direct Connection',
//                 'Connect directly with property owners and car sellers without intermediaries',
//                 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?auto=format&fit=crop&w=400&q=80',
//               ),
//               _buildFeatureCard(
//                 Icons.verified_user,
//                 'Verified Listings',
//                 'All properties and vehicles are verified for authenticity and quality',
//                 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?auto=format&fit=crop&w=400&q=80',
//               ),
//               _buildFeatureCard(
//                 Icons.support_agent,
//                 '24/7 Support',
//                 'Round-the-clock customer support to help you through your buying journey',
//                 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?auto=format&fit=crop&w=400&q=80',
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFeatureCard(IconData icon, String title, String description, String imageUrl) {
//     return Container(
//       width: 300,
//       child: Card(
//         elevation: 8,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: Column(
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//               child: Image.network(
//                 imageUrl,
//                 height: 200,
//                 width: double.infinity,
//                 fit: BoxFit.cover,
//               ),
//             ),
//             Padding(
//               padding: EdgeInsets.all(24),
//               child: Column(
//                 children: [
//                   Container(
//                     padding: EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Color(0xFF7C3AED).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Icon(
//                       icon,
//                       size: 40,
//                       color: Color(0xFF7C3AED),
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF4C1D95),
//                     ),
//                   ),
//                   SizedBox(height: 12),
//                   Text(
//                     description,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildFooter() {
//     return Container(
//       padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
//       color: Color(0xFF1F2937),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Company Info
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Icon(Icons.business_center, color: Colors.white, size: 24),
//                       ),
//                       SizedBox(width: 12),
//                       Text(
//                         'CtoC Broker',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20),
//                   Text(
//                     'Connecting buyers and sellers\ndirectly since 2024',
//                     style: TextStyle(color: Colors.grey[400], fontSize: 16),
//                   ),
//                 ],
//               ),
              
//               // Contact Info
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Contact Us',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   _buildContactItem(Icons.location_on, '123 Business Street\nCity, State 12345'),
//                   SizedBox(height: 12),
//                   _buildContactItem(Icons.phone, '+1 (555) 123-4567'),
//                   SizedBox(height: 12),
//                   _buildContactItem(Icons.email, 'info@ctocbroker.com'),
//                 ],
//               ),
              
//               // Quick Links
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Quick Links',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   _buildFooterLink('Properties for Sale'),
//                   _buildFooterLink('Properties for Rent'),
//                   _buildFooterLink('Cars for Sale'),
//                   _buildFooterLink('About Us'),
//                   _buildFooterLink('Contact'),
//                 ],
//               ),
//             ],
//           ),
//           SizedBox(height: 40),
//           Divider(color: Colors.grey[600]),
//           SizedBox(height: 20),
//           Text(
//             '© 2024 CtoC Broker. All rights reserved.',
//             style: TextStyle(color: Colors.grey[400], fontSize: 14),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildContactItem(IconData icon, String text) {
//     return Row(
//       children: [
//         Icon(icon, color: Color(0xFF7C3AED), size: 20),
//         SizedBox(width: 12),
//         Text(
//           text,
//           style: TextStyle(color: Colors.grey[300], fontSize: 14),
//         ),
//       ],
//     );
//   }

//   Widget _buildFooterLink(String text) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: 8),
//       child: TextButton(
//         onPressed: () {},
//         child: Text(
//           text,
//           style: TextStyle(color: Colors.grey[300], fontSize: 14),
//         ),
//       ),
//     );
//   }
// }

// // // Home Page (after successful welcome)
// // class HomePage extends StatefulWidget {
// //   @override
// //   _HomePageState createState() => _HomePageState();
// // }

// // class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
// //   late AnimationController _fadeController;
// //   late Animation<double> _fadeAnimation;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _fadeController = AnimationController(
// //       duration: Duration(seconds: 1),
// //       vsync: this,
// //     );
// //     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
// //       CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
// //     );
// //     _fadeController.forward();
// //   }

// //   @override
// //   void dispose() {
// //     _fadeController.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('CtoC Broker'),
// //         backgroundColor: Color(0xFF7C3AED),
// //         foregroundColor: Colors.white,
// //         elevation: 0,
// //       ),
// //       body: FadeTransition(
// //         opacity: _fadeAnimation,
// //         child: Container(
// //           decoration: BoxDecoration(
// //             gradient: LinearGradient(
// //               colors: [
// //                 Color(0xFF4C1D95).withOpacity(0.1),
// //                 Color(0xFF7C3AED).withOpacity(0.1),
// //               ],
// //               begin: Alignment.topLeft,
// //               end: Alignment.bottomRight,
// //             ),
// //           ),
// //           child: Center(
// //             child: Column(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: [
// //                 Container(
// //                   width: 120,
// //                   height: 120,
// //                   decoration: BoxDecoration(
// //                     gradient: LinearGradient(
// //                       colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
// //                       begin: Alignment.topLeft,
// //                       end: Alignment.bottomRight,
// //                     ),
// //                     borderRadius: BorderRadius.circular(30),
// //                   ),
// //                   child: Icon(
// //                     Icons.check_circle,
// //                     color: Colors.white,
// //                     size: 60,
// //                   ),
// //                 ),
// //                 SizedBox(height: 32),
// //                 Text(
// //                   'Welcome to CtoC Broker!',
// //                   style: TextStyle(
// //                     fontSize: 28,
// //                     fontWeight: FontWeight.bold,
// //                     color: Color(0xFF4C1D95),
// //                   ),
// //                 ),
// //                 SizedBox(height: 16),
// //                 Text(
// //                   'Thank you for joining us. We\'ll be in touch soon!',
// //                   style: TextStyle(
// //                     fontSize: 16,
// //                     color: Colors.grey[600],
// //                   ),
// //                   textAlign: TextAlign.center,
// //                 ),
// //                 SizedBox(height: 40),
// //                 ElevatedButton(
// //                   onPressed: () {
// //                     Navigator.pushReplacementNamed(context, '/');
// //                   },
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: Color(0xFF7C3AED),
// //                     padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
// //                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //                   ),
// //                   child: Text(
// //                     'Explore More',
// //                     style: TextStyle(
// //                       fontSize: 16,
// //                       fontWeight: FontWeight.w600,
// //                       color: Colors.white,
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }