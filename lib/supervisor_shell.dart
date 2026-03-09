import 'package:flutter/material.dart';
import 'theme.dart';
import 'supervisor_dashboard.dart';
import 'supervisor_students_list.dart';
import 'supervisor_excuses.dart';

// ═══════════════════════════════════════════════════════
//  SupervisorShell — Main layout: Sidebar + Pages
// ═══════════════════════════════════════════════════════

class SupervisorShell extends StatefulWidget {
  final String supervisorId;
  const SupervisorShell({super.key, required this.supervisorId});
  @override
  State<SupervisorShell> createState() => _SupervisorShellState();
}

class _SupervisorShellState extends State<SupervisorShell> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DS.neutral50,
      body: Row(children: [
        _Sidebar(
          selected: _idx,
          onTap: (i) => setState(() => _idx = i),
          supervisorId: widget.supervisorId,
        ),
        Expanded(child: _page()),
      ]),
    );
  }

  Widget _page() => switch (_idx) {
    0 => SupervisorDashboard(
      supervisorId: widget.supervisorId,
      onViewStudents: () => setState(() => _idx = 1),
      onViewExcuses: () => setState(() => _idx = 2),
    ),
    1 => SupervisorStudentsList(supervisorId: widget.supervisorId),
    2 => SupervisorExcuses(supervisorId: widget.supervisorId),
    _ => SupervisorDashboard(supervisorId: widget.supervisorId),
  };
}

// ═══════════════════════════════════════════════════════
//  Sidebar
// ═══════════════════════════════════════════════════════

class _Sidebar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  final String supervisorId;

  const _Sidebar({required this.selected, required this.onTap, required this.supervisorId});

  static const _items = [
    (Icons.dashboard_rounded, 'Dashboard'),
    (Icons.people_rounded, 'Students'),
    (Icons.description_rounded, 'Excuses'),
  ];

  @override
  Widget build(BuildContext context) {
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
        // Decorative orbs
        Positioned(top: -50, right: -50, child: _orb(180, DS.primary500.withOpacity(0.04))),
        Positioned(bottom: 40, left: -40, child: _orb(140, DS.accentTeal.withOpacity(0.03))),

        Column(children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
            child: Row(children: [
              Image.asset('assets/logos/logo_icon.png', width: 34, height: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Image.asset('assets/logos/logo_full_dark.png', height: 22, fit: BoxFit.contain, alignment: Alignment.centerLeft),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: Colors.white.withOpacity(0.06), height: 1),
          ),
          const SizedBox(height: 20),

          // Section label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('SUPERVISOR', style: TextStyle(fontSize: 10, color: DS.primary400.withOpacity(0.6), letterSpacing: 2, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),

          // Menu items
          ...List.generate(_items.length, (i) => _menuItem(i, _items[i].$1, _items[i].$2)),

          const Spacer(),

          // User card
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
                child: const Center(child: Text('DH', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Dr. Hessah', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                Text('Engineering', style: TextStyle(fontSize: 11, color: DS.primary300.withOpacity(0.6))),
              ])),
              IconButton(
                icon: Icon(Icons.logout_rounded, size: 18, color: Colors.white.withOpacity(0.3)),
                onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
              ),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _menuItem(int i, IconData icon, String label) {
    final active = i == selected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onTap(i),
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

  Widget _orb(double size, Color color) => Container(
    width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}