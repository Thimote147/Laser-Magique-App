import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:laser_magique_app/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:laser_magique_app/main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  String _errorMessage = '';
  String _userRole = 'customer';
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user != null) {
        _emailController.text = user.email ?? '';

        // Fetch user data from the users table
        final response =
            await supabase
                .from('users')
                .select()
                .eq('user_id', user.id)
                .single();

        setState(() {
          _userData = response;

          // Populate the form fields with user data
          _firstNameController.text = _userData?['firstname'] ?? '';
          _lastNameController.text = _userData?['lastname'] ?? '';
          _phoneController.text = _userData?['phone'] ?? '';

          if (_userData?['hourly_rate'] != null) {
            _hourlyRateController.text =
                _userData?['hourly_rate']?.toString() ?? '0';
          }

          _userRole = _userData?['role'] ?? 'customer';
        });
      }
    } catch (e) {
      _errorMessage = 'Failed to load profile: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = authService.currentUser;

        if (user != null) {
          // Prepare data to update in users table
          final userData = {
            'firstname': _firstNameController.text.trim(),
            'lastname': _lastNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          };

          // Update users table
          await supabase.from('users').update(userData).eq('user_id', user.id);

          // Also update auth user metadata with name for consistency
          await authService.updateProfile({
            'name':
                '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
          });

          // Reload profile data
          _loadUserProfile();

          setState(() {
            _isEditing = false;
          });

          if (mounted) {
            // Use a custom Cupertino toast-like notification instead of Material SnackBar
            _showCupertinoNotification('Profil mis à jour avec succès');
          }
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showCupertinoNotification(String message) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 50,
            left: 16,
            right: 16,
          ),
          decoration: BoxDecoration(
            color: CupertinoTheme.of(
              context,
            ).barBackgroundColor.withAlpha((0.9 * 255).round()),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.1 * 255).round()),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.check_mark_circled,
                color: CupertinoColors.activeGreen,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(message, style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = themeService.getTextColor();
    final backgroundColor = themeService.getBackgroundColor();
    final cardColor = themeService.getCardColor();
    final separatorColor = themeService.getSeparatorColor();
    final secondaryTextColor = themeService.getSecondaryTextColor();
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
        middle: Text(_isEditing ? 'Modifier le profil' : 'Profil'),
        backgroundColor:
            _isEditing
                ? primaryColor.withAlpha((0.1 * 255).round())
                : backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: _isEditing ? primaryColor : separatorColor,
            width: _isEditing ? 1.0 : 0.5,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed:
              _isEditing
                  ? _updateProfile
                  : () => setState(() => _isEditing = true),
          child:
              _isEditing
                  ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'Enregistrer',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  )
                  : Text('Modifier', style: TextStyle(color: primaryColor)),
        ),
      ),
      child: SafeArea(
        child:
            _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _buildProfileContent(
                  textColor,
                  secondaryTextColor,
                  backgroundColor,
                  cardColor,
                  separatorColor,
                ),
      ),
    );
  }

  Widget _buildProfileContent(
    Color textColor,
    Color secondaryTextColor,
    Color backgroundColor,
    Color cardColor,
    Color separatorColor,
  ) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside input fields
        FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header with avatar and name
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    // Profile avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: separatorColor, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: CupertinoTheme.of(
                          context,
                        ).primaryColor.withAlpha((0.1 * 255).round()),
                        child: Icon(
                          CupertinoIcons.person_fill,
                          size: 40,
                          color: CupertinoTheme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name and role
                    Text(
                      '${_firstNameController.text} ${_lastNameController.text}'
                          .trim(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.person_crop_circle_badge_checkmark,
                          size: 14,
                          color: _getUserRoleColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _translateRole(_userRole),
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Informations personnelles'),
                    const SizedBox(height: 8),

                    _buildFormSection(
                      cardColor: cardColor,
                      separatorColor: separatorColor,
                      children: [
                        _buildTextField(
                          label: 'Prénom',
                          controller: _firstNameController,
                          enabled: _isEditing,
                          textColor: textColor,
                          separatorColor: separatorColor,
                          icon: CupertinoIcons.person,
                        ),
                        _buildTextField(
                          label: 'Nom',
                          controller: _lastNameController,
                          enabled: _isEditing,
                          textColor: textColor,
                          separatorColor: separatorColor,
                          icon: CupertinoIcons.person,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Contact'),
                    const SizedBox(height: 8),

                    _buildFormSection(
                      cardColor: cardColor,
                      separatorColor: separatorColor,
                      children: [
                        _buildTextField(
                          label: 'Email',
                          controller: _emailController,
                          enabled: false, // Email can't be edited
                          textColor: textColor.withAlpha((0.7 * 255).round()),
                          separatorColor: separatorColor,
                          icon: CupertinoIcons.mail,
                        ),
                        _buildTextField(
                          label: 'Téléphone',
                          controller: _phoneController,
                          enabled: _isEditing,
                          textColor: textColor,
                          separatorColor: separatorColor,
                          icon: CupertinoIcons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Paramètres de facturation'),
                    const SizedBox(height: 8),

                    _buildFormSection(
                      cardColor: cardColor,
                      separatorColor: separatorColor,
                      children: [
                        _buildTextField(
                          label: 'Tarif horaire',
                          controller: _hourlyRateController,
                          enabled: false, // Changed to false to prevent editing
                          textColor: textColor.withAlpha((0.7 * 255).round()),
                          separatorColor: separatorColor,
                          icon: CupertinoIcons.money_euro,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),

                    // Error message if present
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: CupertinoColors.systemRed,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: CupertinoTheme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildFormSection({
    required Color cardColor,
    required Color separatorColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: separatorColor, width: 0.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required Color textColor,
    required Color separatorColor,
    required IconData icon,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color:
                    enabled
                        ? CupertinoTheme.of(context).primaryColor
                        : textColor.withAlpha((0.5 * 255).round()),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withAlpha((0.6 * 255).round()),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 100,
                    child: CupertinoTextField(
                      controller: controller,
                      placeholder:
                          enabled ? 'Entrez votre ${label.toLowerCase()}' : '',
                      enabled: enabled,
                      decoration: const BoxDecoration(border: null),
                      padding: EdgeInsets.zero,
                      suffix: suffix,
                      style: TextStyle(color: textColor, fontSize: 16),
                      keyboardType: keyboardType,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Removed the problematic children.last reference
        Divider(height: 1, thickness: 0.5, color: separatorColor, indent: 48),
      ],
    );
  }

  // Helper method to get color based on user role
  Color _getUserRoleColor() {
    switch (_userRole.toLowerCase()) {
      case 'admin':
        return CupertinoColors.systemRed;
      case 'staff':
        return CupertinoColors.systemBlue;
      case 'customer':
      default:
        return CupertinoColors.activeGreen;
    }
  }

  // Helper method to translate user role text
  String _translateRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrateur';
      case 'staff':
        return 'Personnel';
      case 'customer':
        return 'Client';
      default:
        return role.isEmpty
            ? ''
            : role.substring(0, 1).toUpperCase() +
                role.substring(1).toLowerCase();
    }
  }
}
