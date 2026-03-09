import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme.dart';

class SupervisorDashboard extends StatelessWidget {
  final String supervisorId;
  final VoidCallback? onViewAllStudents;
  final VoidCallback? onViewAllExcuses;

  const SupervisorDashboard({
    super.key,
    required this.supervisorId,
    this.onViewAllStudents,
    this.onViewAllExcuses,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text('Dashboard',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: DS.neutral900)),
          const SizedBox(height: 4),
          const Text('Overview of trainee attendance',
            style: TextStyle(fontSize: 14, color: DS.neutral500)),
          const SizedBox(height: 28),

          // Stats Cards
          _StatsSection(supervisorId: supervisorId),
          const SizedBox(height: 28),

          // Performance + Students Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _PerformanceCard(supervisorId: supervisorId)),
              const SizedBox(width: 18),
              Expanded(child: _RecentStudentsCard(supervisorId: supervisorId, onViewAll: onViewAllStudents)),
            ],
          ),
          const SizedBox(height: 18),

          // Pending Excuses
          _PendingExcusesCard(supervisorId: supervisorId, onViewAll: onViewAllExcuses),
        ],
      ),
    );
  }
}

// ──────────── Stats Cards ────────────

class _StatsSection extends StatelessWidget {
  final String supervisorId;
  const _StatsSection({required this.supervisorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Trainees')
          .where('supervisorId', isEqualTo: supervisorId)
          .snapshots(),
      builder: (context, snapshot) {
        final total = snapshot.data?.docs.length ?? 0;
        final today = DateTime.now();
        final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        if (!snapshot.hasData || total == 0) return _buildCards(0, 0, 0, 0);

        final ids = snapshot.data!.docs.map((d) => d['studentId'] as String).toList();

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('AttendanceRecords')
              .where('studentId', whereIn: ids)
              .where('date', isEqualTo: todayStr)
              .get(),
          builder: (context, attSnap) {
            int present = 0, absent = 0, excused = 0;
            if (attSnap.hasData) {
              for (var doc in attSnap.data!.docs) {
                final s = doc['status'] as String;
                if (s == 'present') present++;
                else if (s == 'absent') absent++;
                else excused++;
              }
              absent += total - (present + absent + excused);
            }
            return _buildCards(total, present, absent, excused);
          },
        );
      },
    );
  }

  Widget _buildCards(int total, int present, int absent, int excused) {
    final items = [
      ('Total Students', '$total', Icons.people_rounded, DS.primary500, DS.primary50),
      ('Present Today', '$present', Icons.check_circle_rounded, DS.statusPresent, DS.statusPresentBg),
      ('Absent Today', '$absent', Icons.cancel_rounded, DS.statusAbsent, DS.statusAbsentBg),
      ('Excused', '$excused', Icons.description_rounded, DS.accentViolet, DS.statusExcusedBg),
    ];

    return Row(
      children: items.map((c) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _StatCard(label: c.$1, value: c.$2, icon: c.$3, color: c.$4, bgColor: c.$5),
        ),
      )).toList(),
    );
  }
}

class _StatCard extends StatefulWidget {
  final String label, value;
  final IconData icon;
  final Color color, bgColor;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.bgColor});

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DS.radiusLG),
          border: Border.all(color: DS.neutral200),
          boxShadow: _hover ? DS.shadowMD : DS.shadowSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: widget.bgColor, borderRadius: BorderRadius.circular(DS.radiusMD)),
              child: Icon(widget.icon, color: widget.color, size: 24),
            ),
            const SizedBox(height: 14),
            Text(widget.value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: DS.neutral900)),
            const SizedBox(height: 4),
            Text(widget.label, style: const TextStyle(fontSize: 13, color: DS.neutral500)),
          ],
        ),
      ),
    );
  }
}

// ──────────── Performance Card ────────────

class _PerformanceCard extends StatelessWidget {
  final String supervisorId;
  const _PerformanceCard({required this.supervisorId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DS.radiusLG),
        border: Border.all(color: DS.neutral200),
        boxShadow: DS.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Performance",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: DS.neutral800)),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 140, height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: 0.75,
                    strokeWidth: 12,
                    backgroundColor: DS.neutral100,
                    valueColor: const AlwaysStoppedAnimation(DS.statusPresent),
                    strokeCap: StrokeCap.round,
                  ),
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('75%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: DS.neutral900)),
                        Text('Attendance', style: TextStyle(fontSize: 11, color: DS.neutral500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dot(DS.statusPresent, 'Present'),
              const SizedBox(width: 20),
              _dot(DS.statusAbsent, 'Absent'),
              const SizedBox(width: 20),
              _dot(DS.accentViolet, 'Excused'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c, String l) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(5))),
    const SizedBox(width: 6),
    Text(l, style: const TextStyle(fontSize: 12, color: DS.neutral600)),
  ]);
}

// ──────────── Recent Students ────────────

class _RecentStudentsCard extends StatelessWidget {
  final String supervisorId;
  final VoidCallback? onViewAll;
  const _RecentStudentsCard({required this.supervisorId, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DS.radiusLG),
        border: Border.all(color: DS.neutral200),
        boxShadow: DS.shadowSM,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Students', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: DS.neutral800)),
              if (onViewAll != null) TextButton(onPressed: onViewAll, child: const Text('View All →')),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Trainees')
                .where('supervisorId', isEqualTo: supervisorId)
                .limit(4)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Padding(padding: EdgeInsets.all(20), child: Text('No students yet', style: TextStyle(color: DS.neutral400)));
              }
              return Column(
                children: snap.data!.docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final name = d['name'] ?? 'Unknown';
                  final email = d['email'] ?? '';
                  final initials = name.toString().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: DS.neutral100))),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 18, backgroundColor: DS.primary100, child: Text(initials, style: const TextStyle(color: DS.primary600, fontSize: 13, fontWeight: FontWeight.w700))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: DS.neutral800)),
                          Text(email, style: const TextStyle(fontSize: 12, color: DS.neutral500)),
                        ])),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ──────────── Pending Excuses ────────────

class _PendingExcusesCard extends StatelessWidget {
  final String supervisorId;
  final VoidCallback? onViewAll;
  const _PendingExcusesCard({required this.supervisorId, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DS.radiusLG),
        border: Border.all(color: DS.neutral200),
        boxShadow: DS.shadowSM,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pending Excuses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: DS.neutral800)),
              if (onViewAll != null) TextButton(onPressed: onViewAll, child: const Text('View All →')),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Excuses')
                .where('supervisorId', isEqualTo: supervisorId)
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Padding(padding: EdgeInsets.all(20), child: Text('No pending excuses', style: TextStyle(color: DS.neutral400, fontSize: 14)));
              }
              return Column(
                children: snap.data!.docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: DS.neutral100))),
                    child: Row(
                      children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d['studentName'] ?? 'Student', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: DS.neutral800)),
                          const SizedBox(height: 2),
                          Text('${d['type'] ?? 'Excuse'} • ${d['startDate'] ?? ''}', style: const TextStyle(fontSize: 12, color: DS.neutral500)),
                        ])),
                        StatusBadge(label: 'Pending', color: DS.statusLate, backgroundColor: DS.statusLateBg),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}