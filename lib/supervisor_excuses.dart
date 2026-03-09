import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme.dart';

class SupervisorExcuses extends StatefulWidget {
  final String supervisorId;
  const SupervisorExcuses({super.key, required this.supervisorId});
  @override
  State<SupervisorExcuses> createState() => _State();
}

class _State extends State<SupervisorExcuses> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Excuses', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: DS.neutral900)),
        const SizedBox(height: 4),
        Text('Review and manage student leave requests', style: TextStyle(fontSize: 14, color: DS.neutral500)),
        const SizedBox(height: 24),

        // Filter tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: DS.neutral100, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _tab('All', 'all'),
            _tab('Pending', 'pending'),
            _tab('Approved', 'approved'),
            _tab('Rejected', 'rejected'),
          ]),
        ),
        const SizedBox(height: 24),

        // Counts
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('Excuses')
            .where('supervisorId', isEqualTo: widget.supervisorId).snapshots(),
          builder: (ctx, countSnap) {
            if (!countSnap.hasData) return const SizedBox();
            final all = countSnap.data!.docs;
            final pending = all.where((d) => d['status'] == 'pending').length;
            final approved = all.where((d) => d['status'] == 'approved').length;
            final rejected = all.where((d) => d['status'] == 'rejected').length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(children: [
                _countChip('$pending pending', DS.warning, DS.statusLateBg),
                const SizedBox(width: 10),
                _countChip('$approved approved', DS.statusPresent, DS.statusPresentBg),
                const SizedBox(width: 10),
                _countChip('$rejected rejected', DS.statusAbsent, DS.statusAbsentBg),
              ]),
            );
          },
        ),

        // List
        _list(),
      ]),
    );
  }

  Widget _tab(String label, String val) {
    final sel = _filter == val;
    return GestureDetector(
      onTap: () => setState(() => _filter = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: sel ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))] : [],
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
          color: sel ? DS.neutral800 : DS.neutral500)),
      ),
    );
  }

  Widget _countChip(String t, Color c, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
  );

  Widget _list() {
    Query q = FirebaseFirestore.instance.collection('Excuses')
      .where('supervisorId', isEqualTo: widget.supervisorId);
    if (_filter != 'all') q = q.where('status', isEqualTo: _filter);

    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()));
        if (!snap.hasData || snap.data!.docs.isEmpty)
          return Center(child: Padding(padding: const EdgeInsets.all(60), child: Column(children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: DS.neutral100, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.inbox_rounded, size: 32, color: DS.neutral300),
            ),
            const SizedBox(height: 16),
            const Text('No excuses found', style: TextStyle(color: DS.neutral400, fontSize: 15)),
          ])));

        return Column(children: snap.data!.docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return _ExcuseCard(
            docId: doc.id,
            name: d['studentName'] ?? '',
            type: d['type'] ?? '',
            start: d['startDate'] ?? '',
            end: d['endDate'] ?? '',
            reason: d['reason'] ?? '',
            status: d['status'] ?? 'pending',
            fileUrl: d['fileUrl'],
          );
        }).toList());
      },
    );
  }
}

class _ExcuseCard extends StatelessWidget {
  final String docId, name, type, start, end, reason, status;
  final dynamic fileUrl;

  const _ExcuseCard({
    required this.docId, required this.name, required this.type,
    required this.start, required this.end, required this.reason,
    required this.status, this.fileUrl,
  });

  Future<void> _act(BuildContext ctx, String s) async {
    try {
      await FirebaseFirestore.instance.collection('Excuses').doc(docId).update({'status': s});
      if (ctx.mounted) SnackHelper.success(ctx, 'Excuse ${s == 'approved' ? 'approved' : 'rejected'}');
    } catch (e) {
      if (ctx.mounted) SnackHelper.error(ctx, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ini = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    final dateRange = start == end ? start : '$start → $end';

    Widget badge;
    Color accent;
    switch (status) {
      case 'approved': badge = StatusBadge.present(); accent = DS.statusPresent; break;
      case 'rejected': badge = StatusBadge.absent(); accent = DS.statusAbsent; break;
      default: badge = const StatusBadge(label: 'Pending', color: DS.statusLate, backgroundColor: DS.statusLateBg); accent = DS.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DS.neutral200), boxShadow: DS.shadowSM,
      ),
      child: Column(children: [
        // Status accent bar
        Container(height: 3,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          )),
        Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [DS.primary500.withOpacity(0.15), DS.accentTeal.withOpacity(0.1)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(ini, style: const TextStyle(color: DS.primary600, fontSize: 14, fontWeight: FontWeight.w700))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: DS.neutral800)),
              const SizedBox(height: 4),
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: DS.primary50, borderRadius: BorderRadius.circular(4)),
                  child: Text(type, style: const TextStyle(fontSize: 11, color: DS.primary500, fontWeight: FontWeight.w500))),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today_rounded, size: 12, color: DS.neutral400),
                const SizedBox(width: 4),
                Text(dateRange, style: const TextStyle(fontSize: 12, color: DS.neutral500)),
              ]),
              if (reason.isNotEmpty) Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(reason, style: const TextStyle(fontSize: 13, color: DS.neutral600, height: 1.4)),
              ),
            ])),
            badge,
          ]),

          if (fileUrl != null && fileUrl.toString().isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 12), child: TextButton.icon(
              onPressed: () {}, icon: const Icon(Icons.attach_file_rounded, size: 16), label: const Text('View Attachment'),
              style: TextButton.styleFrom(foregroundColor: DS.primary500, textStyle: const TextStyle(fontSize: 13)),
            )),

          if (status == 'pending') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: DS.neutral100))),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton.icon(
                  onPressed: () => _act(context, 'rejected'),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DS.statusAbsent, side: BorderSide(color: DS.statusAbsent.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _act(context, 'approved'),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DS.statusPresent, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0,
                  ),
                ),
              ]),
            ),
          ],
        ])),
      ]),
    );
  }
}