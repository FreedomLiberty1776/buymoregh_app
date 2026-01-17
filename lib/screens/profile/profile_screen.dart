import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/forgot_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _requireLoginEveryTime = false;
  String _biometricTypeName = 'Fingerprint';
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final authProvider = context.read<AuthProvider>();
    
    final biometricAvailable = await authProvider.isBiometricAvailable();
    final biometricEnabled = await authProvider.isBiometricEnabled();
    final requireLogin = await authProvider.isRequireLoginEveryTime();
    final biometricName = await authProvider.getBiometricTypeName();
    
    if (mounted) {
      setState(() {
        _biometricAvailable = biometricAvailable;
        _biometricEnabled = biometricEnabled;
        _requireLoginEveryTime = requireLogin;
        _biometricTypeName = biometricName;
        _isLoadingSettings = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.setBiometricEnabled(value);
    
    if (success) {
      setState(() {
        _biometricEnabled = value;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value 
                  ? '$_biometricTypeName login enabled' 
                  : '$_biometricTypeName login disabled'
            ),
            backgroundColor: AppTheme.completedStatus,
          ),
        );
      }
    } else {
      if (mounted && authProvider.error != null) {
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

  Future<void> _toggleRequireLogin(bool value) async {
    final authProvider = context.read<AuthProvider>();
    
    await authProvider.setRequireLoginEveryTime(value);
    
    setState(() {
      _requireLoginEveryTime = value;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value 
                ? 'Login will be required every time' 
                : 'You will stay logged in'
          ),
          backgroundColor: AppTheme.completedStatus,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

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
          'Profile',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Center(
                      child: Text(
                        user?.fullName.isNotEmpty == true
                            ? user!.fullName[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Name
                  Text(
                    user?.fullName ?? 'Agent',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  // Agent Code
                  if (user?.agentCode != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        user!.agentCode!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                  
                  // Role Badge
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.completedStatus.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      user?.isAdmin == true ? 'Admin' : 'Agent',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.completedStatus,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty)
                    _buildInfoTile(
                      context,
                      Icons.phone,
                      'Phone Number',
                      user.phoneNumber!,
                    ),
                  const Divider(height: 1),
                  if (user?.email != null && user!.email.isNotEmpty)
                    _buildInfoTile(
                      context,
                      Icons.email,
                      'Email',
                      user.email,
                    ),
                  const Divider(height: 1),
                  if (user?.assignedRegion != null && user!.assignedRegion!.isNotEmpty)
                    _buildInfoTile(
                      context,
                      Icons.location_on,
                      'Assigned Region',
                      user.assignedRegion!,
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Security Section
            _buildSectionHeader('Security'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Require Login Every Time
                  _buildSwitchTile(
                    icon: Icons.lock_clock,
                    iconColor: AppTheme.warningColor,
                    title: 'Require Login Every Time',
                    subtitle: 'Always require authentication when opening the app',
                    value: _requireLoginEveryTime,
                    onChanged: _isLoadingSettings ? null : _toggleRequireLogin,
                  ),
                  
                  const Divider(height: 1),
                  
                  // Biometric Authentication
                  if (_biometricAvailable) ...[
                    _buildSwitchTile(
                      icon: Icons.fingerprint,
                      iconColor: AppTheme.primaryColor,
                      title: '$_biometricTypeName Login',
                      subtitle: 'Use $_biometricTypeName to unlock the app',
                      value: _biometricEnabled,
                      onChanged: _isLoadingSettings 
                          ? null 
                          : (_requireLoginEveryTime ? _toggleBiometric : null),
                      disabled: !_requireLoginEveryTime,
                      disabledHint: 'Enable "Require Login Every Time" first',
                    ),
                    const Divider(height: 1),
                  ],
                  
                  // Reset Password
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: const Text(
                      'Reset Password',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Change your account password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Help text for security settings
            if (_requireLoginEveryTime) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppTheme.primaryColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _biometricEnabled
                            ? 'You will need to use $_biometricTypeName or password each time you open the app.'
                            : 'You will need to enter your password each time you open the app.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showLogoutDialog(context, authProvider);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App Version
            Center(
              child: Text(
                'BuyMore Agent v1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textHint,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool)? onChanged,
    bool disabled = false,
    String? disabledHint,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(disabled ? 0.05 : 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: disabled ? iconColor.withOpacity(0.3) : iconColor,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: disabled ? AppTheme.textHint : AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        disabled && disabledHint != null ? disabledHint : subtitle,
        style: TextStyle(
          color: disabled ? AppTheme.textHint : AppTheme.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: disabled ? null : onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
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
