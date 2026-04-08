import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  String selectedFilter = 'All';

  String _getStatus(Map<String, dynamic> data) {
    if (data['status'] != null && data['status'] != '') {
      String status = data['status'].toString().trim();
      // 'completed' = check-out done = Present
      if (status.toLowerCase() == 'completed') return 'Present';
      // Capitalize first letter to match badge keys (Present, Absent, Late, Excused)
      if (status.isNotEmpty) {
        status = status[0].toUpperCase() + status.substring(1).toLowerCase();
      }
      return status;
    }
    return 'Present';
  }

  String _formatDate(Timestamp ts) {
    final d = ts.toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String _formatDayName(Timestamp ts) {
    final d = ts.toDate();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ThemedScaffold(
      appBar: const CustomHeader(title: 'Attendance History', showBack: true),
      body: Column(
        children: [
          const SizedBox(height: DS.spaceMD),

          // ── Filter Chips ──
          _buildFilterSection(isDark),

          const SizedBox(height: DS.spaceSM),

          // ── Records List ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .where('uid', isEqualTo: uid)
                  .orderBy('checkIn', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: DS.primary500),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                var records = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'date': _formatDate(data['checkIn'] as Timestamp),
                    'time': _formatTime(data['checkIn'] as Timestamp?),
                    'day': _formatDayName(data['checkIn'] as Timestamp),
                    'status': _getStatus(data),
                    'checkOut': data['checkOut'] != null
                        ? _formatTime(data['checkOut'] as Timestamp?)
                        : null,
                  };
                }).toList();

                // Count stats
                final totalRecords = records.length;
                final presentCount =
                    records.where((r) => r['status'] == 'Present').length;
                final absentCount =
                    records.where((r) => r['status'] == 'Absent').length;

                if (selectedFilter != 'All') {
                  records = records
                      .where((r) => r['status'] == selectedFilter)
                      .toList();
                }

                if (records.isEmpty) {
                  return _buildEmptyState(isDark, isFiltered: true);
                }

                return Column(
                  children: [
                    // ── Summary Bar ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: DS.spaceMD),
                      child: _buildSummaryBar(
                        totalRecords,
                        presentCount,
                        absentCount,
                        isDark,
                      ),
                    ),
                    const SizedBox(height: DS.spaceMD),

                    // ── List ──
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          left: DS.spaceMD,
                          right: DS.spaceMD,
                          bottom: DS.spaceXL,
                        ),
                        itemCount: records.length,
                        itemBuilder: (context, index) =>
                            _buildAttendanceCard(records[index], isDark),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary Bar ──
  Widget _buildSummaryBar(
      int total, int present, int absent, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(DS.spaceMD),
      decoration: BoxDecoration(
        color: isDark ? DS.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(DS.radiusXL),
        border: Border.all(
            color: isDark ? DS.neutral700 : DS.neutral200),
        boxShadow: isDark ? null : DS.shadowSM,
      ),
      child: Row(
        children: [
          _buildStatItem(
            '$total',
            'Total',
            DS.primary500,
            isDark,
          ),
          _buildDivider(isDark),
          _buildStatItem(
            '$present',
            'Present',
            DS.success,
            isDark,
          ),
          _buildDivider(isDark),
          _buildStatItem(
            '$absent',
            'Absent',
            DS.error,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String value, String label, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: DS.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 36,
      color: isDark ? DS.neutral700 : DS.neutral200,
    );
  }

  // ── Filter Section ──
  Widget _buildFilterSection(bool isDark) {
    final filters = ['All', 'Present', 'Absent', 'Late', 'Excused'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: DS.spaceMD),
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;

          Color chipColor;
          switch (filter) {
            case 'Present':
              chipColor = DS.success;
              break;
            case 'Absent':
              chipColor = DS.error;
              break;
            case 'Late':
              chipColor = DS.warning;
              break;
            case 'Excused':
              chipColor = DS.accentViolet;
              break;
            default:
              chipColor = DS.primary500;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => selectedFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? chipColor
                      : (isDark
                          ? DS.darkCard
                          : chipColor.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(DS.radiusFull),
                  border: Border.all(
                    color: isSelected
                        ? chipColor
                        : chipColor.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : chipColor,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Attendance Card ──
  Widget _buildAttendanceCard(
      Map<String, dynamic> item, bool isDark) {
    final status = item['status'] as String;

    Color statusColor;
    Color statusBg;
    IconData statusIcon;

    switch (status) {
      case 'Present':
        statusColor = DS.statusPresent;
        statusBg = DS.statusPresentBg;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'Absent':
        statusColor = DS.statusAbsent;
        statusBg = DS.statusAbsentBg;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'Late':
        statusColor = DS.statusLate;
        statusBg = DS.statusLateBg;
        statusIcon = Icons.watch_later_rounded;
        break;
      case 'Excused':
        statusColor = DS.statusExcused;
        statusBg = DS.statusExcusedBg;
        statusIcon = Icons.event_note_rounded;
        break;
      default:
        statusColor = DS.neutral400;
        statusBg = DS.neutral100;
        statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: DS.spaceSM),
      padding: const EdgeInsets.all(DS.spaceMD),
      decoration: BoxDecoration(
        color: isDark ? DS.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(DS.radiusXL),
        border: Border.all(
          color: isDark ? DS.neutral700 : DS.neutral200,
        ),
        boxShadow: isDark ? null : DS.shadowSM,
      ),
      child: Row(
        children: [
          // ── Date badge ──
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? DS.primary500.withOpacity(0.12)
                  : DS.primary50,
              borderRadius: BorderRadius.circular(DS.radiusLG),
            ),
            child: Column(
              children: [
                Text(
                  item['day'] ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: DS.primary500,
                  ),
                ),
                Text(
                  // Extract day number from date string
                  _extractDay(item['date'] ?? ''),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : DS.primary900,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: DS.spaceMD),

          // ── Info ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['date'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : DS.neutral800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.login_rounded,
                        size: 12, color: DS.neutral400),
                    const SizedBox(width: 4),
                    Text(
                      item['time'] ?? '-',
                      style: const TextStyle(
                          fontSize: 12, color: DS.neutral500),
                    ),
                    if (item['checkOut'] != null) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.logout_rounded,
                          size: 12, color: DS.neutral400),
                      const SizedBox(width: 4),
                      Text(
                        item['checkOut'],
                        style: const TextStyle(
                            fontSize: 12, color: DS.neutral500),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Status badge ──
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? statusColor.withOpacity(0.15) : statusBg,
              borderRadius: BorderRadius.circular(DS.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _extractDay(String dateStr) {
    // "Jan 5, 2025" → "5"
    final parts = dateStr.split(' ');
    if (parts.length >= 2) {
      return parts[1].replaceAll(',', '');
    }
    return '';
  }

  // ── Empty State ──
  Widget _buildEmptyState(bool isDark, {bool isFiltered = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DS.space2XL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? DS.neutral700.withOpacity(0.5)
                    : DS.neutral100,
                borderRadius: BorderRadius.circular(DS.radiusXL),
              ),
              child: Icon(
                isFiltered
                    ? Icons.filter_list_off_rounded
                    : Icons.calendar_today_outlined,
                size: 36,
                color: DS.neutral400,
              ),
            ),
            const SizedBox(height: DS.spaceLG),
            Text(
              isFiltered ? 'No Records Found' : 'No History Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? DS.neutral300 : DS.neutral700,
              ),
            ),
            const SizedBox(height: DS.spaceSM),
            Text(
              isFiltered
                  ? 'Try changing the filter to see more records.'
                  : 'Your attendance history will appear here\nonce you start checking in.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: DS.neutral500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}