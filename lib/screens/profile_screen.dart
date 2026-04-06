import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../utils/validators.dart';
import 'landing_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  late TabController _tabCtrl;
  bool _redirecting = false;

  // Profile form controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _interestCtrl = TextEditingController();
  List<String> _interests = [];

  // Password form controllers
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _profileLoading = false;
  bool _passLoading = false;
  String? _profileError;
  String? _profileSuccess;
  String? _passError;
  String? _passSuccess;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final _profileFormKey = GlobalKey<FormState>();
  final _passFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _populateFields();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _guardAuth();
  }

  void _guardAuth() {
    if (_redirecting) return;
    final user = _auth.currentUser;
    if (user == null) {
      _redirecting = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LandingScreen()),
          (r) => false,
        );
      });
    }
  }

  void _populateFields() {
    final user = _auth.currentUser;
    if (user == null) return;
    _nameCtrl.text = user.fullName;
    _emailCtrl.text = user.email;
    _companyCtrl.text = user.company ?? '';
    _industryCtrl.text = user.industry ?? '';
    _phoneCtrl.text = user.phone ?? '';
    _bioCtrl.text = user.bio ?? '';
    _interests = List.from(user.interests);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _companyCtrl.dispose();
    _industryCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _interestCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _profileError = null;
      _profileSuccess = null;
    });
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _profileLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));

    final error = _auth.updateProfile(
      fullName: _nameCtrl.text,
      email: _emailCtrl.text,
      company: _companyCtrl.text,
      industry: _industryCtrl.text,
      phone: _phoneCtrl.text,
      bio: _bioCtrl.text,
      interests: _interests,
    );

    setState(() {
      _profileLoading = false;
      if (error != null) {
        _profileError = error;
      } else {
        _profileSuccess = 'Profile updated successfully!';
      }
    });
  }

  Future<void> _changePassword() async {
    setState(() {
      _passError = null;
      _passSuccess = null;
    });
    if (!_passFormKey.currentState!.validate()) return;
    setState(() => _passLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));

    final error =
    _auth.changePassword(_currentPassCtrl.text, _newPassCtrl.text);

    setState(() {
      _passLoading = false;
      if (error != null) {
        _passError = error;
      } else {
        _passSuccess = 'Password changed successfully!';
        _currentPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
      }
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(color: Color(0xFF1A1A1A))),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: Color(0xFF6B6B6B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6060A0))),
          ),
          ElevatedButton(
            onPressed: () {
              _auth.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LandingScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D2D2D)),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _addInterest() {
    final val = _interestCtrl.text.trim();
    if (val.isEmpty || _interests.contains(val)) return;
    setState(() {
      _interests.add(val);
      _interestCtrl.clear();
    });
  }

  Widget _buildFeedback(String? error, String? success) {
    if (error != null) {
      return _buildBanner(error, Colors.redAccent, Icons.error_outline);
    }
    if (success != null) {
      return _buildBanner(success, Colors.greenAccent, Icons.check_circle_outline);
    }
    return const SizedBox.shrink();
  }

  Widget _buildBanner(String msg, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(msg, style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool optional = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: optional ? '$label (optional)' : label,
        prefixIcon: Icon(icon, color: const Color(0xFF2D2D2D), size: 20),
      ),
      validator: validator ??
          (optional
              ? null
              : (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        title: const Text('My Profile',
            style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF1A1A1A)),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFF2D2D2D),
          labelColor: const Color(0xFF2D2D2D),
          unselectedLabelColor: const Color(0xFF6B6B6B),
          tabs: const [
            Tab(text: 'Edit Profile'),
            Tab(text: 'Change Password'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── User Info Header ──────────────────
          Container(
            color: const Color(0xFFFFFFFF),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFF0F0F0),
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Color(0xFF2D2D2D),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${user.role.emoji} ${user.role.displayName}',
                          style: const TextStyle(
                            color: Color(0xFF2D2D2D),
                            fontSize: 12,
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

          // ── Tab Content ───────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // ── Tab 1: Edit Profile ───────────
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _profileFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFeedback(_profileError, _profileSuccess),
                        _buildField(
                          controller: _nameCtrl,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          controller: _emailCtrl,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: EmailValidator.validate,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          controller: _phoneCtrl,
                          label: 'Phone',
                          icon: Icons.phone_outlined,
                          optional: true,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          controller: _companyCtrl,
                          label: 'Company',
                          icon: Icons.business_outlined,
                          optional: true,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          controller: _industryCtrl,
                          label: 'Industry',
                          icon: Icons.work_outline,
                          optional: true,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          controller: _bioCtrl,
                          label: 'Bio',
                          icon: Icons.notes_outlined,
                          optional: true,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),

                        // Interests
                        const Text('Interests',
                            style: TextStyle(
                                color: Color(0xFF2D2D2D),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 1)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _interestCtrl,
                                style: const TextStyle(color: Color(0xFF1A1A1A)),
                                decoration: const InputDecoration(
                                  labelText: 'Add interest',
                                  prefixIcon: Icon(Icons.tag,
                                      color: Color(0xFF2D2D2D), size: 18),
                                ),
                                onFieldSubmitted: (_) => _addInterest(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _addInterest,
                              style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12))),
                              child: const Icon(Icons.add, size: 20),
                            ),
                          ],
                        ),
                        if (_interests.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _interests
                                .map((i) => Chip(
                              label: Text(i,
                                  style: const TextStyle(
                                      color: Color(0xFF1A1A1A),
                                      fontSize: 12)),
                              backgroundColor: const Color(0xFFF0F0F0),
                              side: const BorderSide(
                                  color: Color(0xFFE8E8E8)),
                              deleteIcon: const Icon(Icons.close,
                                  size: 14, color: Color(0xFF6B6B6B)),
                              onDeleted: () => setState(
                                      () => _interests.remove(i)),
                            ))
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 28),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _profileLoading ? null : _saveProfile,
                            child: _profileLoading
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white),
                            )
                                : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Tab 2: Change Password ────────
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _passFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFeedback(_passError, _passSuccess),
                        _buildPasswordField(
                          controller: _currentPassCtrl,
                          label: 'Current Password',
                          obscure: _obscureCurrent,
                          toggle: () => setState(
                                  () => _obscureCurrent = !_obscureCurrent),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Current password is required'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _buildPasswordField(
                          controller: _newPassCtrl,
                          label: 'New Password',
                          obscure: _obscureNew,
                          toggle: () =>
                              setState(() => _obscureNew = !_obscureNew),
                          validator: PasswordValidator.validate,
                        ),
                        const SizedBox(height: 14),
                        _buildPasswordField(
                          controller: _confirmPassCtrl,
                          label: 'Confirm New Password',
                          obscure: _obscureConfirm,
                          toggle: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please confirm new password.';
                            }
                            if (v != _newPassCtrl.text) {
                              return 'Passwords do not match.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                            _passLoading ? null : _changePassword,
                            child: _passLoading
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white),
                            )
                                : const Text('Change Password'),
                          ),
                        ),
                      ],
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
        const Icon(Icons.lock_outline, color: Color(0xFF2D2D2D), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF6B6B6B),
          ),
          onPressed: toggle,
        ),
      ),
      validator: validator,
    );
  }
}