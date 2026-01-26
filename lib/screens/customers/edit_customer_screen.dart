import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/customer.dart';
import '../../services/api_service.dart';

class EditCustomerScreen extends StatefulWidget {
  final int customerId;
  final String customerName;

  const EditCustomerScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isLoadingData = true;
  String? _errorMessage;

  Customer? _customer;

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _occupationController = TextEditingController();
  final _workplaceController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();
  File? _passportPhoto;
  File? _idPhoto;
  final ImagePicker _imagePicker = ImagePicker();

  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  String? _selectedRegion;

  final _nokNameController = TextEditingController();
  final _nokPhoneController = TextEditingController();
  String? _selectedNokRelationship;

  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

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

  Future<void> _loadCustomer() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });
    final api = ApiService();
    final response = await api.getCustomer(widget.customerId);
    if (!mounted) return;
    if (response.success && response.data != null) {
      _customer = response.data!;
      _fullNameController.text = _customer!.fullName;
      _phoneController.text = _customer!.phoneNumber;
      _emailController.text = _customer!.email ?? '';
      _nationalIdController.text = _customer!.nationalId ?? '';
      _occupationController.text = _customer!.occupation ?? '';
      _workplaceController.text = _customer!.workplace ?? '';
      _monthlyIncomeController.text = _customer!.monthlyIncome != null
          ? _customer!.monthlyIncome!.toStringAsFixed(2)
          : '';
      _addressController.text = _customer!.address ?? '';
      _cityController.text = _customer!.city ?? '';
      final region = _customer!.region;
      _selectedRegion = (region != null && region.isNotEmpty && ghanaRegions.contains(region))
          ? region
          : null;
      _nokNameController.text = _customer!.nextOfKinName ?? '';
      _nokPhoneController.text = _customer!.nextOfKinPhone ?? '';
      final rel = _customer!.nextOfKinRelationship;
      _selectedNokRelationship = (rel != null && rel.isNotEmpty && nokRelationships.contains(rel))
          ? rel
          : null;
      _latitude = _customer!.latitude;
      _longitude = _customer!.longitude;
    } else {
      _errorMessage = response.error ?? 'Failed to load customer';
    }
    setState(() => _isLoadingData = false);
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          if (!mounted) return;
          setState(() {
            _locationError = 'Location permission is required to record coordinates.';
            _isLoadingLocation = false;
          });
          return;
        }
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Location request timed out'),
      );
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationError = null;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _locationError =
            'Location request timed out. Turn on GPS/location and try again.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Could not get location: ${e is Exception ? e.toString().replaceFirst('Exception: ', '') : e}';
      });
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
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
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      onPressed: () async {
                        Navigator.pop(context);
                        final XFile? image = await _imagePicker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 80,
                          maxWidth: 1024,
                          maxHeight: 1024,
                        );
                        if (image != null && mounted) {
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      onPressed: () async {
                        Navigator.pop(context);
                        final XFile? image = await _imagePicker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                          maxWidth: 1024,
                          maxHeight: 1024,
                        );
                        if (image != null && mounted) {
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitCustomer() async {
    if (!_formKey.currentState!.validate() || _customer == null) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final customer = Customer(
        id: widget.customerId,
        customerNumber: _customer!.customerNumber,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        nationalId: _nationalIdController.text.trim().isNotEmpty ? _nationalIdController.text.trim() : null,
        address: _addressController.text.trim(),
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        region: _selectedRegion,
        latitude: _latitude,
        longitude: _longitude,
        occupation: _occupationController.text.trim().isNotEmpty ? _occupationController.text.trim() : null,
        workplace: _workplaceController.text.trim().isNotEmpty ? _workplaceController.text.trim() : null,
        monthlyIncome: _monthlyIncomeController.text.trim().isNotEmpty
            ? double.tryParse(_monthlyIncomeController.text.trim())
            : null,
        passportPhoto: null,
        idPhoto: null,
        nextOfKinName: _nokNameController.text.trim().isNotEmpty ? _nokNameController.text.trim() : null,
        nextOfKinPhone: _nokPhoneController.text.trim().isNotEmpty ? _nokPhoneController.text.trim() : null,
        nextOfKinRelationship: _selectedNokRelationship,
        createdAt: _customer!.createdAt,
        updatedAt: DateTime.now(),
        isSynced: true,
        localUniqueId: null,
      );
      final api = ApiService();
      final result = await api.updateCustomer(widget.customerId, customer);
      if (!mounted) return;
      if (result.success) {
        final authProvider = context.read<AuthProvider>();
        final appProvider = context.read<AppProvider>();
        await appProvider.loadCustomers(agentId: authProvider.user?.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer updated successfully.'),
            backgroundColor: AppTheme.completedStatus,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Failed to update customer';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _errorMessage = null;
          _currentStep++;
        });
      }
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
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Edit Customer',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_customer == null && _errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Edit Customer',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _loadCustomer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
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
          'Edit Customer',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    if (_currentStep == 0) _buildPersonalInfoStep(),
                    if (_currentStep == 1) _buildAddressStep(),
                    if (_currentStep == 2) _buildNextOfKinStep(),
                  ],
                ),
              ),
            ),
          ),
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
                            _currentStep < 2 ? 'Next' : 'Save changes',
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
        _buildTextField(controller: _fullNameController, label: 'Full Name', hint: 'Enter customer\'s full name', icon: Icons.person, required: true),
        _buildTextField(controller: _phoneController, label: 'Phone Number', hint: 'e.g., 0244123456', icon: Icons.phone, keyboardType: TextInputType.phone, required: true, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
        _buildTextField(controller: _emailController, label: 'Email Address', hint: 'customer@email.com', icon: Icons.email, keyboardType: TextInputType.emailAddress),
        _buildTextField(controller: _nationalIdController, label: 'National ID (Ghana Card)', hint: 'GHA-XXXXXXXXX-X', icon: Icons.badge),
        _buildTextField(controller: _occupationController, label: 'Occupation', hint: 'e.g., Teacher, Trader', icon: Icons.work),
        _buildTextField(controller: _workplaceController, label: 'Workplace', hint: 'Company/Business name', icon: Icons.business),
        _buildTextField(controller: _monthlyIncomeController, label: 'Estimated Monthly Income (GHS)', hint: '0.00', icon: Icons.payments, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]),
        const SizedBox(height: 8),
        Text('Documents (Optional)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPhotoUploadCard(label: 'Customer Photo', icon: Icons.person, image: _passportPhoto, onTap: () => _pickImage(true), onRemove: _passportPhoto != null ? () => setState(() => _passportPhoto = null) : null)),
            const SizedBox(width: 12),
            Expanded(child: _buildPhotoUploadCard(label: 'ID Card Photo', icon: Icons.credit_card, image: _idPhoto, onTap: () => _pickImage(false), onRemove: _idPhoto != null ? () => setState(() => _idPhoto = null) : null)),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Address Information', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildTextField(controller: _addressController, label: 'Street Address', hint: 'House number, Street name, Landmark', icon: Icons.home, required: true, maxLines: 2),
        _buildTextField(controller: _cityController, label: 'City/Town', hint: 'e.g., Accra, Kumasi', icon: Icons.location_city),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonFormField<String>(
            value: _selectedRegion != null && ghanaRegions.contains(_selectedRegion)
                ? _selectedRegion
                : null,
            decoration: InputDecoration(
              labelText: 'Region',
              prefixIcon: const Icon(Icons.map),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
            ),
            items: [const DropdownMenuItem<String>(value: null, child: Text('-- Select Region --')), ...ghanaRegions.map((region) => DropdownMenuItem(value: region, child: Text(region)))],
            onChanged: (value) => setState(() => _selectedRegion = value),
          ),
        ),
        const SizedBox(height: 8),
        Text('Location (optional)', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                icon: _isLoadingLocation ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location, size: 20),
                label: Text(_latitude != null && _longitude != null ? 'Recapture location' : 'Get location'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (_latitude != null && _longitude != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setState(() { _latitude = null; _longitude = null; _locationError = null; }),
                icon: const Icon(Icons.clear),
                tooltip: 'Clear location',
              ),
            ],
          ],
        ),
        if (_locationError != null) ...[
          const SizedBox(height: 6),
          Text(_locationError!, style: TextStyle(color: AppTheme.errorColor, fontSize: 12)),
        ],
        if (_latitude != null && _longitude != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
          ),
      ],
    );
  }

  Widget _buildNextOfKinStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Next of Kin / Guarantor', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Optional but recommended', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: 16),
        _buildTextField(controller: _nokNameController, label: 'Full Name', hint: 'Next of kin\'s full name', icon: Icons.person_outline),
        _buildTextField(controller: _nokPhoneController, label: 'Phone Number', hint: 'e.g., 0244123456', icon: Icons.phone, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonFormField<String>(
            value: _selectedNokRelationship != null && nokRelationships.contains(_selectedNokRelationship)
                ? _selectedNokRelationship
                : null,
            decoration: InputDecoration(
              labelText: 'Relationship',
              prefixIcon: const Icon(Icons.family_restroom),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
            ),
            items: [const DropdownMenuItem<String>(value: null, child: Text('-- Select Relationship --')), ...nokRelationships.map((rel) => DropdownMenuItem(value: rel, child: Text(rel)))],
            onChanged: (value) => setState(() => _selectedNokRelationship = value),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Icon(Icons.info_outline, size: 18, color: AppTheme.primaryColor), const SizedBox(width: 8), Text('Summary', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryColor))]),
              const SizedBox(height: 12),
              _buildSummaryRow('Name', _fullNameController.text),
              _buildSummaryRow('Phone', _phoneController.text),
              _buildSummaryRow('Address', _addressController.text),
              if (_cityController.text.isNotEmpty) _buildSummaryRow('City', '${_cityController.text}${_selectedRegion != null ? ', $_selectedRegion' : ''}'),
              if (_passportPhoto != null || _idPhoto != null) _buildSummaryRow('Photos', '${_passportPhoto != null ? 'Customer Photo' : ''}${_passportPhoto != null && _idPhoto != null ? ', ' : ''}${_idPhoto != null ? 'ID Photo' : ''}'),
            ],
          ),
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
          border: Border.all(color: image != null ? AppTheme.primaryColor : AppTheme.dividerColor, width: image != null ? 2 : 1),
        ),
        child: image != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(image, fit: BoxFit.cover)),
                  if (onRemove != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)),
                      ),
                    ),
                  Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(vertical: 6), decoration: BoxDecoration(color: Colors.black54, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10))), child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)))),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.backgroundColor, shape: BoxShape.circle), child: Icon(icon, size: 28, color: AppTheme.primaryColor)),
                  const SizedBox(height: 8),
                  Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text('Tap to add', style: TextStyle(fontSize: 10, color: AppTheme.primaryColor)),
                ],
              ),
      ),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          prefixIcon: maxLines > 1 ? Padding(padding: const EdgeInsets.only(bottom: 24), child: Icon(icon)) : Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: required ? (value) => (value == null || value.trim().isEmpty) ? '$label is required' : null : null,
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
          SizedBox(width: 80, child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary))),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
