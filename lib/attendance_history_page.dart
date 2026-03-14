import 'package:flutter/material.dart';
import 'theme.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  // الفلتر المختار حالياً
  String selectedFilter = 'All';

  // بيانات تجريبية (Mock Data) لمحاكاة الحضور
  final List<Map<String, dynamic>> attendanceData = [
    {
      'date': 'Oct 24, 2023',
      'day': 'Thursday',
      'status': 'Present',
      'time': '08:02 AM'
    },
    {
      'date': 'Oct 23, 2023',
      'day': 'Wednesday',
      'status': 'Absent',
      'time': '-'
    },
    {
      'date': 'Oct 22, 2023',
      'day': 'Tuesday',
      'status': 'Present',
      'time': '07:55 AM'
    },
    {
      'date': 'Oct 21, 2023',
      'day': 'Monday',
      'status': 'Late',
      'time': '08:45 AM'
    },
    {'date': 'Oct 20, 2023', 'day': 'Sunday', 'status': 'Excused', 'time': '-'},
  ];

  @override
  Widget build(BuildContext context) {
    // تصفية البيانات بناءً على الفلتر المختار
    final filteredList = selectedFilter == 'All'
        ? attendanceData
        : attendanceData
            .where((item) => item['status'] == selectedFilter)
            .toList();

    return ThemedScaffold(
      appBar: const CustomHeader(
        title: 'Attendance History',
        showBack: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: DS.spaceLG),
          // ── قسم الفلاتر (Horizontal Filter List) ──
          _buildFilterSection(),

          const SizedBox(height: DS.spaceMD),

          // ── قائمة السجلات ──
          Expanded(
            child: filteredList.isEmpty
                ? const EmptyState(
                    icon: Icons.calendar_today_outlined,
                    title: 'No Records Found',
                    subtitle: 'Try changing the filter or check back later.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: DS.spaceXL),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return _buildAttendanceCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // بناء أزرار الفلترة
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
              onSelected: (val) => setState(() => selectedFilter = filter),
              selectedColor: DS.primary500,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? DS.darkSurface
                  : Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : DS.neutral500,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // بناء بطاقة الحضور لكل يوم
  Widget _buildAttendanceCard(Map<String, dynamic> item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DS.spaceMD),
        child: Row(
          children: [
            // التاريخ واليوم
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
                  Text(
                    item['day'],
                    style: TextStyle(color: DS.neutral500, fontSize: 13),
                  ),
                ],
              ),
            ),

            // وقت الحضور (إذا وجد)
            if (item['time'] != '-')
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: DS.neutral400),
                    Text(item['time'], style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),

            // الحالة (باستخدام المكون الذي أنشأته أنت)
            _getStatusBadge(item['status']),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لربط النصوص بالـ StatusBadge الخاص بك
  Widget _getStatusBadge(String status) {
    switch (status) {
      case 'Present':
        return StatusBadge.present();
      case 'Absent':
        return StatusBadge.absent();
      case 'Late':
        return StatusBadge.late();
      case 'Excused':
        return StatusBadge.excused();
      default:
        return const SizedBox.shrink();
    }
  }
}
