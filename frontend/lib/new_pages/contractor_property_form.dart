// lib/presentation/contractor_property_form.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class ContractorPropertyFormPage extends StatefulWidget {
  final String username;
  final String email;

  const ContractorPropertyFormPage({
    super.key,
    required this.username,
    required this.email,
  });

  @override
  State<ContractorPropertyFormPage> createState() => _PropertyFormState();
}

class _PropertyFormState extends State<ContractorPropertyFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtr = TextEditingController();
  final _locationCtr = TextEditingController();
  final _amountCtr = TextEditingController();
  final _contractorNameCtr = TextEditingController();
  final _contractorPhoneCtr = TextEditingController();
  final _vacancyCtr = TextEditingController();
  final _discountCtr = TextEditingController();
  final _descriptionCtr = TextEditingController();

  // Image handling
  final List<XFile> _pickedFiles = [];
  final List<Uint8List> _pickedBytes = [];
  final _picker = ImagePicker();

  // State variables
  bool _isSubmitting = false;
  String _selectedPropertyType = '';
  int _currentStep = 0;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Property types
  final List<Map<String, dynamic>> _propertyTypes = [
    {'name': 'Villa', 'icon': Icons.home, 'color': Colors.blue},
    {'name': 'Apartment', 'icon': Icons.apartment, 'color': Colors.green},
    {'name': 'Office', 'icon': Icons.business, 'color': Colors.orange},
    {'name': 'Shop', 'icon': Icons.store, 'color': Colors.purple},
    {'name': 'Land', 'icon': Icons.landscape, 'color': Colors.brown},
    {'name': 'Warehouse', 'icon': Icons.warehouse, 'color': Colors.red},
  ];

  static const _apiUrl = 'http://localhost:3000/api/contractor_property';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _contractorNameCtr.text = widget.username.isNotEmpty ? widget.username : 'Contractor';
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameCtr.dispose();
    _locationCtr.dispose();
    _amountCtr.dispose();
    _contractorNameCtr.dispose();
    _contractorPhoneCtr.dispose();
    _vacancyCtr.dispose();
    _discountCtr.dispose();
    _descriptionCtr.dispose();
    super.dispose();
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
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    final List<XFile>? files = await _picker.pickMultiImage();
    if (files != null && files.isNotEmpty) {
      for (final file in files) {
        if (_pickedFiles.any((f) => f.path == file.path)) continue;
        final bytes = await file.readAsBytes();
        _pickedFiles.add(file);
        _pickedBytes.add(bytes);
      }
      setState(() {});
    }
  }

  void _removeImage(int index) {
    setState(() {
      _pickedFiles.removeAt(index);
      _pickedBytes.removeAt(index);
    });
  }

  // Payment dialog before submission
  Future<bool> _showPaymentDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.blue[600]),
            SizedBox(width: 8),
            Text('Property Listing Fee'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To list your property, a listing fee is required:'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Listing Fee:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('₹499', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✓ Valid for 60 days', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      Text('✓ Unlimited photo uploads', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      Text('✓ Priority listing placement', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      Text('✓ Enhanced visibility', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Choose payment method:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, true);
                    _showSnackBar('Payment successful! Processing your listing...', isError: false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(Icons.payment, size: 18),
                  label: Text('Pay ₹499'),
                ),
              ),
            ],
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFiles.isEmpty) {
      _showSnackBar('Please select at least one image', isError: true);
      return;
    }
    if (_selectedPropertyType.isEmpty) {
      _showSnackBar('Please select a property type', isError: true);
      return;
    }

    // Show payment dialog first
    final paymentSuccess = await _showPaymentDialog();
    if (!paymentSuccess) {
      _showSnackBar('Payment cancelled. Property not submitted.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final uri = Uri.parse(_apiUrl);
    final req = http.MultipartRequest('POST', uri)
      ..fields['name'] = _nameCtr.text
      ..fields['location'] = _locationCtr.text
      ..fields['amount'] = _amountCtr.text
      ..fields['contractorName'] = _contractorNameCtr.text
      ..fields['contractorPhone'] = _contractorPhoneCtr.text
      ..fields['vacancies'] = _vacancyCtr.text
      ..fields['discount'] = _discountCtr.text
      ..fields['propertyType'] = _selectedPropertyType
      ..fields['description'] = _descriptionCtr.text
      ..fields['contractorEmail'] = widget.email
      ..fields['paymentStatus'] = 'completed'
      ..fields['listingFee'] = '499';

    for (int i = 0; i < _pickedFiles.length; i++) {
      final file = _pickedFiles[i];
      final bytes = _pickedBytes[i];
      final fieldName = 'images';

      if (kIsWeb) {
        req.files.add(http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: file.name,
          contentType: MediaType(
            file.mimeType!.split('/')[0],
            file.mimeType!.split('/')[1],
          ),
        ));
      } else {
        req.files.add(await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          contentType: MediaType(
            file.mimeType!.split('/')[0],
            file.mimeType!.split('/')[1],
          ),
        ));
      }
    }

    try {
      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      setState(() => _isSubmitting = false);

      if (res.statusCode == 201) {
        _showSnackBar('Property listed successfully! 🎉🏠');
        _showSuccessDialog();
      } else {
        final error = jsonDecode(res.body);
        _showSnackBar('Error: ${error['error'] ?? 'Something went wrong'}', isError: true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showSnackBar('Network Error: $e', isError: true);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 64),
            SizedBox(height: 16),
            Text('Property Listed Successfully!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your property has been successfully added to our platform.'),
            SizedBox(height: 12),
            Text('It will now appear in your "My Properties" section.'),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    _resetForm(); // Reset form for new listing
                  },
                  child: Text('Add Another'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to dashboard
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                  child: Text('View Dashboard'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameCtr.clear();
    _locationCtr.clear();
    _amountCtr.clear();
    _contractorPhoneCtr.clear();
    _vacancyCtr.clear();
    _discountCtr.clear();
    _descriptionCtr.clear();
    _contractorNameCtr.text = widget.username.isNotEmpty ? widget.username : 'Contractor';
    setState(() {
      _pickedFiles.clear();
      _pickedBytes.clear();
      _selectedPropertyType = '';
      _currentStep = 0;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.all(16),
        action: !isError ? SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => Navigator.pop(context),
        ) : null,
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
              'Add Property',
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
                      widget.username.isNotEmpty
                          ? widget.username.substring(0, 1).toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.username.isNotEmpty ? widget.username : 'Contractor',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 20),
                ],
              ),
            ),
            itemBuilder: (context) => [
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
              if (value == 'logout') _logout();
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Colors.blue[600],
              ),
            ),
            child: Stepper(
              currentStep: _currentStep,
              onStepTapped: (step) => setState(() => _currentStep = step),
              controlsBuilder: (context, details) {
                return Row(
                  children: [
                    if (details.stepIndex < 2)
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Next'),
                      ),
                    const SizedBox(width: 8),
                    if (details.stepIndex > 0)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                  ],
                );
              },
              onStepContinue: () {
                if (_currentStep < 2) {
                  setState(() => _currentStep++);
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                }
              },
              steps: [
                Step(
                  title: const Text('Basic Info'),
                  content: _buildBasicInfoStep(),
                  isActive: _currentStep >= 0,
                ),
                Step(
                  title: const Text('Property Details'),
                  content: _buildPropertyDetailsStep(),
                  isActive: _currentStep >= 1,
                ),
                Step(
                  title: const Text('Images & Submit'),
                  content: _buildImagesStep(),
                  isActive: _currentStep >= 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Type Selection
          const Text(
            'Property Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _propertyTypes.map((type) {
              final isSelected = _selectedPropertyType == type['name'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPropertyType = type['name'];
                  });
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? type['color'].withOpacity(0.1)
                        : Colors.white,
                    border: Border.all(
                      color: isSelected ? type['color'] : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: type['color'].withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type['icon'],
                        color: isSelected ? type['color'] : Colors.grey[600],
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        type['name'],
                        style: TextStyle(
                          color: isSelected ? type['color'] : Colors.grey[700],
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Property Name
          _buildTextField(
            controller: _nameCtr,
            label: 'Property Name',
            icon: Icons.home,
            validator: (v) => v!.isEmpty ? 'Property name is required' : null,
          ),
          const SizedBox(height: 16),

          // Location
          _buildTextField(
            controller: _locationCtr,
            label: 'Location',
            icon: Icons.location_on,
            validator: (v) => v!.isEmpty ? 'Location is required' : null,
          ),
          const SizedBox(height: 16),

          // Amount
          _buildTextField(
            controller: _amountCtr,
            label: 'Amount (₹)',
            icon: Icons.currency_rupee,
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Amount is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyDetailsStep() {
    return Column(
      children: [
        // Contractor Name
        _buildTextField(
          controller: _contractorNameCtr,
          label: 'Contractor Name',
          icon: Icons.person,
          readOnly: true,
        ),
        const SizedBox(height: 16),

        // Contractor Phone
        _buildTextField(
          controller: _contractorPhoneCtr,
          label: 'Contact Phone',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (v) => v!.isEmpty ? 'Phone number is required' : null,
        ),
        const SizedBox(height: 16),

        // Vacancies
        _buildTextField(
          controller: _vacancyCtr,
          label: 'Available Units (Optional)',
          icon: Icons.meeting_room,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),

        // Discount
        _buildTextField(
          controller: _discountCtr,
          label: 'Special Offer (Optional)',
          icon: Icons.local_offer,
          hintText: 'e.g., 10% off for early booking',
        ),
        const SizedBox(height: 16),

        // Description
        _buildTextField(
          controller: _descriptionCtr,
          label: 'Property Description',
          icon: Icons.description,
          maxLines: 4,
          hintText: 'Describe your property features, amenities, etc.',
        ),
      ],
    );
  }

  Widget _buildImagesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Property Images',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add multiple high-quality images of your property',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),

        // Image grid
        if (_pickedBytes.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _pickedBytes.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _pickedBytes[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // Add images button
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to add images',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Submit button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Processing Payment & Listing...'),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.payment),
                      SizedBox(width: 8),
                      Text(
                        'Pay & Submit Property',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey[100] : null,
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      readOnly: readOnly,
    );
  }
}
