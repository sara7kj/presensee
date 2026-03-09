import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme.dart';

class SupervisorExcuses extends StatefulWidget {
  final String supervisorId;
  const SupervisorExcuses({super.key, required this.supervisorId});

  @override
  State<SupervisorExcuses> createState() => _SupervisorExcusesState();
}

class _SupervisorExcusesState extends State<SupervisorExcuses> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Excuses', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: DS.neutral900)),
          const SizedBox(height: 4),
          const Text('Review and manage student excuses', style: TextStyle(fontSize: 14, color: DS.neutral500)),
          const SizedBox(height: 24),

          // Filter Chips
          Wrap(spacing: 8, children: [
            _chip('All', 'all'),
            _chip('Pending', 'pending'),
            _chip('Approved', 'approved'),
            _chip('Rejected', 'rejected'),
          ]),
          const SizedBox(height: 20),

          // List
          _buildList(),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: DS.primary500,
      backgroundColor: DS.neutral100,
      labelStyle: TextStyle(color: selected ? Colors.white : DS.neutral600, fontWeight: FontWeight.w500, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: BorderSide.none),
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  Widget _buildList() {
    Query query = FirebaseFirestore.instance
        .collection('Excuses')
        .where('supervisorId', isEqualTo: widget.supervisorId);

    if (_filter != 'all') query = query.where('status', isEqualTo: _filter);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(children: [
            Icon(Icons.description_outlined, size: 48, color: DS.neutral300),
            const SizedBox(height: 12),
            const Text('No excuses found', style: TextStyle(color: DS.neutral400, fontSize: 14)),
          ])));
        }

        return Column(
          children: snap.data!.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _ExcuseCard(
              docId: doc.id,
              studentName: d['studentName'] ?? 'Student',
              type: d['type'] ?? 'Excuse',
              startDate: d['startDate'] ?? '',
              endDate: d['endDate'] ?? '',
              reason: d['reason'] ?? '',
              status: d['status'] ?? 'pending',
              fileUrl: d['fileUrl'],
            );
          }).toList(),
        );
      },
    );
  }
}

// ──────────── Excuse Card ────────────

class _ExcuseCard extends StatelessWidget {
  final String docId, studentName, type, startDate, endDate, reason, status;
  final String? fileUrl;

  const _ExcuseCard({
    required this.docId, required this.studentName, required this.type,
    required this.startDate, required this.endDate, required this.reason,
    required this.status, this.fileUrl,
  });

  Future<void> _update(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('Excuses').doc(docId).update({'status': newStatus});
      if (context.mounted) SnackHelper.success(context, 'Excuse ${newStatus == 'approved' ? 'approved' : 'rejected'}');
    } catch (e) {
      if (context.mounted) SnackHelper.error(context, 'Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = studentName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    final dateRange = startDate == endDate ? startDate : '$startDate → $endDate';

    Widget badge;
    switch (status) {
      case 'approved': badge = StatusBadge.present(); break;
      case 'rejected': badge = StatusBadge.absent(); break;
      default: badge = const StatusBadge(label: 'Pending', color: DS.statusLate, backgroundColor: DS.statusLateBg);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(DS.radiusLG), border: Border.all(color: DS.neutral200), boxShadow: DS.shadowSM),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(radius: 21, backgroundColor: DS.primary100, child: Text(initials, style: const TextStyle(color: DS.primary600, fontSize: 14, fontWeight: FontWeight.w700))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(studentName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: DS.neutral800)),
            const SizedBox(height: 2),
            Text('$type  •  $dateRange', style: const TextStyle(fontSize: 13, color: DS.neutral500)),
            if (reason.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(reason, style: const TextStyle(fontSize: 13, color: DS.neutral600))),
          ])),
          badge,
        ]),

        if (fileUrl != null && fileUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.attach_file_rounded, size: 16),
              label: const Text('View Attachment'),
              style: TextButton.styleFrom(foregroundColor: DS.primary500, textStyle: const TextStyle(fontSize: 13)),
            ),
          ),

        if (status == 'pending') ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: DS.neutral100))),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton(
                onPressed: () => _update(context, 'rejected'),
                style: OutlinedButton.styleFrom(foregroundColor: DS.statusAbsent, side: const BorderSide(color: DS.statusAbsent), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.radiusMD))),
                child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _update(context, 'approved'),
                style: ElevatedButton.styleFrom(backgroundColor: DS.statusPresent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.radiusMD))),
                child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}