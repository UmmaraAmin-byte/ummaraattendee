import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'dashboards/super_admin_dashboard.dart';
import 'dashboards/organizer_dashboard.dart';
import 'dashboards/staff_dashboard.dart';
import 'dashboards/attendee_dashboard.dart';

class RegisterScreen extends StatefulWidget {
  final UserRole role;

  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _interestCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMsg;

  late final UserRole _selectedRole;
  final List<String> _interests = [];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role;
  }

  void _addInterest() {
    final val = _interestCtrl.text.trim();
    if (val.isEmpty) return;
    if (_interests.contains(val)) return;
    setState(() {
      _interests.add(val);
      _interestCtrl.clear();
    });
  }

  void _removeInterest(String interest) {
    setState(() => _interests.remove(interest));
  }

  Future<void> _handleRegister() async {
    setState(() => _errorMsg = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 400));

    final error = _auth.register(
      fullName: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
      role: _selectedRole,
      company: _companyCtrl.text.isEmpty ? null : _companyCtrl.text,
      industry: _industryCtrl.text.isEmpty ? null : _industryCtrl.text,
      phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
      bio: _bioCtrl.text.isEmpty ? null : _bioCtrl.text,
      interests: _interests,
    );

    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMsg = error);
      return;
    }

    _navigateToDashboard(_auth.currentUser!);
  }

  void _navigateToDashboard(UserModel user) {
    Widget dashboard;
    switch (user.role) {
      case UserRole.superAdmin:
        dashboard = const SuperAdminDashboard();
        break;
      case UserRole.organizer:
        dashboard = const OrganizerDashboard();
        break;
      case UserRole.staff:
        dashboard = const StaffDashboard();
        break;
      case UserRole.attendee:
        dashboard = const AttendeeDashboard();
        break;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => dashboard),
          (route) => false,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool optional = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: optional ? '$label (optional)' : label,
        prefixIcon: Icon(icon, color: const Color(0xFF2D2D2D), size: 20),
      ),
      validator: validator ??
          (optional
              ? null
              : (v) {
            if (v == null || v.trim().isEmpty) return '$label is required';
            return null;
          }),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _companyCtrl.dispose();
    _industryCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _interestCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A1A1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _selectedRole == UserRole.staff
              ? 'Register as Venue Owner'
              : 'Register as ${_selectedRole.displayName}',
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Error Banner ──────────────────────
                if (_errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border:
                      Border.all(color: Colors.red.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMsg!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Section: Basic Info ───────────────
                _buildSectionTitle('BASIC INFORMATION'),
                _buildTextField(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _emailCtrl,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _phoneCtrl,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  optional: true,
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('ROLE'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: Text(
                    _selectedRole == UserRole.staff
                        ? 'Venue Owner'
                        : _selectedRole.displayName,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Section: Professional Info ────────
                _buildSectionTitle('PROFESSIONAL DETAILS'),
                _buildTextField(
                  controller: _companyCtrl,
                  label: 'Company / Organization',
                  icon: Icons.business_outlined,
                  optional: true,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _industryCtrl,
                  label: 'Industry',
                  icon: Icons.work_outline,
                  optional: true,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _bioCtrl,
                  label: 'Bio',
                  icon: Icons.notes_outlined,
                  maxLines: 3,
                  optional: true,
                ),
                const SizedBox(height: 24),

                // ── Section: Interests ────────────────
                _buildSectionTitle('INTERESTS'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _interestCtrl,
                        style: const TextStyle(color: Color(0xFF1A1A1A)),
                        decoration: const InputDecoration(
                          labelText: 'Add an interest',
                          prefixIcon: Icon(Icons.tag,
                              color: Color(0xFF2D2D2D), size: 20),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
                        .map(
                          (i) => Chip(
                          label: Text(i,
                            style: const TextStyle(
                                color: Color(0xFF1A1A1A), fontSize: 12)),
                        backgroundColor: const Color(0xFFF0F0F0),
                        side: const BorderSide(color: Color(0xFFE8E8E8)),
                        deleteIcon: const Icon(Icons.close,
                            size: 14, color: Color(0xFF6B6B6B)),
                        onDeleted: () => _removeInterest(i),
                      ),
                    )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),

                // ── Section: Password ─────────────────
                _buildSectionTitle('SECURITY'),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  style: const TextStyle(color: Color(0xFF1A1A1A)),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: Color(0xFF2D2D2D), size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF6B6B6B),
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Min. 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: Color(0xFF1A1A1A)),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_reset_outlined,
                        color: Color(0xFF2D2D2D), size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF6B6B6B),
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm password';
                    if (v != _passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // ── Register Button ───────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
    );
  }
}