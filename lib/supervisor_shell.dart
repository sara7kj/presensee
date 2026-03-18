import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme.dart';
import 'supervisor_dashboard.dart';
import 'supervisor_students_list.dart';
import 'supervisor_excuses.dart';
import 'web_login_page.dart';

class SupervisorShell extends StatefulWidget {
  final String supervisorId;
  final String supervisorName;    // ← ديناميكي من Firestore
  final String supervisorEmail;   // ← ديناميكي من Firestore
  final String department;        // ← ديناميكي من Firestore

  const SupervisorShell({
    super.key,
    required this.supervisorId,
    required this.supervisorName,
    required this.supervisorEmail,
    required this.department,
  });

  @override
  State<SupervisorShell> createState() => _SupervisorShellState();
}

class _SupervisorShellState extends State<SupervisorShell> {
  int _idx = 0;

  // الأحرف الأولى من الاسم — ديناميكية
  String get _initials => widget.supervisorName
      .split(' ')
      .map((w) => w.isNotEmpty ? w[0] : '')
      .take(2)
      .join()
      .toUpperCase();

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WebLoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DS.neutral50,
      body: Row(children: [
        _buildSidebar(),
        Expanded(child: _page()),
      ]),
    );
  }

  Widget _page() => switch (_idx) {
    0 => SupervisorDashboard(
      supervisorId: widget.supervisorId,
      supervisorName: widget.supervisorName,
      onViewStudents: () => setState(() => _idx = 1),
      onViewExcuses: () => setState(() => _idx = 2),
    ),
    1 => SupervisorStudentsList(supervisorId: widget.supervisorId),
    2 => SupervisorExcuses(supervisorId: widget.supervisorId),
    _ => SupervisorDashboard(
      supervisorId: widget.supervisorId,
      supervisorName: widget.supervisorName,
    ),
  };

  // ═══════════════════════════════════════════════════════
  //  Sidebar — كل شي ديناميكي
  // ═══════════════════════════════════════════════════════

  static const _items = [
    (Icons.dashboard_rounded, 'Dashboard'),
    (Icons.people_rounded, 'Students'),
    (Icons.description_rounded, 'Excuses'),
  ];

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0D1B33), DS.primary900, Color(0xFF081428)],
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(4, 0))],
      ),
      child: Stack(children: [
        Positioned(top: -50, right: -50,
          child: Container(width: 180, height: 180,
            decoration: BoxDecoration(shape: BoxShape.circle, color: DS.primary500.withOpacity(0.04)))),
        Positioned(bottom: 40, left: -40,
          child: Container(width: 140, height: 140,
            decoration: BoxDecoration(shape: BoxShape.circle, color: DS.accentTeal.withOpacity(0.03)))),

        Column(children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
            child: Row(children: [
              Image.asset('assets/logos/logo_icon.png', width: 34, height: 34),
              const SizedBox(width: 10),
              Expanded(child: Image.asset('assets/logos/logo_full_dark.png',
                height: 22, fit: BoxFit.contain, alignment: Alignment.centerLeft)),
            ]),
          ),
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: Colors.white.withOpacity(0.06), height: 1)),
          const SizedBox(height: 20),

          // Section label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Align(alignment: Alignment.centerLeft,
              child: Text('SUPERVISOR', style: TextStyle(fontSize: 10,
                color: DS.primary400.withOpacity(0.6), letterSpacing: 2, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 12),

          // Menu
          ...List.generate(_items.length, (i) => _menuItem(i, _items[i].$1, _items[i].$2)),

          const Spacer(),

          // ── User Card — ديناميكي بالكامل ──
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [DS.primary500, DS.accentTeal]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(
                  _initials,  // ← ديناميكي
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                )),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  widget.supervisorName,  // ← ديناميكي
                  style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.department,  // ← ديناميكي
                  style: TextStyle(fontSize: 11, color: DS.primary300.withOpacity(0.6)),
                ),
              ])),
              IconButton(
                icon: Icon(Icons.logout_rounded, size: 18, color: Colors.white.withOpacity(0.3)),
                onPressed: _logout,
                tooltip: 'Sign out',
              ),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _menuItem(int i, IconData icon, String label) {
    final active = i == _idx;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Material(
        color: Colors.transparent, borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _idx = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: active ? DS.primary500.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border(left: BorderSide(color: active ? DS.primary400 : Colors.transparent, width: 3)),
            ),
            child: Row(children: [
              Icon(icon, size: 20, color: active ? Colors.white : Colors.white.withOpacity(0.3)),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? Colors.white : Colors.white.withOpacity(0.3))),
              if (active) ...[
                const Spacer(),
                Container(width: 6, height: 6, decoration: BoxDecoration(color: DS.accentTeal, borderRadius: BorderRadius.circular(3))),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}