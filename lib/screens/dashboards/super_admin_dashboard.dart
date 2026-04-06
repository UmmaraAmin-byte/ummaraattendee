import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../profile_screen.dart';
import 'attendee_dashboard.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final _auth = AuthService();
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();
    _guardAuth();
  }

  void _guardAuth() {
    final user = _auth.currentUser;
    if (_redirecting) return;
    if (user == null || user.role != UserRole.superAdmin) {
      _redirecting = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AttendeeDashboard()),
          (r) => false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser!;
    final allUsers = _auth.allUsers;

    // Stats
    final organizers =
        allUsers.where((u) => u.role == UserRole.organizer).length;
    final staff = allUsers.where((u) => u.role == UserRole.staff).length;
    final attendees =
        allUsers.where((u) => u.role == UserRole.attendee).length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        title: const Row(
          children: [
            Text('👑', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              'Super Admin',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())).then((_) => setState(() {})),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF1A1A1A)),
            onPressed: () {
              _auth.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AttendeeDashboard()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome
            Text(
              'Welcome, ${user.fullName}',
              style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text('System overview & user management',
                style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 14)),
            const SizedBox(height: 24),

            // ── Stats Grid ────────────────────────
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.4,
              children: [
                _statCard('Total Users', '${allUsers.length}',
                    Icons.people_outline, const Color(0xFF2D2D2D)),
                _statCard('Organizers', '$organizers',
                    Icons.event_outlined, const Color(0xFF6B6B6B)),
                _statCard('Staff', '$staff',
                    Icons.support_agent_outlined, const Color(0xFF9E9E9E)),
                _statCard('Attendees', '$attendees',
                    Icons.confirmation_num_outlined, const Color(0xFF1A1A1A)),
              ],
            ),
            const SizedBox(height: 28),

            // ── User List ─────────────────────────
            const Text(
              'All Registered Users',
              style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),

            ...allUsers.map((u) => _userTile(u, canDelete: u.id != user.id)),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 26),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 26,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF6B6B6B), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userTile(UserModel u, {required bool canDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFF0F0F0),
            child: Text(
              u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Color(0xFF2D2D2D), fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.fullName,
                    style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(u.email,
                    style: const TextStyle(
                        color: Color(0xFF6B6B6B), fontSize: 12)),
              ],
            ),
          ),
          // Role badge
          GestureDetector(
            onTap: () => _showRoleChangeDialog(u),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _roleColor(u.role).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                Border.all(color: _roleColor(u.role).withOpacity(0.5)),
              ),
              child: Text(
                '${u.role.emoji} ${u.role.displayName}',
                style: TextStyle(
                    color: _roleColor(u.role),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (canDelete) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              onPressed: () => _confirmDelete(u),
            ),
          ],
        ],
      ),
    );
  }

  void _showRoleChangeDialog(UserModel u) {
    UserRole selected = u.role;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFFFFFFFF),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Change Role: ${u.fullName}',
              style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: UserRole.values.map((role) {
              return RadioListTile<UserRole>(
                value: role,
                groupValue: selected,
                title: Text('${role.emoji} ${role.displayName}',
                    style: const TextStyle(color: Color(0xFF1A1A1A))),
                activeColor: const Color(0xFF2D2D2D),
                onChanged: (v) => setS(() => selected = v!),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: Color(0xFF6B6B6B)))),
            ElevatedButton(
              onPressed: () {
                _auth.changeUserRole(u.id, selected);
                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(UserModel u) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete User',
            style: TextStyle(color: Color(0xFF1A1A1A))),
        content: Text(
            'Are you sure you want to delete "${u.fullName}"? This cannot be undone.',
            style: const TextStyle(color: Color(0xFF6B6B6B))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF6B6B6B)))),
          ElevatedButton(
            onPressed: () {
              _auth.deleteUser(u.id);
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return const Color(0xFF1A1A1A);
      case UserRole.organizer:
        return const Color(0xFF2D2D2D);
      case UserRole.staff:
        return const Color(0xFF6B6B6B);
      case UserRole.attendee:
        return const Color(0xFF9E9E9E);
    }
  }
}