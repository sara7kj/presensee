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

  // تحديد الـ Status من وقت الدخول
  String _getStatus(Map<String, dynamic> data) {
    if (data['checkOut'] == null) return 'Present';
    return data['status'] ?? 'Present';
  }

  // تنسيق التاريخ
  String _formatDate(Timestamp ts) {
    final d = ts.toDate();
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  // تنسيق الوقت
  String _formatTime(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return ThemedScaffold(
      appBar: const CustomHeader(
        title: 'Attendance History',
        showBack: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: DS.spaceLG),
          _buildFilterSection(),
          const SizedBox(height: DS.spaceMD),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // جلب بيانات الطالب من Firebase مرتبة بالتاريخ
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .where('uid', isEqualTo: uid)
                  .orderBy('checkIn', descending: true)
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const EmptyState(
                    icon: Icons.calendar_today_outlined,
                    title: 'No Records Found',
                    subtitle: 'Your attendance history will appear here.',
                  );
                }

                // تحويل البيانات
                var records = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'date': _formatDate(data['checkIn'] as Timestamp),
                    'time': _formatTime(data['checkIn'] as Timestamp?),
                    'status': _getStatus(data),
                  };
                }).toList();

                // تطبيق الفلتر
                if (selectedFilter != 'All') {
                  records = records
                      .where((r) => r['status'] == selectedFilter)
                      .toList();
                }

                if (records.isEmpty) {
                  return const EmptyState(
                    icon: Icons.filter_list_off_rounded,
                    title: 'No Records Found',
                    subtitle: 'Try changing the filter.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: DS.spaceXL),
                  itemCount: records.length,
                  itemBuilder: (context, index) =>
                      _buildAttendanceCard(records[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final filters = ['All', 'Present', 'Absent', 'Late', 'Excused'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: DS.spaceMD),
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => setState(() => selectedFilter = filter),
              selectedColor: DS.primary500,
              backgroundColor:
                  Theme.of(context).brightness == Brightness.dark
                      ? DS.darkSurface
                      : Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : DS.neutral500,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: DS.spaceMD, vertical: DS.spaceSM / 2),
      child: Padding(
        padding: const EdgeInsets.all(DS.spaceMD),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['date'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 13, color: DS.neutral400),
                      const SizedBox(width: 4),
                      Text(
                        item['time'],
                        style: const TextStyle(
                            fontSize: 12, color: DS.neutral500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _getStatusBadge(item['status']!),
          ],
        ),
      ),
    );
  }

  Widget _getStatusBadge(String status) {
    switch (status) {
      case 'Present': return StatusBadge.present();
      case 'Absent':  return StatusBadge.absent();
      case 'Late':    return StatusBadge.late();
      case 'Excused': return StatusBadge.excused();
      default:        return const SizedBox.shrink();
    }
  }
}