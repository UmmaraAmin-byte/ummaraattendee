import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';

enum AuthIntent {
  attendeeRegister,
  organizerCreateEvent,
  ownerListVenue,
  adminAccess,
  generic,
}

class UnifiedAuthSheet extends StatefulWidget {
  final AuthIntent intent;
  final UserRole defaultRole;

  const UnifiedAuthSheet({
    super.key,
    required this.intent,
    required this.defaultRole,
  });

  static Future<bool> show(
    BuildContext context, {
    required AuthIntent intent,
    required UserRole defaultRole,
  }) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => UnifiedAuthSheet(intent: intent, defaultRole: defaultRole),
    );
    return ok ?? false;
  }

  @override
  State<UnifiedAuthSheet> createState() => _UnifiedAuthSheetState();
}

class _UnifiedAuthSheetState extends State<UnifiedAuthSheet>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  late final TabController _tabCtrl;
  late UserRole _role;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _role = widget.defaultRole;
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  String _title() {
    switch (widget.intent) {
      case AuthIntent.attendeeRegister:
        return 'Login to register';
      case AuthIntent.organizerCreateEvent:
        return 'Login to create events';
      case AuthIntent.ownerListVenue:
        return 'Login to list your venue';
      case AuthIntent.adminAccess:
        return 'Admin login';
      case AuthIntent.generic:
        return 'Welcome back';
    }
  }

  String _subtitle() {
    switch (widget.intent) {
      case AuthIntent.attendeeRegister:
        return 'Sign in or create an attendee account to continue.';
      case AuthIntent.organizerCreateEvent:
        return 'Sign in as an organizer to continue.';
      case AuthIntent.ownerListVenue:
        return 'Sign in as a venue owner to continue.';
      case AuthIntent.adminAccess:
        return 'Enter admin credentials.';
      case AuthIntent.generic:
        return 'Sign in to continue.';
    }
  }

  String _roleLabel(UserRole role) {
    if (role == UserRole.staff) return 'Venue Owner';
    return role.displayName;
  }

  bool _canChangeRole() {
    // UX: attendee flow should not force role picking up front,
    // but allow it when CTA implies organizer/owner/admin.
    switch (widget.intent) {
      case AuthIntent.attendeeRegister:
        return false;
      case AuthIntent.organizerCreateEvent:
        return false;
      case AuthIntent.ownerListVenue:
        return false;
      case AuthIntent.adminAccess:
        return false;
      case AuthIntent.generic:
        return true;
    }
  }

  List<UserRole> _roleChoices() {
    return const [
      UserRole.attendee,
      UserRole.organizer,
      UserRole.staff,
      UserRole.superAdmin,
    ];
  }

  Future<void> _login() async {
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _error = null;
      _loading = true;
    });
    await Future.delayed(const Duration(milliseconds: 200));
    final err = _auth.login(_emailCtrl.text, _passCtrl.text);
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    final user = _auth.currentUser!;
    if (widget.intent != AuthIntent.generic && user.role != _role) {
      _auth.logout();
      setState(() => _error = 'This account is not ${_roleLabel(_role)}.');
      return;
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _signup() async {
    if (!(_signupFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _error = null;
      _loading = true;
    });
    await Future.delayed(const Duration(milliseconds: 200));
    final err = _auth.register(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role: _role,
      interests: const [],
    );
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              _title(),
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _subtitle(),
              style: const TextStyle(color: Color(0xFF6B6B6B)),
            ),
            const SizedBox(height: 12),
            if (_canChangeRole())
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserRole>(
                    value: _role,
                    isExpanded: true,
                    icon: const Icon(Icons.expand_more, color: Color(0xFF6B6B6B)),
                    items: _roleChoices()
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(_roleLabel(r)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _role = v!),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: Text(
                  'Continue as ${_roleLabel(_role)}',
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabCtrl,
              labelColor: const Color(0xFF2D2D2D),
              unselectedLabelColor: const Color(0xFF6B6B6B),
              indicatorColor: const Color(0xFF2D2D2D),
              tabs: const [
                Tab(text: 'Login'),
                Tab(text: 'Sign up'),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.25)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              height: 260,
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _loginView(),
                  _signupView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loginView() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF2D2D2D)),
            ),
            validator: EmailValidator.validate,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2D2D2D)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF6B6B6B),
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Password is required.' : null,
          ),
          const Spacer(),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signupView() {
    return Form(
      key: _signupFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline, color: Color(0xFF2D2D2D)),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Full name is required.' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF2D2D2D)),
              ),
              validator: EmailValidator.validate,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2D2D2D)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF6B6B6B),
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                helperText: 'Min 8 chars with uppercase, lowercase, number & special character',
                helperMaxLines: 2,
              ),
              validator: PasswordValidator.validate,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _signup,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
