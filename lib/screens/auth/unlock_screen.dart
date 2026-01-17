import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Unlock Screen - shown when re-authentication is required
class UnlockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  
  const UnlockScreen({super.key, required this.onUnlocked});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _showPasswordField = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  String _biometricTypeName = 'Fingerprint';
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final authProvider = context.read<AuthProvider>();
    
    final biometricAvailable = await authProvider.isBiometricAvailable();
    final biometricEnabled = await authProvider.isBiometricEnabled();
    final biometricName = await authProvider.getBiometricTypeName();
    
    if (mounted) {
      setState(() {
        _biometricAvailable = biometricAvailable;
        _biometricEnabled = biometricEnabled;
        _biometricTypeName = biometricName;
        // Show password field by default if biometric not enabled
        _showPasswordField = !biometricEnabled;
      });
      
      // Auto-trigger biometric if enabled
      if (biometricEnabled && biometricAvailable) {
        _authenticateWithBiometric();
      }
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isAuthenticating) return;
    
    setState(() {
      _isAuthenticating = true;
    });
    
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.authenticateWithBiometric();
    
    if (mounted) {
      setState(() {
        _isAuthenticating = false;
      });
      
      if (success) {
        widget.onUnlocked();
      } else {
        // Show password field on biometric failure
        setState(() {
          _showPasswordField = true;
        });
        if (authProvider.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error!),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          authProvider.clearError();
        }
      }
    }
  }

  Future<void> _authenticateWithPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isAuthenticating = true;
    });
    
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.reauthenticateWithPassword(
      _passwordController.text,
    );
    
    if (mounted) {
      setState(() {
        _isAuthenticating = false;
      });
      
      if (success) {
        widget.onUnlocked();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Invalid password'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        authProvider.clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              
              // Lock Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Welcome Back
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // User Name
              Text(
                user?.fullName ?? 'Agent',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                'Please authenticate to continue',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textHint,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Biometric Button
              if (_biometricEnabled && _biometricAvailable && !_showPasswordField)
                Column(
                  children: [
                    // Fingerprint Button
                    GestureDetector(
                      onTap: _isAuthenticating ? null : _authenticateWithBiometric,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _isAuthenticating
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.fingerprint,
                                size: 48,
                                color: AppTheme.primaryColor,
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Touch the sensor',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Use Password Instead
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showPasswordField = true;
                        });
                      },
                      child: const Text('Use password instead'),
                    ),
                  ],
                ),
              
              // Password Field
              if (_showPasswordField)
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _authenticateWithPassword(),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Unlock Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isAuthenticating ? null : _authenticateWithPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isAuthenticating
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Unlock',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      
                      // Use Biometric Instead
                      if (_biometricEnabled && _biometricAvailable)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showPasswordField = false;
                              });
                              _authenticateWithBiometric();
                            },
                            icon: const Icon(Icons.fingerprint),
                            label: Text('Use $_biometricTypeName'),
                          ),
                        ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 48),
              
              // Logout Option
              TextButton(
                onPressed: () {
                  _showLogoutConfirmation();
                },
                child: const Text(
                  'Logout and sign in with different account',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout? You will need to sign in again with your credentials.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
