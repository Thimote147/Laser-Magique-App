import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../main.dart'; // For supabase client

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  String? _userEmail;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final user = supabase.auth.currentUser;
      if (user != null) {
        setState(() {
          _userEmail = user.email;
        });
      }
    } catch (e) {
      // Handle error
      print('Error loading user info: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        padding: EdgeInsetsDirectional.only(start: 16, end: 8),
        middle: null,
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null,
        leading: Text(
          'Paramètres',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: CupertinoColors.black,
            fontFamily: '.SF Pro Display',
          ),
        ),
      ),
      child: SafeArea(
        child:
            _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildUserInfoSection(),
                          const SizedBox(height: 24),
                          _buildGeneralSettingsSection(),
                          const SizedBox(height: 24),
                          _buildAppearanceSection(),
                          const SizedBox(height: 24),
                          _buildAboutSection(),
                          const SizedBox(height: 24),
                          _buildSignOutButton(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(
                CupertinoIcons.person_fill,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Laser Magique Admin',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail ?? 'Not signed in',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      // Navigate to profile edit screen
                    },
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('General Settings'),
        Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: CupertinoIcons.bell_fill,
                title: 'Notifications',
                trailing: CupertinoSwitch(
                  value: _notificationsEnabled,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
              ),
              const Divider(height: 1, indent: 65),
              _buildSettingsItem(
                icon: CupertinoIcons.time,
                title: 'Working Hours',
                onTap: () {
                  // Navigate to working hours screen
                },
              ),
              const Divider(height: 1, indent: 65),
              _buildSettingsItem(
                icon: CupertinoIcons.money_dollar_circle_fill,
                title: 'Services & Pricing',
                onTap: () {
                  // Navigate to services & pricing screen
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Appearance'),
        Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: CupertinoIcons.moon_fill,
                title: 'Dark Mode',
                trailing: CupertinoSwitch(
                  value: _darkModeEnabled,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                    // Implement theme change
                  },
                ),
              ),
              const Divider(height: 1, indent: 65),
              _buildSettingsItem(
                icon: CupertinoIcons.textformat_size,
                title: 'Text Size',
                onTap: () {
                  // Navigate to text size settings
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('About'),
        Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: CupertinoIcons.info_circle_fill,
                title: 'App Info',
                onTap: () {
                  _showAppInfoDialog();
                },
              ),
              const Divider(height: 1, indent: 65),
              _buildSettingsItem(
                icon: CupertinoIcons.doc_text,
                title: 'Terms of Service',
                onTap: () {
                  // Navigate to terms screen
                },
              ),
              const Divider(height: 1, indent: 65),
              _buildSettingsItem(
                icon: CupertinoIcons.lock_fill,
                title: 'Privacy Policy',
                onTap: () {
                  // Navigate to privacy policy screen
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing ??
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 18,
                  color: CupertinoColors.systemGrey,
                ),
          ],
        ),
      ),
    );
  }

  void _showAppInfoDialog() {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Laser Magique'),
            content: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Laser Magique App helps beauty salons manage appointments, clients, and services efficiently.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  Widget _buildSignOutButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _signOut,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: const Text(
          'Sign Out',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();

    if (!context.mounted) return;

    // Navigate to login or reset app state
    // This would depend on how your authentication flow is set up
  }
}
