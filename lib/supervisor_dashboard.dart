import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme.dart';
import 'student_details.dart';

// ══════════════════════════════════════════════════════════════
//  Changed: StatelessWidget → StatefulWidget
//  so we can track which stat card is selected (_selectedFilter)
// ══════════════════════════════════════════════════════════════

class SupervisorDashboard extends StatefulWidget {
  final String supervisorId;
  final String supervisorName;
  final VoidCallback? onViewStudents;
  final VoidCallback? onViewExcuses;

  const SupervisorDashboard({
    super.key,
    required this.supervisorId,
    this.supervisorName = 'Supervisor',
    this.onViewStudents,
    this.onViewExcuses,
  });

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  // ── NEW: tracks which card is tapped ──
  // null = no filter panel shown, 'all' / 'present' / 'absent' / 'excused'
  String? _selectedFilter;

  String get _todayStr {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  // ══════════════════════════════════════════════════════════════
  // ✅ NEW: تحديد لو اليوم يوم تدريب أو إجازة
  // الجمعة + السبت = إجازة، باقي الأيام = تدريب
  // ══════════════════════════════════════════════════════════════
  bool get _isWorkingDay {
    final today = DateTime.now();
    return today.weekday != DateTime.friday &&
        today.weekday != DateTime.saturday;
  }

  String get _firstName {
    final parts = widget.supervisorName.split(' ');
    if (parts.length > 1 &&
        (parts[0].toLowerCase().startsWith('dr') ||
            parts[0].startsWith('د'))) {
      return '${parts[0]} ${parts[1]}';
    }
    return parts.first;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Trainees')
          .where('supervisorId', isEqualTo: widget.supervisorId)
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
          // ✅ يوم إجازة بدون طلاب = 100%، يوم عمل بدون طلاب = 0%
          final emptyPerf = _isWorkingDay ? 0 : 100;
          return _buildContent(
              context, trainees, total, 0, 0, 0, emptyPerf, {});
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('AttendanceRecords')
              .where('studentId', whereIn: studentIds)
              .where('date', isEqualTo: _todayStr)
              .snapshots(),
          builder: (context, attSnap) {
            int present = 0, absent = 0, excused = 0;

            // ── NEW: build a map of studentId → status ──
            final Map<String, String> statusMap = {};

            if (attSnap.hasData) {
              for (var d in attSnap.data!.docs) {
                final data = d.data() as Map<String, dynamic>?;
                if (data == null) continue;
                final s = data['status'] as String? ?? '';
                final sid = data['studentId'] as String? ?? '';
                if (s == 'present') {
                  present++;
                  if (sid.isNotEmpty) statusMap[sid] = 'present';
                } else if (s == 'absent') {
                  absent++;
                  if (sid.isNotEmpty) statusMap[sid] = 'absent';
                } else {
                  excused++;
                  if (sid.isNotEmpty) statusMap[sid] = 'excused';
                }
              }

              // ═══════════════════════════════════════════════════════
              // ✅ يوم تدريب: من ما سجل = غايب
              // ✅ يوم إجازة: ما نحسب أحد غايب
              // ═══════════════════════════════════════════════════════
              if (_isWorkingDay) {
                final accounted = present + absent + excused;
                if (accounted < total) absent += total - accounted;
              }
              // في يوم الإجازة، اللي ما سجلوا يبقون بدون status (مو غايبين)
            }

            // ═══════════════════════════════════════════════════════
            // ✅ تحديد status للطلاب اللي ما عندهم سجل
            // يوم تدريب → absent
            // يوم إجازة → excused (لأن اليوم إجازة، مو غياب)
            // ═══════════════════════════════════════════════════════
            for (final sid in studentIds) {
              if (!statusMap.containsKey(sid)) {
                statusMap[sid] = _isWorkingDay ? 'absent' : 'excused';
              }
            }

            // ═══════════════════════════════════════════════════════
            // ✅ معادلة النسبة الجديدة:
            // - يوم تدريب: (present + excused) / total × 100
            //   (المعذور يحسب حضور لأن عذره مقبول)
            // - يوم إجازة: 100% (ما فيه غياب)
            // ═══════════════════════════════════════════════════════
            int perf;
            if (!_isWorkingDay) {
              perf = 100;
            } else if (total > 0) {
              perf = ((present + excused) / total * 100).round();
            } else {
              perf = 0;
            }

            return _buildContent(context, trainees, total, present, absent,
                excused, perf, statusMap);
          },
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<QueryDocumentSnapshot> trainees,
    int total,
    int present,
    int absent,
    int excused,
    int perf,
    Map<String, String> statusMap, // ← NEW parameter
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dashboard',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: DS.neutral900)),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome back, $_firstName',
                    style: TextStyle(fontSize: 14, color: DS.neutral500),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: DS.primary50,
                    borderRadius: BorderRadius.circular(DS.radiusFull)),
                child: Row(children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 14, color: DS.primary500),
                  const SizedBox(width: 6),
                  Text(_todayStr,
                      style: const TextStyle(
                          fontSize: 13,
                          color: DS.primary500,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ══════════════════════════════════════════════
          //  CHANGED: Stat Cards — now clickable
          // ══════════════════════════════════════════════
          Row(children: [
            _statCard('Total\nStudents', '$total', Icons.people_rounded,
                DS.primary500, DS.primary50, 'all'),
            _statCard('Present\nToday', '$present',
                Icons.check_circle_rounded, DS.statusPresent, DS.statusPresentBg, 'present'),
            _statCard('Absent\nToday', '$absent', Icons.cancel_rounded,
                DS.statusAbsent, DS.statusAbsentBg, 'absent'),
            _statCard('Excused', '$excused', Icons.event_note_rounded,
                DS.accentViolet, DS.statusExcusedBg, 'excused'),
          ]),
          const SizedBox(height: 24),

          // ══════════════════════════════════════════════
          //  NEW: Filtered Students Panel
          //  Shows only when a stat card is tapped
          // ══════════════════════════════════════════════
          if (_selectedFilter != null)
            _buildFilteredStudentsPanel(trainees, statusMap),

          if (_selectedFilter != null) const SizedBox(height: 24),

          // ── Performance + Students ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Performance Card
              Expanded(
                child: _card(
                  child: Column(children: [
                    _cardTitle("Today's Performance"),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Stack(fit: StackFit.expand, children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: perf / 100),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => CircularProgressIndicator(
                            value: v,
                            strokeWidth: 14,
                            backgroundColor: DS.neutral100,
                            valueColor: AlwaysStoppedAnimation(
                              perf > 60
                                  ? DS.statusPresent
                                  : perf > 30
                                      ? DS.warning
                                      : DS.statusAbsent,
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$perf%',
                                  style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      color: DS.neutral900)),
                              Text(
                                  _isWorkingDay
                                      ? 'attendance'
                                      : 'holiday',
                                  style: const TextStyle(
                                      fontSize: 11, color: DS.neutral500)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _dot(DS.statusPresent, 'Present'),
                        const SizedBox(width: 16),
                        _dot(DS.statusAbsent, 'Absent'),
                        const SizedBox(width: 16),
                        _dot(DS.accentViolet, 'Excused'),
                      ],
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 18),

              // Students Card
              Expanded(
                child: _card(
                  child: Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _cardTitle('My Students'),
                        if (widget.onViewStudents != null)
                          TextButton(
                            onPressed: widget.onViewStudents,
                            child: const Text('View All →',
                                style: TextStyle(fontSize: 13)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (trainees.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('No students assigned yet',
                            style: TextStyle(color: DS.neutral400)),
                      )
                    else
                      ...trainees.take(4).map((doc) {
                        final d = doc.data() as Map<String, dynamic>? ?? {};
                        final name = d['name']?.toString() ?? 'Unknown';
                        final email = d['email']?.toString() ?? '';
                        final sid = d['studentId']?.toString() ?? '';
                        final status = statusMap[sid] ?? 'absent';
                        final ini = name
                            .split(' ')
                            .map((w) => w.isNotEmpty ? w[0] : '')
                            .take(2)
                            .join()
                            .toUpperCase();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentDetailsPage(
                                    studentId: sid, studentName: name),
                              ),
                            ),
                            child: Row(children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: DS.primary100,
                                child: Text(ini,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: DS.primary700)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: DS.neutral800)),
                                    Text(email,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: DS.neutral500)),
                                  ],
                                ),
                              ),
                              _statusBadge(status),
                            ]),
                          ),
                        );
                      }),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Excuses Card ──
          _card(
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _cardTitle('Recent Excuses'),
                  if (widget.onViewExcuses != null)
                    TextButton(
                      onPressed: widget.onViewExcuses,
                      child: const Text('View All →',
                          style: TextStyle(fontSize: 13)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Excuses')
                    .where('supervisorId', isEqualTo: widget.supervisorId)
                    .where('status', isEqualTo: 'pending')
                    .limit(3)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('No pending excuses',
                          style: TextStyle(color: DS.neutral400)),
                    );
                  }
                  return Column(
                    children: snap.data!.docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: DS.statusExcusedBg,
                            child: const Icon(Icons.description_rounded,
                                size: 16, color: DS.accentViolet),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['studentName']?.toString() ?? 'Student',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: DS.neutral800),
                                ),
                                Text(
                                  '${d['type'] ?? 'Excuse'} • ${d['startDate'] ?? ''}',
                                  style: const TextStyle(
                                      fontSize: 12, color: DS.neutral500),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(
                            label: 'Pending',
                            color: DS.statusLate,
                            backgroundColor: DS.statusLateBg,
                          ),
                        ]),
                      );
                    }).toList(),
                  );
                },
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  NEW: Filtered Students Panel
  // ══════════════════════════════════════════════════════════════

  Widget _buildFilteredStudentsPanel(
    List<QueryDocumentSnapshot> trainees,
    Map<String, String> statusMap,
  ) {
    // Determine title & color based on filter
    String title;
    Color color;
    switch (_selectedFilter) {
      case 'present':
        title = 'Present Students';
        color = DS.statusPresent;
        break;
      case 'absent':
        title = 'Absent Students';
        color = DS.statusAbsent;
        break;
      case 'excused':
        title = 'Excused Students';
        color = DS.accentViolet;
        break;
      default:
        title = 'All Students';
        color = DS.primary500;
    }

    // Filter trainees
    final filtered = trainees.where((doc) {
      if (_selectedFilter == 'all') return true;
      final d = doc.data() as Map<String, dynamic>? ?? {};
      final sid = d['studentId']?.toString() ?? '';
      final status = statusMap[sid] ?? 'absent';
      return status == _selectedFilter;
    }).toList();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DS.radiusLG),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: DS.shadowSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title & close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$title (${filtered.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: DS.neutral800,
                    ),
                  ),
                ]),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _selectedFilter = null),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: DS.neutral100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: DS.neutral500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: DS.neutral50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Expanded(
                    flex: 3,
                    child: Text('Student',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DS.neutral500))),
                const Expanded(
                    flex: 3,
                    child: Text('Email',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DS.neutral500))),
                const Expanded(
                    flex: 2,
                    child: Text('Status',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DS.neutral500))),
              ]),
            ),

            const SizedBox(height: 4),

            // Student rows
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No students found',
                    style: TextStyle(color: DS.neutral400, fontSize: 14),
                  ),
                ),
              )
            else
              ...filtered.map((doc) {
                final d = doc.data() as Map<String, dynamic>? ?? {};
                final name = d['name']?.toString() ?? 'Unknown';
                final email = d['email']?.toString() ?? '';
                final sid = d['studentId']?.toString() ?? '';
                final status = statusMap[sid] ?? 'absent';
                final ini = name
                    .split(' ')
                    .map((w) => w.isNotEmpty ? w[0] : '')
                    .take(2)
                    .join()
                    .toUpperCase();

                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentDetailsPage(
                          studentId: sid, studentName: name),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: DS.neutral100),
                      ),
                    ),
                    child: Row(children: [
                      // Name with avatar
                      Expanded(
                        flex: 3,
                        child: Row(children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: DS.primary100,
                            child: Text(ini,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: DS.primary700)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(name,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: DS.neutral800),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                      ),
                      // Email
                      Expanded(
                        flex: 3,
                        child: Text(email,
                            style: const TextStyle(
                                fontSize: 13, color: DS.neutral500),
                            overflow: TextOverflow.ellipsis),
                      ),
                      // Status badge
                      Expanded(flex: 2, child: _statusBadge(status)),
                    ]),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  CHANGED: _statCard now accepts filterKey + has onTap
  // ══════════════════════════════════════════════════════════════

  Widget _statCard(String label, String value, IconData icon, Color color,
      Color bg, String filterKey) {
    final isSelected = _selectedFilter == filterKey;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: GestureDetector(
          onTap: () {
            setState(() {
              // Toggle: tap again to close
              if (_selectedFilter == filterKey) {
                _selectedFilter = null;
              } else {
                _selectedFilter = filterKey;
              }
            });
          },
          child: _HoverCard(
            isSelected: isSelected,
            selectedColor: color,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 16),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: DS.neutral900)),
                  const SizedBox(height: 4),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12,
                          color: DS.neutral500,
                          height: 1.3)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helper: status badge widget ──
  Widget _statusBadge(String status) {
    switch (status) {
      case 'present':
        return StatusBadge.present();
      case 'absent':
        return StatusBadge.absent();
      case 'excused':
        return StatusBadge.excused();
      default:
        return StatusBadge.absent();
    }
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DS.radiusLG),
          border: Border.all(color: DS.neutral200),
          boxShadow: DS.shadowSM,
        ),
        child: child,
      );

  Widget _cardTitle(String t) => Align(
        alignment: Alignment.centerLeft,
        child: Text(t,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: DS.neutral800)),
      );

  Widget _dot(Color c, String l) => Row(children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 5),
        Text(l, style: const TextStyle(fontSize: 11, color: DS.neutral500)),
      ]);
}

// ══════════════════════════════════════════════════════════════
//  CHANGED: _HoverCard now supports isSelected highlight
// ══════════════════════════════════════════════════════════════

class _HoverCard extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final Color? selectedColor;
  const _HoverCard({
    required this.child,
    this.isSelected = false,
    this.selectedColor,
  });
  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? (widget.selectedColor ?? DS.primary500)
        : (_h ? DS.primary200 : DS.neutral200);

    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform:
            Matrix4.translationValues(0, (_h || widget.isSelected) ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? (widget.selectedColor?.withOpacity(0.04) ?? Colors.white)
              : Colors.white,
          borderRadius: BorderRadius.circular(DS.radiusLG),
          border: Border.all(
            color: borderColor,
            width: widget.isSelected ? 2 : 1,
          ),
          boxShadow: (_h || widget.isSelected) ? DS.shadowMD : DS.shadowSM,
        ),
        child: widget.child,
      ),
    );
  }
}