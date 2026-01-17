import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';

enum ResetStep { request, verify, newPassword, success }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final ApiService _api = ApiService();
  
  ResetStep _currentStep = ResetStep.request;
  bool _isLoading = false;
  String? _error;
  String? _maskedPhone;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestResetCode() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final response = await _api.requestPasswordReset(
        _identifierController.text.trim(),
      );
      
      if (response.success && response.data != null) {
        setState(() {
          _maskedPhone = response.data!.maskedPhone;
          _currentStep = ResetStep.verify;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to send reset code';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.trim().length != 6) {
      setState(() {
        _error = 'Please enter the 6-digit code';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final response = await _api.verifyResetCode(
        _identifierController.text.trim(),
        _codeController.text.trim(),
      );
      
      if (response.success) {
        setState(() {
          _currentStep = ResetStep.newPassword;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Invalid or expired code';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _error = 'Passwords do not match';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final response = await _api.resetPassword(
        _identifierController.text.trim(),
        _codeController.text.trim(),
        _passwordController.text,
      );
      
      if (response.success) {
        setState(() {
          _currentStep = ResetStep.success;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to reset password';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildRequestStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Forgot Password?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your agent code or phone number and we\'ll send you a reset code via SMS.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _identifierController,
            decoration: const InputDecoration(
              labelText: 'Agent Code or Phone Number',
              hintText: 'e.g. AG-12345678 or 0241234567',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your agent code or phone number';
              }
              return null;
            },
          ),
        ),
        
        const SizedBox(height: 24),
        
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _requestResetCode,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Send Reset Code'),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter Reset Code',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit code to $_maskedPhone',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            labelText: 'Reset Code',
            hintText: 'Enter 6-digit code',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
        ),
        
        const SizedBox(height: 16),
        
        TextButton(
          onPressed: _isLoading ? null : _requestResetCode,
          child: const Text('Resend Code'),
        ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyCode,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Verify Code'),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create New Password',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a strong password for your account.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            obscureText: _obscureConfirmPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Reset Password'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.successColor.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: AppTheme.successColor,
            size: 48,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Password Reset Successful!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your password has been reset. You can now login with your new password.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Back to Login'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentStep != ResetStep.success
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_currentStep == ResetStep.request) {
                    Navigator.of(context).pop();
                  } else if (_currentStep == ResetStep.verify) {
                    setState(() {
                      _currentStep = ResetStep.request;
                      _error = null;
                    });
                  } else if (_currentStep == ResetStep.newPassword) {
                    setState(() {
                      _currentStep = ResetStep.verify;
                      _error = null;
                    });
                  }
                },
              ),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_currentStep != ResetStep.success) ...[
                const SizedBox(height: 20),
              ] else ...[
                const SizedBox(height: 80),
              ],
              
              // Step indicator
              if (_currentStep != ResetStep.success) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepIndicator(1, _currentStep.index >= 0),
                    _buildStepConnector(_currentStep.index >= 1),
                    _buildStepIndicator(2, _currentStep.index >= 1),
                    _buildStepConnector(_currentStep.index >= 2),
                    _buildStepIndicator(3, _currentStep.index >= 2),
                  ],
                ),
                const SizedBox(height: 32),
              ],
              
              // Error message
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Current step content
              if (_currentStep == ResetStep.request) _buildRequestStep(),
              if (_currentStep == ResetStep.verify) _buildVerifyStep(),
              if (_currentStep == ResetStep.newPassword) _buildNewPasswordStep(),
              if (_currentStep == ResetStep.success) _buildSuccessStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, bool active) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: active ? AppTheme.primaryColor : AppTheme.dividerColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: TextStyle(
            color: active ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStepConnector(bool active) {
    return Container(
      width: 40,
      height: 2,
      color: active ? AppTheme.primaryColor : AppTheme.dividerColor,
    );
  }
}
