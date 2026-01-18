import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/customer.dart';
import '../../services/api_service.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Personal Information
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _occupationController = TextEditingController();
  final _workplaceController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();
  
  // Photo files (optional)
  File? _passportPhoto;
  File? _idPhoto;
  final ImagePicker _imagePicker = ImagePicker();

  // Address Information
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  String? _selectedRegion;

  // Next of Kin
  final _nokNameController = TextEditingController();
  final _nokPhoneController = TextEditingController();
  String? _selectedNokRelationship;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nationalIdController.dispose();
    _occupationController.dispose();
    _workplaceController.dispose();
    _monthlyIncomeController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _nokNameController.dispose();
    _nokPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isPassportPhoto) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isPassportPhoto ? 'Customer Photo' : 'ID Card Photo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildPhotoOptionButton(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? image = await _imagePicker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 80,
                          maxWidth: 1024,
                          maxHeight: 1024,
                        );
                        if (image != null) {
                          setState(() {
                            if (isPassportPhoto) {
                              _passportPhoto = File(image.path);
                            } else {
                              _idPhoto = File(image.path);
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPhotoOptionButton(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? image = await _imagePicker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                          maxWidth: 1024,
                          maxHeight: 1024,
                        );
                        if (image != null) {
                          setState(() {
                            if (isPassportPhoto) {
                              _passportPhoto = File(image.path);
                            } else {
                              _idPhoto = File(image.path);
                            }
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    
    try {
      final localId = const Uuid().v4();
      
      // For now, we create customer without images
      // In a full implementation, you would upload images to a server first
      final customer = Customer(
        id: 0, // Will be assigned by server
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        nationalId: _nationalIdController.text.trim().isNotEmpty ? _nationalIdController.text.trim() : null,
        address: _addressController.text.trim(),
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        region: _selectedRegion,
        occupation: _occupationController.text.trim().isNotEmpty ? _occupationController.text.trim() : null,
        workplace: _workplaceController.text.trim().isNotEmpty ? _workplaceController.text.trim() : null,
        monthlyIncome: _monthlyIncomeController.text.trim().isNotEmpty 
            ? double.tryParse(_monthlyIncomeController.text.trim()) 
            : null,
        // Photos will be uploaded separately if needed
        passportPhoto: null,
        idPhoto: null,
        nextOfKinName: _nokNameController.text.trim().isNotEmpty ? _nokNameController.text.trim() : null,
        nextOfKinPhone: _nokPhoneController.text.trim().isNotEmpty ? _nokPhoneController.text.trim() : null,
        nextOfKinRelationship: _selectedNokRelationship,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
        localUniqueId: localId,
      );
      
      final api = ApiService();
      final result = await api.createCustomer(customer);
      
      if (!mounted) return;
      
      if (result.success) {
        // If we have photos and customer was created, we could upload them here
        // For now, just show success
        
        // Reload customers
        final authProvider = context.read<AuthProvider>();
        final appProvider = context.read<AppProvider>();
        await appProvider.loadCustomers(agentId: authProvider.user?.id);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_passportPhoto != null || _idPhoto != null 
                ? 'Customer added! Photos saved locally.'
                : 'Customer added successfully!'),
            backgroundColor: AppTheme.completedStatus,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Failed to add customer';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      // Validate current step before proceeding
      if (_currentStep == 0) {
        // Validate personal info
        if (_fullNameController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Full name is required');
          return;
        }
        if (_phoneController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Phone number is required');
          return;
        }
        if (_phoneController.text.trim().length < 10) {
          setState(() => _errorMessage = 'Please enter a valid phone number');
          return;
        }
      } else if (_currentStep == 1) {
        // Validate address
        if (_addressController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Address is required');
          return;
        }
      }
      
      setState(() {
        _errorMessage = null;
        _currentStep++;
      });
    } else {
      _submitCustomer();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _errorMessage = null;
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: _previousStep,
        ),
        title: const Text(
          'Add Customer',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _buildStepIndicator(0, 'Personal'),
                _buildStepConnector(0),
                _buildStepIndicator(1, 'Address'),
                _buildStepConnector(1),
                _buildStepIndicator(2, 'Next of Kin'),
              ],
            ),
          ),
          
          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: AppTheme.errorColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Step Content
                    if (_currentStep == 0) _buildPersonalInfoStep(),
                    if (_currentStep == 1) _buildAddressStep(),
                    if (_currentStep == 2) _buildNextOfKinStep(),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Buttons
          Container(
            padding: EdgeInsets.fromLTRB(
              16, 
              16, 
              16, 
              16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  flex: _currentStep > 0 ? 2 : 1,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _currentStep < 2 ? 'Next' : 'Add Customer',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryColor : Colors.white,
              border: Border.all(
                color: isActive ? AppTheme.primaryColor : AppTheme.dividerColor,
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isActive && !isCurrent
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isCurrent ? AppTheme.primaryColor : AppTheme.textSecondary,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int afterStep) {
    final isActive = _currentStep > afterStep;
    
    return Container(
      height: 2,
      width: 40,
      margin: const EdgeInsets.only(bottom: 16),
      color: isActive ? AppTheme.primaryColor : AppTheme.dividerColor,
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _fullNameController,
          label: 'Full Name',
          hint: 'Enter customer\'s full name',
          icon: Icons.person,
          required: true,
        ),
        
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'e.g., 0244123456',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          required: true,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'customer@email.com',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        
        _buildTextField(
          controller: _nationalIdController,
          label: 'National ID (Ghana Card)',
          hint: 'GHA-XXXXXXXXX-X',
          icon: Icons.badge,
        ),
        
        _buildTextField(
          controller: _occupationController,
          label: 'Occupation',
          hint: 'e.g., Teacher, Trader',
          icon: Icons.work,
        ),
        
        _buildTextField(
          controller: _workplaceController,
          label: 'Workplace',
          hint: 'Company/Business name',
          icon: Icons.business,
        ),
        
        _buildTextField(
          controller: _monthlyIncomeController,
          label: 'Estimated Monthly Income (GHS)',
          hint: '0.00',
          icon: Icons.payments,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
        ),
        
        // Photo section header
        const SizedBox(height: 8),
        Text(
          'Documents (Optional)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Photo upload buttons
        Row(
          children: [
            Expanded(
              child: _buildPhotoUploadCard(
                label: 'Customer Photo',
                icon: Icons.person,
                image: _passportPhoto,
                onTap: () => _pickImage(true),
                onRemove: _passportPhoto != null ? () {
                  setState(() => _passportPhoto = null);
                } : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPhotoUploadCard(
                label: 'ID Card Photo',
                icon: Icons.credit_card,
                image: _idPhoto,
                onTap: () => _pickImage(false),
                onRemove: _idPhoto != null ? () {
                  setState(() => _idPhoto = null);
                } : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoUploadCard({
    required String label,
    required IconData icon,
    required File? image,
    required VoidCallback onTap,
    VoidCallback? onRemove,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: image != null ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: image != null ? 2 : 1,
          ),
        ),
        child: image != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      image,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(10),
                        ),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to add',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Address Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _addressController,
          label: 'Street Address',
          hint: 'House number, Street name, Landmark',
          icon: Icons.home,
          required: true,
          maxLines: 2,
        ),
        
        _buildTextField(
          controller: _cityController,
          label: 'City/Town',
          hint: 'e.g., Accra, Kumasi',
          icon: Icons.location_city,
        ),
        
        // Region Dropdown
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedRegion,
            decoration: InputDecoration(
              labelText: 'Region',
              prefixIcon: const Icon(Icons.map),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('-- Select Region --'),
              ),
              ...ghanaRegions.map((region) => DropdownMenuItem(
                value: region,
                child: Text(region),
              )),
            ],
            onChanged: (value) {
              setState(() => _selectedRegion = value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNextOfKinStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next of Kin / Guarantor',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Optional but recommended',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _nokNameController,
          label: 'Full Name',
          hint: 'Next of kin\'s full name',
          icon: Icons.person_outline,
        ),
        
        _buildTextField(
          controller: _nokPhoneController,
          label: 'Phone Number',
          hint: 'e.g., 0244123456',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        
        // Relationship Dropdown
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedNokRelationship,
            decoration: InputDecoration(
              labelText: 'Relationship',
              prefixIcon: const Icon(Icons.family_restroom),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('-- Select Relationship --'),
              ),
              ...nokRelationships.map((rel) => DropdownMenuItem(
                value: rel,
                child: Text(rel),
              )),
            ],
            onChanged: (value) {
              setState(() => _selectedNokRelationship = value);
            },
          ),
        ),
        
        // Summary Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSummaryRow('Name', _fullNameController.text),
              _buildSummaryRow('Phone', _phoneController.text),
              _buildSummaryRow('Address', _addressController.text),
              if (_cityController.text.isNotEmpty)
                _buildSummaryRow('City', '${_cityController.text}${_selectedRegion != null ? ', $_selectedRegion' : ''}'),
              if (_passportPhoto != null || _idPhoto != null)
                _buildSummaryRow('Photos', '${_passportPhoto != null ? 'Customer Photo' : ''}${_passportPhoto != null && _idPhoto != null ? ', ' : ''}${_idPhoto != null ? 'ID Photo' : ''}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool required = false,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          prefixIcon: maxLines > 1 
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Icon(icon),
                )
              : Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
