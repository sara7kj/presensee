import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme.dart';
import 'student_details.dart';

class SupervisorDashboard extends StatelessWidget {
  final String supervisorId;
  final String supervisorName;  // ← ديناميكي
  final VoidCallback? onViewStudents;
  final VoidCallback? onViewExcuses;

  const SupervisorDashboard({
    super.key,
    required this.supervisorId,
    this.supervisorName = 'Supervisor',
    this.onViewStudents,
    this.onViewExcuses,
  });

  String get _todayStr {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  // استخراج الاسم الأول فقط للترحيب
  String get _firstName {
    final parts = supervisorName.split(' ');
    // إذا يبدأ بـ Dr. أو د. ناخذ الاسم اللي بعده
    if (parts.length > 1 && (parts[0].toLowerCase().startsWith('dr') || parts[0].startsWith('د'))) {
      return '${parts[0]} ${parts[1]}';
    }
    return parts.first;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Trainees')
          .where('supervisorId', isEqualTo: supervisorId)
          .snapshots(),
      builder: (context, traineesSnap) {
        if (traineesSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final trainees = traineesSnap.data?.docs ?? [];
        final total = trainees.length;
        final studentIds = trainees
            .map((d) {
              final data = d.data() as Map<String, dynamic>?;
              return data?['studentId'] as String?;
            })
            .where((id) => id != null)
            .cast<String>()
            .toList();

        if (studentIds.isEmpty) {
          return _buildContent(context, trainees, total, 0, 0, 0, 0);
        }

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('AttendanceRecords')
              .where('studentId', whereIn: studentIds)
              .where('date', isEqualTo: _todayStr)
              .get(),
          builder: (context, attSnap) {
            int present = 0, absent = 0, excused = 0;

            if (attSnap.connectionState == ConnectionState.done && attSnap.hasData) {
              for (var d in attSnap.data!.docs) {
                final data = d.data() as Map<String, dynamic>?;
                if (data == null) continue;
                final s = data['status'] as String? ?? '';
                if (s == 'present') present++;
                else if (s == 'absent') absent++;
                else excused++;
              }
              final accounted = present + absent + excused;
              if (accounted < total) absent += total - accounted;
            }

            final perf = total > 0 ? (present / total * 100).round() : 0;
            return _buildContent(context, trainees, total, present, absent, excused, perf);
          },
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, List<QueryDocumentSnapshot> trainees,
      int total, int present, int absent, int excused, int perf) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header — ديناميكي ──
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: DS.neutral900)),
            const SizedBox(height: 4),
            Text(
              'Welcome back, $_firstName',  // ← ديناميكي
              style: TextStyle(fontSize: 14, color: DS.neutral500),
            ),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: DS.primary50, borderRadius: BorderRadius.circular(DS.radiusFull)),
            child: Row(children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: DS.primary500),
              const SizedBox(width: 6),
              Text(_todayStr, style: const TextStyle(fontSize: 13, color: DS.primary500, fontWeight: FontWeight.w500)),
            ]),
          ),
        ]),
        const SizedBox(height: 28),

        // ── Stat Cards ──
        Row(children: [
          _statCard('Total\nStudents', '$total', Icons.people_rounded, DS.primary500, DS.primary50),
          _statCard('Present\nToday', '$present', Icons.check_circle_rounded, DS.statusPresent, DS.statusPresentBg),
          _statCard('Absent\nToday', '$absent', Icons.cancel_rounded, DS.statusAbsent, DS.statusAbsentBg),
          _statCard('Excused', '$excused', Icons.event_note_rounded, DS.accentViolet, DS.statusExcusedBg),
        ]),
        const SizedBox(height: 24),

        // ── Performance + Students ──
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _card(child: Column(children: [
            _cardTitle("Today's Performance"),
            const SizedBox(height: 20),
            SizedBox(width: 150, height: 150, child: Stack(fit: StackFit.expand, children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: perf / 100),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => CircularProgressIndicator(
                  value: v, strokeWidth: 14, backgroundColor: DS.neutral100,
                  valueColor: AlwaysStoppedAnimation(perf > 60 ? DS.statusPresent : perf > 30 ? DS.warning : DS.statusAbsent),
                  strokeCap: StrokeCap.round),
              ),
              Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$perf%', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: DS.neutral900)),
                const Text('attendance', style: TextStyle(fontSize: 11, color: DS.neutral500)),
              ])),
            ])),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _dot(DS.statusPresent, 'Present'), const SizedBox(width: 16),
              _dot(DS.statusAbsent, 'Absent'), const SizedBox(width: 16),
              _dot(DS.accentViolet, 'Excused'),
            ]),
          ]))),
          const SizedBox(width: 18),

          Expanded(child: _card(child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _cardTitle('My Students'),
              if (onViewStudents != null)
                TextButton(onPressed: onViewStudents, child: const Text('View All →', style: TextStyle(fontSize: 13))),
            ]),
            const SizedBox(height: 8),
            if (trainees.isEmpty)
              Padding(padding: const EdgeInsets.all(20), child: Text('No students assigned yet', style: TextStyle(color: DS.neutral400)))
            else
              ...trainees.take(4).map((doc) {
                final d = doc.data() as Map<String, dynamic>? ?? {};
                final name = d['name']?.toString() ?? 'Unknown';
                final email = d['email']?.toString() ?? '';
                final hrs = (d['completedHours'] ?? 0).toDouble();
                final rem = (d['remainingHours'] ?? 280).toDouble();
                final pct = (hrs + rem) > 0 ? (hrs / (hrs + rem) * 100).round() : 0;
                final ini = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
                return InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => StudentDetailsPage(studentId: d['studentId']?.toString() ?? doc.id, studentName: name))),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
                    CircleAvatar(radius: 18, backgroundColor: DS.primary100,
                      child: Text(ini, style: const TextStyle(color: DS.primary600, fontSize: 12, fontWeight: FontWeight.w700))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: DS.neutral800)),
                      Text(email, style: const TextStyle(fontSize: 12, color: DS.neutral400)),
                    ])),
                    SizedBox(width: 60, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('$pct%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: pct > 60 ? DS.statusPresent : DS.warning)),
                      const SizedBox(height: 4),
                      ClipRRect(borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(value: pct / 100, minHeight: 4, backgroundColor: DS.neutral100,
                          valueColor: AlwaysStoppedAnimation(pct > 60 ? DS.statusPresent : DS.warning))),
                    ])),
                  ])),
                );
              }),
          ]))),
        ]),
        const SizedBox(height: 18),

        // ── Pending Excuses ──
        _card(child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _cardTitle('Pending Excuses'),
            if (onViewExcuses != null)
              TextButton(onPressed: onViewExcuses, child: const Text('View All →', style: TextStyle(fontSize: 13))),
          ]),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Excuses')
              .where('supervisorId', isEqualTo: supervisorId)
              .where('status', isEqualTo: 'pending').snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return Padding(padding: const EdgeInsets.all(24), child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check_circle_outline, color: DS.statusPresent.withOpacity(0.5), size: 20),
                    const SizedBox(width: 8),
                    Text('All caught up!', style: TextStyle(color: DS.neutral400, fontSize: 14)),
                  ]));
              }
              return Column(children: snap.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>? ?? {};
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: DS.neutral100))),
                  child: Row(children: [
                    Container(width: 4, height: 40, decoration: BoxDecoration(color: DS.warning, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['studentName']?.toString() ?? 'Student', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: DS.neutral800)),
                      Text('${d['type'] ?? 'Excuse'} • ${d['startDate'] ?? ''}', style: const TextStyle(fontSize: 12, color: DS.neutral500)),
                    ])),
                    StatusBadge(label: 'Pending', color: DS.statusLate, backgroundColor: DS.statusLateBg),
                  ]),
                );
              }).toList());
            },
          ),
        ])),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, Color bg) {
    return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
      child: _HoverCard(child: Padding(padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: DS.neutral900)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: DS.neutral500, height: 1.3)),
        ])))));
  }

  Widget _card({required Widget child}) => Container(padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(DS.radiusLG),
      border: Border.all(color: DS.neutral200), boxShadow: DS.shadowSM), child: child);

  Widget _cardTitle(String t) => Align(alignment: Alignment.centerLeft,
    child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: DS.neutral800)));

  Widget _dot(Color c, String l) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4))),
    const SizedBox(width: 5),
    Text(l, style: const TextStyle(fontSize: 11, color: DS.neutral500)),
  ]);
}

class _HoverCard extends StatefulWidget {
  final Widget child;
  const _HoverCard({required this.child});
  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _h ? -4 : 0, 0),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(DS.radiusLG),
          border: Border.all(color: _h ? DS.primary200 : DS.neutral200),
          boxShadow: _h ? DS.shadowMD : DS.shadowSM),
        child: widget.child,
      ),
    );
  }
}