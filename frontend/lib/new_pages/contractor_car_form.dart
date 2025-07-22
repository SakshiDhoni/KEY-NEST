// lib/presentation/contractor_car_form.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class ContractorCarFormPage extends StatefulWidget {
  final String username;
  final String email;

  const ContractorCarFormPage({
    super.key,
    required this.username,
    required this.email,
  });

  @override
  State<ContractorCarFormPage> createState() => _CarFormState();
}

class _CarFormState extends State<ContractorCarFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers as requested
  final _brandCtr = TextEditingController();
  final _modelCtr = TextEditingController();
  final _showroomCtr = TextEditingController();
  final _locationCtr = TextEditingController();
  final _priceCtr = TextEditingController();
  final _discountCtr = TextEditingController();
  final _yearCtr = TextEditingController();
  final _kmDrivenCtr = TextEditingController();
  final _descriptionCtr = TextEditingController();
  final _contactPhoneCtr = TextEditingController();

  // Image handling
  final List<XFile> _pickedFiles = [];
  final List<Uint8List> _pickedBytes = [];
  final _picker = ImagePicker();

  // State variables
  bool _isSubmitting = false;
  String _selectedFuelType = '';
  String _selectedTransmission = '';
  String _selectedCondition = '';
  int _currentStep = 0;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Car brands
  final List<Map<String, dynamic>> _carBrands = [
    {
      'name': 'Maruti Suzuki',
      'icon': Icons.directions_car,
      'color': Colors.blue
    },
    {'name': 'Hyundai', 'icon': Icons.directions_car, 'color': Colors.red},
    {'name': 'Tata', 'icon': Icons.directions_car, 'color': Colors.indigo},
    {'name': 'Mahindra', 'icon': Icons.directions_car, 'color': Colors.orange},
    {'name': 'Honda', 'icon': Icons.directions_car, 'color': Colors.purple},
    {'name': 'Toyota', 'icon': Icons.directions_car, 'color': Colors.green},
    {'name': 'BMW', 'icon': Icons.directions_car, 'color': Colors.black},
    {'name': 'Mercedes', 'icon': Icons.directions_car, 'color': Colors.grey},
  ];

  // Fuel types
  final List<String> _fuelTypes = [
    'Petrol',
    'Diesel',
    'CNG',
    'Electric',
    'Hybrid'
  ];

  // Transmission types
  final List<String> _transmissionTypes = ['Manual', 'Automatic', 'CVT'];

  // Condition types
  final List<String> _conditionTypes = ['New', 'Like New', 'Good', 'Fair'];

  static const _apiUrl = 'http://localhost:3000/api/contractor/addCar';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _brandCtr.dispose();
    _modelCtr.dispose();
    _showroomCtr.dispose();
    _locationCtr.dispose();
    _priceCtr.dispose();
    _discountCtr.dispose();
    _yearCtr.dispose();
    _kmDrivenCtr.dispose();
    _descriptionCtr.dispose();
    _contactPhoneCtr.dispose();
    super.dispose();
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
              Navigator.pushReplacementNamed(context, '/welcome');
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFiles.isEmpty) {
      _showSnackBar('Please select at least one image', isError: true);
      return;
    }
    if (_selectedFuelType.isEmpty ||
        _selectedTransmission.isEmpty ||
        _selectedCondition.isEmpty) {
      _showSnackBar('Please fill all required selections', isError: true);
      return;
    }

    // Show payment dialog before submission
    final shouldProceed = await _showPaymentDialog();
    if (!shouldProceed) return;

    setState(() => _isSubmitting = true);

    final uri = Uri.parse(_apiUrl);
    final req = http.MultipartRequest('POST', uri)
      ..fields['brand'] = _brandCtr.text
      ..fields['model'] = _modelCtr.text
      ..fields['showroom'] = _showroomCtr.text
      ..fields['location'] = _locationCtr.text
      ..fields['price'] = _priceCtr.text
      ..fields['discount'] = _discountCtr.text
      ..fields['year'] = _yearCtr.text
      ..fields['kmDriven'] = _kmDrivenCtr.text
      ..fields['fuelType'] = _selectedFuelType
      ..fields['transmission'] = _selectedTransmission
      ..fields['condition'] = _selectedCondition
      ..fields['description'] = _descriptionCtr.text
      ..fields['contactPhone'] = _contactPhoneCtr.text
      ..fields['contractorEmail'] = widget.email
      ..fields['contractorName'] = widget.username;

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
        _showSnackBar('Car listing added successfully! 🚗✨');
        _resetForm();
      } else {
        final error = jsonDecode(res.body);
        _showSnackBar('Error: ${error['error'] ?? 'Something went wrong'}',
            isError: true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showSnackBar('Network Error: $e', isError: true);
    }
  }

  Future<bool> _showPaymentDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Listing Fee'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('To list your car, a small fee is required:'),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Listing Fee:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('₹299',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                    '• Valid for 30 days\n• Unlimited photo uploads\n• Priority listing',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                  _showSnackBar(
                      'Payment successful! Processing your listing...',
                      isError: false);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('Pay ₹299', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _brandCtr.clear();
    _modelCtr.clear();
    _showroomCtr.clear();
    _locationCtr.clear();
    _priceCtr.clear();
    _discountCtr.clear();
    _yearCtr.clear();
    _kmDrivenCtr.clear();
    _descriptionCtr.clear();
    _contactPhoneCtr.clear();
    setState(() {
      _pickedFiles.clear();
      _pickedBytes.clear();
      _selectedFuelType = '';
      _selectedTransmission = '';
      _selectedCondition = '';
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
                  colors: [Colors.orange[600]!, Colors.orange[700]!],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_car,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Add Car Listing',
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
                    backgroundColor: Colors.orange[600],
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
                    widget.username,
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
                    primary: Colors.orange[600],
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
                          backgroundColor: Colors.orange[600],
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
                  title: const Text('Car Details'),
                  content: _buildCarDetailsStep(),
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
          // Brand
          _buildTextField(
            controller: _brandCtr,
            label: 'Car Brand',
            icon: Icons.branding_watermark,
            validator: (v) => v!.isEmpty ? 'Brand is required' : null,
          ),
          const SizedBox(height: 16),

          // Model
          _buildTextField(
            controller: _modelCtr,
            label: 'Car Model',
            icon: Icons.directions_car,
            validator: (v) => v!.isEmpty ? 'Model is required' : null,
          ),
          const SizedBox(height: 16),

          // Showroom/Dealer
          _buildTextField(
            controller: _showroomCtr,
            label: 'Showroom/Dealer Name',
            icon: Icons.store,
            validator: (v) => v!.isEmpty ? 'Showroom name is required' : null,
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

          // Price
          _buildTextField(
            controller: _priceCtr,
            label: 'Price (₹)',
            icon: Icons.currency_rupee,
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Price is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCarDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Year
        _buildTextField(
          controller: _yearCtr,
          label: 'Manufacturing Year',
          icon: Icons.calendar_today,
          keyboardType: TextInputType.number,
          validator: (v) => v!.isEmpty ? 'Year is required' : null,
        ),
        const SizedBox(height: 16),

        // KM Driven
        _buildTextField(
          controller: _kmDrivenCtr,
          label: 'KM Driven',
          icon: Icons.speed,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),

        // Fuel Type
        _buildDropdownField(
          label: 'Fuel Type',
          icon: Icons.local_gas_station,
          value: _selectedFuelType.isEmpty ? null : _selectedFuelType,
          items: _fuelTypes,
          onChanged: (value) => setState(() => _selectedFuelType = value!),
        ),
        const SizedBox(height: 16),

        // Transmission
        _buildDropdownField(
          label: 'Transmission',
          icon: Icons.settings,
          value: _selectedTransmission.isEmpty ? null : _selectedTransmission,
          items: _transmissionTypes,
          onChanged: (value) => setState(() => _selectedTransmission = value!),
        ),
        const SizedBox(height: 16),

        // Condition
        _buildDropdownField(
          label: 'Condition',
          icon: Icons.star,
          value: _selectedCondition.isEmpty ? null : _selectedCondition,
          items: _conditionTypes,
          onChanged: (value) => setState(() => _selectedCondition = value!),
        ),
        const SizedBox(height: 16),

        // Contact Phone
        _buildTextField(
          controller: _contactPhoneCtr,
          label: 'Contact Phone',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (v) => v!.isEmpty ? 'Phone number is required' : null,
        ),
        const SizedBox(height: 16),

        // Discount
        _buildTextField(
          controller: _discountCtr,
          label: 'Special Offer (Optional)',
          icon: Icons.local_offer,
          hintText: 'e.g., Negotiable, Exchange accepted',
        ),
        const SizedBox(height: 16),

        // Description
        _buildTextField(
          controller: _descriptionCtr,
          label: 'Car Description',
          icon: Icons.description,
          maxLines: 4,
          hintText:
              'Describe your car features, condition, service history, etc.',
        ),
      ],
    );
  }

  Widget _buildImagesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Car Images',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add multiple high-quality images of your car (exterior, interior, engine)',
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
                  'Tap to add car images',
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
              backgroundColor: Colors.orange[600],
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
                      Text('Submitting Car Listing...'),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.payment),
                      SizedBox(width: 8),
                      Text(
                        'Pay & Submit Listing',
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
          borderSide: BorderSide(color: Colors.orange[600]!, width: 2),
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

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
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
          borderSide: BorderSide(color: Colors.orange[600]!, width: 2),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? '$label is required' : null,
    );
  }
}
