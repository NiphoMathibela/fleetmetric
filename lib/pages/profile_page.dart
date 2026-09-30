import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/fuel_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  final _fuelRepo = FuelRepository();
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _userName;
  String? _userEmail;
  int _totalVehicles = 0;
  int _totalFuelSlips = 0;
  double _totalSpend = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated')),
          );
        }
        return;
      }

      final userEmail = user.email;
      final userName = user.userMetadata?['name'] as String?;

      final vehicles = await _fuelRepo.getVehicles();
      final fuelSlips = await _fuelRepo.getFuelSlips();

      double totalSpend = 0.0;
      for (final slip in fuelSlips) {
        totalSpend += (slip['total_amount'] as num?)?.toDouble() ?? 0.0;
      }

      if (mounted) {
        setState(() {
          _userEmail = userEmail;
          _userName = userName;
          _totalVehicles = vehicles.length;
          _totalFuelSlips = fuelSlips.length;
          _totalSpend = totalSpend;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Logout', style: TextStyle(color: Color(0xFFf7f8f9))),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: Color(0xFF7f7f81))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFFfca541))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _handleEditProfile() async {
    final nameController = TextEditingController(text: _userName ?? '');
    final emailController = TextEditingController(text: _userEmail ?? '');

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Edit Profile',
            style: TextStyle(color: Color(0xFFf7f8f9))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Color(0xFFf7f8f9)),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Color(0xFF7f7f81)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7f7f81)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFfca541)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                enabled: false,
                style: const TextStyle(color: Color(0xFF7f7f81)),
                decoration: const InputDecoration(
                  labelText: 'Email (cannot be changed)',
                  labelStyle: TextStyle(color: Color(0xFF7f7f81)),
                  disabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF7f7f81)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'To change your email, please contact support.',
                style: TextStyle(fontSize: 11, color: Color(0xFF7f7f81)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFFfca541))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Save', style: TextStyle(color: Color(0xFFfca541))),
          ),
        ],
      ),
    );

    if (updated == true && nameController.text.trim().isNotEmpty) {
      try {
        await _supabase.auth.updateUser(
          UserAttributes(data: {'name': nameController.text.trim()}),
        );
        _loadProfileData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100f14),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF100f14),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              const Color(0xFFfca541).withValues(alpha: 0.2),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: const Color(0xFFfca541),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userName ?? 'User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFf7f8f9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userEmail ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7f7f81),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Vehicles',
                          value: _totalVehicles.toString(),
                          icon: Icons.directions_car,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Fuel Slips',
                          value: _totalFuelSlips.toString(),
                          icon: Icons.receipt_long,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Total Spend',
                    value: 'R ${_totalSpend.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet,
                    color: Colors.orange.shade800,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 32),

                  // Settings Section
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFf7f8f9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsTile(
                    icon: Icons.edit,
                    title: 'Edit Profile',
                    subtitle: 'Update your name and email',
                    onTap: _handleEditProfile,
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Manage notification preferences',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Notifications coming soon')),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Get help with the app',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help coming soon')),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'App version and information',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'FuelSlips',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© 2026 FuelSlips',
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7f7f81),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFf7f8f9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1C1C1E),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFfca541)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFFf7f8f9),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF7f7f81),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF7f7f81)),
        onTap: onTap,
      ),
    );
  }
}
