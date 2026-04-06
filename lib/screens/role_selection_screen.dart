import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        title: const Text(
          'Select Role',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Continue as',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose your dashboard role to sign in.',
              style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 14),
            ),
            const SizedBox(height: 24),
            _RoleCard(
              icon: Icons.storefront_outlined,
              title: 'Venue Owner',
              subtitle: 'Manage venue operations and attendee check-ins.',
              onTap: () => _goLogin(context, UserRole.staff),
            ),
            const SizedBox(height: 14),
            _RoleCard(
              icon: Icons.confirmation_num_outlined,
              title: 'Attendee',
              subtitle: 'Discover events and register in seconds.',
              onTap: () => _goLogin(context, UserRole.attendee),
            ),
            const SizedBox(height: 14),
            _RoleCard(
              icon: Icons.event_note_outlined,
              title: 'Organizer',
              subtitle: 'Create and manage events and registrations.',
              onTap: () => _goLogin(context, UserRole.organizer),
            ),
            const SizedBox(height: 14),
            _RoleCard(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Admin',
              subtitle: 'Access super admin tools and user management.',
              onTap: () => _goLogin(context, UserRole.superAdmin),
            ),
          ],
        ),
      ),
    );
  }

  void _goLogin(BuildContext context, UserRole role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(role: role)),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF2D2D2D), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF6B6B6B)),
          ],
        ),
      ),
    );
  }
}
