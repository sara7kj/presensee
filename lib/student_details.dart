import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme.dart';

class StudentDetailsPage extends StatelessWidget {
  final String studentId;
  final String studentName;

  const StudentDetailsPage({super.key, required this.studentId, required this.studentName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DS.neutral50,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Trainees').where('studentId', isEqualTo: studentId).limit(1).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: CircularProgressIndicator());

          final t = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final completed = (t['completedHours'] ?? 0).toDouble();
          final remaining = (t['remainingHours'] ?? 280).toDouble();
          final total = completed + remaining;
          final pct = total > 0 ? (completed / total * 100).round() : 0;
          final name = t['name'] ?? studentName;
          final email = t['email'] ?? '';
          final phone = t['phone'] ?? '';
          final initials = name.toString().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to Students'),
                ),
                const SizedBox(height: 16),

                // Header Card
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [DS.primary700, DS.primary500], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(DS.radiusXL),
                    boxShadow: [BoxShadow(color: DS.primary900.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Stack(children: [
                    Positioned(top: -30, right: -30, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
                    Row(children: [
                      CircleAvatar(radius: 32, backgroundColor: Colors.white.withOpacity(0.15), child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700))),
                      const SizedBox(width: 18),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('$email  •  $phone', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                      ]),
                    ]),
                  ]),
                ),
                const SizedBox(height: 24),

                // Stats
                _StatsRow(completed: completed, remaining: remaining, pct: pct, studentId: studentId),
                const SizedBox(height: 24),

                // Progress Bar
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(DS.radiusLG), border: Border.all(color: DS.neutral200), boxShadow: DS.shadowSM),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Training Progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: DS.neutral700)),
                      Text('${completed.toStringAsFixed(1)}h / ${total.toStringAsFixed(0)}h', style: const TextStyle(fontSize: 13, color: DS.neutral500)),
                    ]),
                    const SizedBox(height: 12),
                    ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: pct / 100, minHeight: 10, backgroundColor: DS.neutral100, valueColor: const AlwaysStoppedAnimation(DS.accentTeal))),
                  ]),
                ),
                const SizedBox(height: 24),

                // Attendance History
                _AttendanceHistory(studentId: studentId),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ──────────── Stats Row ────────────

class _StatsRow extends StatelessWidget {
  final double completed, remaining;
  final int pct;
  final String studentId;
  const _StatsRow({required this.completed, required this.remaining, required this.pct, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('AttendanceRecords').where('studentId', isEqualTo: studentId).snapshots(),
      builder: (context, snap) {
        int presentDays = 0, totalDays = 0;
        if (snap.hasData) {
          totalDays = snap.data!.docs.length;
          presentDays = snap.data!.docs.where((d) => (d['status'] as String?) == 'present').length;
        }
        final attPct = totalDays > 0 ? (presentDays / totalDays * 100).round() : 0;

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('Excuses').where('studentId', isEqualTo: studentId).get(),
          builder: (context, excSnap) {
            final totalExc = excSnap.data?.docs.length ?? 0;
            final approved = excSnap.data?.docs.where((d) => (d['status'] as String?) == 'approved').length ?? 0;

            return Row(children: [
              _miniCard('Completed', '${completed.toStringAsFixed(1)}h', 'of ${(completed + remaining).toStringAsFixed(0)}h', DS.primary500),
              _miniCard('Remaining', '${remaining.toStringAsFixed(1)}h', '$pct% done', DS.accentTeal),
              _miniCard('Attendance', '$attPct%', '$presentDays/$totalDays days', DS.statusPresent),
              _miniCard('Excuses', '$totalExc', '$approved approved', DS.accentViolet),
            ]);
          },
        );
      },
    );
  }

  Widget _miniCard(String label, String value, String sub, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(DS.radiusLG), border: Border.all(color: DS.neutral200), boxShadow: DS.shadowSM),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: DS.neutral500, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 12, color: DS.neutral400)),
          ]),
        ),
      ),
    );
  }
}

// ──────────── Attendance History ────────────

class _AttendanceHistory extends StatelessWidget {
  final String studentId;
  const _AttendanceHistory({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(DS.radiusLG), border: Border.all(color: DS.neutral200), boxShadow: DS.shadowSM),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Attendance History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: DS.neutral800)),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('AttendanceRecords').where('studentId', isEqualTo: studentId).orderBy('date', descending: true).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No records yet', style: TextStyle(color: DS.neutral400))));

            return DataTable(
              headingRowColor: WidgetStateProperty.all(DS.neutral50),
              headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DS.neutral500, letterSpacing: 0.5),
              columnSpacing: 32,
              columns: const [
                DataColumn(label: Text('DATE')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('CHECK IN')),
                DataColumn(label: Text('CHECK OUT')),
              ],
              rows: snap.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final status = d['status'] ?? 'absent';
                Widget badge;
                switch (status) {
                  case 'present': badge = StatusBadge.present(); break;
                  case 'absent': badge = StatusBadge.absent(); break;
                  case 'late': badge = StatusBadge.late(); break;
                  default: badge = StatusBadge.excused();
                }
                return DataRow(cells: [
                  DataCell(Text(d['date'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, color: DS.neutral700))),
                  DataCell(badge),
                  DataCell(Text(d['checkInTime'] ?? '-', style: const TextStyle(fontSize: 13, color: DS.neutral600))),
                  DataCell(Text(d['checkOutTime'] ?? '-', style: const TextStyle(fontSize: 13, color: DS.neutral600))),
                ]);
              }).toList(),
            );
          },
        ),
      ]),
    );
  }
}