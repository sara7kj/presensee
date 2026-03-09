import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme.dart';
import 'student_details.dart';

class SupervisorStudentsList extends StatefulWidget {
  final String supervisorId;
  const SupervisorStudentsList({super.key, required this.supervisorId});
  @override
  State<SupervisorStudentsList> createState() => _State();
}

class _State extends State<SupervisorStudentsList> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Students', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: DS.neutral900)),
        const SizedBox(height: 4),
        Text('Monitor your assigned trainees', style: TextStyle(fontSize: 14, color: DS.neutral500)),
        const SizedBox(height: 24),

        // Search
        SizedBox(width: 360, child: TextField(
          onChanged: (v) => setState(() => _q = v),
          decoration: InputDecoration(
            hintText: 'Search by name or email...', prefixIcon: const Icon(Icons.search_rounded, size: 20),
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DS.neutral200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DS.neutral200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DS.primary500, width: 2)),
          ),
        )),
        const SizedBox(height: 20),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('Trainees')
            .where('supervisorId', isEqualTo: widget.supervisorId).snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting)
              return const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()));
            if (!snap.hasData || snap.data!.docs.isEmpty)
              return Center(child: Padding(padding: const EdgeInsets.all(60), child: Column(children: [
                Icon(Icons.people_outline, size: 56, color: DS.neutral300),
                const SizedBox(height: 12),
                const Text('No students assigned', style: TextStyle(color: DS.neutral400, fontSize: 16)),
              ])));

            final docs = snap.data!.docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              final n = (data['name'] ?? '').toString().toLowerCase();
              final e = (data['email'] ?? '').toString().toLowerCase();
              return n.contains(_q.toLowerCase()) || e.contains(_q.toLowerCase());
            }).toList();

            return Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DS.neutral200), boxShadow: DS.shadowSM),
              child: Column(children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: DS.neutral50,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: DS.neutral200)),
                  ),
                  child: Row(children: [
                    _col('Student', flex: 3),
                    _col('Email', flex: 3),
                    _col('Phone', flex: 2),
                    _col('Progress', flex: 2),
                    const SizedBox(width: 40),
                  ]),
                ),
                // Rows
                ...docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final name = d['name'] ?? '';
                  final email = d['email'] ?? '';
                  final phone = d['phone'] ?? '';
                  final hrs = (d['completedHours'] ?? 0).toDouble();
                  final rem = (d['remainingHours'] ?? 280).toDouble();
                  final pct = (hrs + rem) > 0 ? (hrs / (hrs + rem) * 100).round() : 0;
                  final ini = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

                  return InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => StudentDetailsPage(studentId: d['studentId'] ?? doc.id, studentName: name))),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: DS.neutral100))),
                      child: Row(children: [
                        Expanded(flex: 3, child: Row(children: [
                          CircleAvatar(radius: 18, backgroundColor: DS.primary100,
                            child: Text(ini, style: const TextStyle(color: DS.primary600, fontSize: 12, fontWeight: FontWeight.w700))),
                          const SizedBox(width: 12),
                          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: DS.neutral800)),
                        ])),
                        Expanded(flex: 3, child: Text(email, style: const TextStyle(fontSize: 13, color: DS.neutral500))),
                        Expanded(flex: 2, child: Text(phone, style: const TextStyle(fontSize: 13, color: DS.neutral500))),
                        Expanded(flex: 2, child: Row(children: [
                          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(value: pct / 100, minHeight: 6, backgroundColor: DS.neutral100,
                              valueColor: AlwaysStoppedAnimation(pct > 60 ? DS.statusPresent : DS.warning)))),
                          const SizedBox(width: 10),
                          Text('$pct%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: pct > 60 ? DS.statusPresent : DS.warning)),
                        ])),
                        const SizedBox(width: 40, child: Icon(Icons.chevron_right_rounded, color: DS.neutral400, size: 20)),
                      ]),
                    ),
                  );
                }),
              ]),
            );
          },
        ),
      ]),
    );
  }

  Widget _col(String t, {int flex = 1}) => Expanded(flex: flex,
    child: Text(t.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DS.neutral400, letterSpacing: 0.8)));
}