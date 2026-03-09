import 'package:flutter/material.dart';
import 'theme.dart';
import 'supervisor_sidebar.dart';
import 'supervisor_dashboard.dart';
import 'supervisor_students_list.dart';
import 'supervisor_excuses.dart';

/// الصفحة الرئيسية للسوبرفايزر — Sidebar + المحتوى
/// استخدمها بعد اللوقن:
///
/// Navigator.pushReplacement(
///   context,
///   MaterialPageRoute(
///     builder: (_) => SupervisorShell(supervisorId: 'SUP001'),
///   ),
/// );

class SupervisorShell extends StatefulWidget {
  final String supervisorId;
  const SupervisorShell({super.key, required this.supervisorId});

  @override
  State<SupervisorShell> createState() => _SupervisorShellState();
}

class _SupervisorShellState extends State<SupervisorShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DS.neutral50,
      body: Row(
        children: [
          SupervisorSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (i) => setState(() => _selectedIndex = i),
          ),
          Expanded(child: _buildPage()),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return SupervisorDashboard(
          supervisorId: widget.supervisorId,
          onViewAllStudents: () => setState(() => _selectedIndex = 1),
          onViewAllExcuses: () => setState(() => _selectedIndex = 2),
        );
      case 1:
        return SupervisorStudentsList(supervisorId: widget.supervisorId);
      case 2:
        return SupervisorExcuses(supervisorId: widget.supervisorId);
      default:
        return SupervisorDashboard(
          supervisorId: widget.supervisorId,
          onViewAllStudents: () => setState(() => _selectedIndex = 1),
          onViewAllExcuses: () => setState(() => _selectedIndex = 2),
        );
    }
  }
}