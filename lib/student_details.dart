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
        builder: (context, snap) {
          if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: CircularProgressIndicator());

          final t = snap.data!.docs.first.data() as Map<String, dynamic>;
          final name = t['name'] ?? studentName;
          final email = t['email'] ?? '';
          final phone = t['phone'] ?? '';
          final completed = (t['completedHours'] ?? 0).toDouble();
          final remaining = (t['remainingHours'] ?? 280).toDouble();
          final total = completed + remaining;
          final hoursPct = total > 0 ? (completed / total * 100).round() : 0;
          final ini = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
          final enrollDate = t['enrollDate'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Back
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back'),
                style: TextButton.styleFrom(foregroundColor: DS.neutral500),
              ),
              const SizedBox(height: 12),

              // Header
              Container(
                width: double.infinity, padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [DS.primary700, DS.primary500, DS.accentTeal],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: DS.primary700.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: Stack(children: [
                  Positioned(top: -40, right: -40, child: Container(width: 160, height: 160,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)))),
                  Positioned(bottom: -30, left: -30, child: Container(width: 120, height: 120,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.03)))),
                  Row(children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Center(child: Text(ini, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700))),
                    ),
                    const SizedBox(width: 20),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.email_outlined, size: 14, color: Colors.white.withOpacity(0.6)),
                        const SizedBox(width: 6),
                        Text(email, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7))),
                        const SizedBox(width: 16),
                        Icon(Icons.phone_outlined, size: 14, color: Colors.white.withOpacity(0.6)),
                        const SizedBox(width: 6),
                        Text(phone, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7))),
                      ]),
                      if (enrollDate.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Enrolled: $enrollDate', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
                      ],
                    ])),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),

              // Stats
              _Stats(studentId: studentId, completed: completed, remaining: remaining, hoursPct: hoursPct),
              const SizedBox(height: 24),

              // Progress
              _progressCard(completed, total, hoursPct),
              const SizedBox(height: 24),

              // Attendance History
              _AttHistory(studentId: studentId),
            ]),
          );
        },
      ),
    );
  }

  Widget _progressCard(double completed, double total, int pct) => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: DS.neutral200), boxShadow: DS.shadowSM),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Training Progress', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: DS.neutral800)),
        Text('${completed.toStringAsFixed(1)}h / ${total.toStringAsFixed(0)}h',
          style: const TextStyle(fontSize: 13, color: DS.neutral500, fontWeight: FontWeight.w500)),
      ]),
      const SizedBox(height: 14),
      ClipRRect(borderRadius: BorderRadius.circular(6),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct / 100),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => LinearProgressIndicator(
            value: v, minHeight: 12, backgroundColor: DS.neutral100,
            valueColor: const AlwaysStoppedAnimation(DS.accentTeal)),
        )),
    ]),
  );
}

class _Stats extends StatelessWidget {
  final String studentId;
  final double completed, remaining;
  final int hoursPct;
  const _Stats({required this.studentId, required this.completed, required this.remaining, required this.hoursPct});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('AttendanceRecords').where('studentId', isEqualTo: studentId).snapshots(),
      builder: (ctx, attSnap) {
        int present = 0, totalDays = 0;
        if (attSnap.hasData) {
          totalDays = attSnap.data!.docs.length;
          present = attSnap.data!.docs.where((d) => d['status'] == 'present').length;
        }
        final attPct = totalDays > 0 ? (present / totalDays * 100).round() : 0;

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('Excuses').where('studentId', isEqualTo: studentId).get(),
          builder: (ctx, excSnap) {
            final totalExc = excSnap.data?.docs.length ?? 0;
            final approved = excSnap.data?.docs.where((d) => d['status'] == 'approved').length ?? 0;

            return Row(children: [
              _s('Completed', '${completed.toStringAsFixed(1)}h', 'of ${(completed + remaining).toStringAsFixed(0)}h', DS.primary500, Icons.timer_rounded),
              _s('Remaining', '${remaining.toStringAsFixed(1)}h', '$hoursPct% done', DS.accentTeal, Icons.hourglass_bottom_rounded),
              _s('Attendance', '$attPct%', '$present/$totalDays days', DS.statusPresent, Icons.calendar_today_rounded),
              _s('Excuses', '$totalExc', '$approved approved', DS.accentViolet, Icons.description_rounded),
            ]);
          },
        );
      },
    );
  }

  Widget _s(String label, String val, String sub, Color color, IconData icon) => Expanded(child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DS.neutral200), boxShadow: DS.shadowSM),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: color.withOpacity(0.6)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: DS.neutral500, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 10),
        Text(val, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 11, color: DS.neutral400)),
      ]),
    ),
  ));
}

class _AttHistory extends StatelessWidget {
  final String studentId;
  const _AttHistory({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DS.neutral200), boxShadow: DS.shadowSM),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Attendance History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: DS.neutral800)),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('AttendanceRecords')
            .where('studentId', isEqualTo: studentId).orderBy('date', descending: true).snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty)
              return const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No records yet', style: TextStyle(color: DS.neutral400))));

            return Column(children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: DS.neutral50, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Expanded(flex: 3, child: Text('DATE', style: _hStyle)),
                  Expanded(flex: 2, child: Text('STATUS', style: _hStyle)),
                  Expanded(flex: 2, child: Text('CHECK IN', style: _hStyle)),
                  Expanded(flex: 2, child: Text('CHECK OUT', style: _hStyle)),
                ]),
              ),
              ...snap.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final status = d['status'] ?? 'absent';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: DS.neutral100))),
                  child: Row(children: [
                    Expanded(flex: 3, child: Text(d['date'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: DS.neutral700))),
                    Expanded(flex: 2, child: _badge(status)),
                    Expanded(flex: 2, child: Text(d['checkInTime'] ?? '-', style: const TextStyle(fontSize: 13, color: DS.neutral600))),
                    Expanded(flex: 2, child: Text(d['checkOutTime'] ?? '-', style: const TextStyle(fontSize: 13, color: DS.neutral600))),
                  ]),
                );
              }),
            ]);
          },
        ),
      ]),
    );
  }

  static final _hStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DS.neutral400, letterSpacing: 0.8);

  Widget _badge(String s) {
    switch (s) {
      case 'present': return StatusBadge.present();
      case 'absent': return StatusBadge.absent();
      case 'late': return StatusBadge.late();
      default: return StatusBadge.excused();
    }
  }
}