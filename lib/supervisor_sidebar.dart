import 'package:flutter/material.dart';
import 'theme.dart';

class SupervisorSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const SupervisorSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [DS.darkSurface, DS.primary900]
              : [DS.primary800, DS.primary900],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative bubbles
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          Positioned(
            bottom: 60, left: -30,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.02),
              ),
            ),
          ),

          Column(
            children: [
              // ── Logo ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                child: Row(
                  children: [
                    Image.asset('assets/images/logo_icon.png', width: 36, height: 36),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Presen',
                                style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800,
                                  color: DS.primary50, letterSpacing: -0.5,
                                ),
                              ),
                              TextSpan(
                                text: 'See',
                                style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800,
                                  color: DS.primary300, letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'SMART ATTENDANCE',
                          style: TextStyle(
                            fontSize: 8, color: DS.primary300,
                            letterSpacing: 2.5, fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Section Label ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SUPERVISOR PANEL',
                    style: TextStyle(
                      fontSize: 10, color: DS.primary400,
                      letterSpacing: 1.5, fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Menu Items ──
              _buildItem(0, Icons.dashboard_rounded, 'Dashboard'),
              _buildItem(1, Icons.people_rounded, 'Students'),
              _buildItem(2, Icons.description_rounded, 'Excuses'),

              const Spacer(),

              // ── Supervisor Info ──
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(DS.radiusMD),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: DS.primary600,
                      child: const Text('DH',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dr. Hessah',
                            style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          Text('Engineering',
                            style: TextStyle(fontSize: 11, color: DS.primary400),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.logout_rounded, size: 18, color: DS.primary400),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(int index, IconData icon, String label) {
    final isActive = index == selectedIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(DS.radiusMD),
        child: InkWell(
          borderRadius: BorderRadius.circular(DS.radiusMD),
          onTap: () => onItemSelected(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? DS.primary500.withOpacity(0.25) : Colors.transparent,
              borderRadius: BorderRadius.circular(DS.radiusMD),
              border: Border(
                left: BorderSide(
                  color: isActive ? DS.primary400 : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: isActive ? Colors.white : DS.primary300),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? Colors.white : DS.primary300,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}