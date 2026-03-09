import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme.dart';
import 'student_details.dart';

class SupervisorStudentsList extends StatefulWidget {
  final String supervisorId;
  const SupervisorStudentsList({super.key, required this.supervisorId});

  @override
  State<SupervisorStudentsList> createState() => _SupervisorStudentsListState();
}

class _SupervisorStudentsListState extends State<SupervisorStudentsList> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Students', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: DS.neutral900)),
          const SizedBox(height: 4),
          const Text('Monitor assigned trainees', style: TextStyle(fontSize: 14, color: DS.neutral500)),
          const SizedBox(height: 24),

          // Search
          SizedBox(
            width: 340,
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(DS.radiusMD), borderSide: BorderSide(color: DS.neutral300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(DS.radiusMD), borderSide: BorderSide(color: DS.neutral300)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Table
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Trainees')
                .where('supervisorId', isEqualTo: widget.supervisorId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No students assigned yet', style: TextStyle(color: DS.neutral400))));
              }

              final docs = snapshot.data!.docs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final name = (d['name'] ?? '').toString().toLowerCase();
                final email = (d['email'] ?? '').toString().toLowerCase();
                return name.contains(_search.toLowerCase()) || email.contains(_search.toLowerCase());
              }).toList();

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DS.radiusLG),
                  border: Border.all(color: DS.neutral200),
                  boxShadow: DS.shadowSM,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DS.radiusLG),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(DS.neutral50),
                    headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DS.neutral500, letterSpacing: 0.5),
                    columnSpacing: 24, horizontalMargin: 20,
                    columns: const [
                      DataColumn(label: Text('STUDENT')),
                      DataColumn(label: Text('EMAIL')),
                      DataColumn(label: Text('PHONE')),
                      DataColumn(label: Text('PROGRESS')),
                      DataColumn(label: Text('')),
                    ],
                    rows: docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final name = d['name'] ?? 'Unknown';
                      final email = d['email'] ?? '';
                      final phone = d['phone'] ?? '';
                      final completed = (d['completedHours'] ?? 0).toDouble();
                      final remaining = (d['remainingHours'] ?? 280).toDouble();
                      final total = completed + remaining;
                      final pct = total > 0 ? (completed / total * 100).round() : 0;
                      final initials = name.toString().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

                      return DataRow(
                        onSelectChanged: (_) {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => StudentDetailsPage(studentId: d['studentId'] ?? doc.id, studentName: name),
                          ));
                        },
                        cells: [
                          DataCell(Row(children: [
                            CircleAvatar(radius: 17, backgroundColor: DS.primary100, child: Text(initials, style: const TextStyle(color: DS.primary600, fontSize: 12, fontWeight: FontWeight.w700))),
                            const SizedBox(width: 10),
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w500, color: DS.neutral800)),
                          ])),
                          DataCell(Text(email, style: const TextStyle(fontSize: 13, color: DS.neutral600))),
                          DataCell(Text(phone, style: const TextStyle(fontSize: 13, color: DS.neutral600))),
                          DataCell(Row(children: [
                            SizedBox(width: 80, child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: pct / 100, minHeight: 6, backgroundColor: DS.neutral100, valueColor: AlwaysStoppedAnimation(pct > 60 ? DS.statusPresent : DS.warning)))),
                            const SizedBox(width: 8),
                            Text('$pct%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: DS.neutral600)),
                          ])),
                          DataCell(Icon(Icons.chevron_right_rounded, color: DS.primary500, size: 20)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}