import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'theme.dart';

class SubmitExcusePage extends StatefulWidget {
  const SubmitExcusePage({super.key});

  @override
  State<SubmitExcusePage> createState() => _SubmitExcusePageState();
}

class _SubmitExcusePageState extends State<SubmitExcusePage>
    with SingleTickerProviderStateMixin {
  final _reasonController = TextEditingController();
  DateTime? _selectedDate;
  String? _fileName;
  FilePickerResult? _pickerResult;
  bool _isSubmitting = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: DS.primary500,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        _pickerResult = result;
        _fileName = result.files.first.name;
      });
    }
  }

  void _submit() async {
    if (_selectedDate == null ||
        _reasonController.text.isEmpty ||
        _pickerResult == null) {
      SnackHelper.error(context, 'Please fill all fields and upload a file');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('attendance').add({
        'uid': "OBfCSGRm5iM68jRQtzm42K91JLp1",
        'checkIn': Timestamp.fromDate(_selectedDate!),
        'status': 'Excused',
        'reason': _reasonController.text,
        'attachmentUrl': " ",
        'createdAt': FieldValue.serverTimestamp(),
      });

      JadeerDialog(
        title: 'Success',
        primaryLabel: 'Back to Home',
        content:
            const Text('Your excuse has been submitted and is under review.'),
        primaryResult: true,
      ).show(context);

      setState(() {
        _selectedDate = null;
        _reasonController.clear();
        _fileName = null;
        _pickerResult = null;
      });
    } catch (e) {
      SnackHelper.error(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool get _isFormComplete =>
      _selectedDate != null &&
      _reasonController.text.isNotEmpty &&
      _pickerResult != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ThemedScaffold(
      appBar: const CustomHeader(title: 'Submit Excuse', showBack: true),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DS.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(isDark),
              const SizedBox(height: DS.spaceLG),
              _buildStepHeader(
                number: '1',
                title: 'Absence Date',
                subtitle: 'When were you absent?',
                isDark: isDark,
              ),
              const SizedBox(height: DS.spaceSM),
              _buildDatePicker(isDark),
              const SizedBox(height: DS.spaceLG),
              _buildStepHeader(
                number: '2',
                title: 'Reason for Absence',
                subtitle: 'Describe why you were absent',
                isDark: isDark,
              ),
              const SizedBox(height: DS.spaceSM),
              _buildReasonField(isDark),
              const SizedBox(height: DS.spaceLG),
              _buildStepHeader(
                number: '3',
                title: 'Supporting Document',
                subtitle: 'Upload proof (PDF or image)',
                isDark: isDark,
              ),
              const SizedBox(height: DS.spaceSM),
              _buildFileUpload(isDark),
              const SizedBox(height: DS.spaceXL),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DS.primary500,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: DS.primary500.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DS.radiusXL),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.send_rounded, size: 20),
                            SizedBox(width: DS.spaceSM),
                            Text(
                              'Submit Excuse',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: DS.spaceLG),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DS.spaceMD),
      decoration: BoxDecoration(
        color: isDark
            ? DS.accentAmber.withOpacity(0.1)
            : DS.accentAmber.withOpacity(0.06),
        borderRadius: BorderRadius.circular(DS.radiusXL),
        border: Border.all(color: DS.accentAmber.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DS.accentAmber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(DS.radiusLG),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: DS.accentAmber,
              size: 20,
            ),
          ),
          const SizedBox(width: DS.spaceMD),
          Expanded(
            child: Text(
              'Please provide accurate information. Your excuse will be reviewed by your supervisor.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? DS.neutral300 : DS.neutral600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader({
    required String number,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: DS.primary500,
            borderRadius: BorderRadius.circular(DS.radiusMD),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: DS.spaceSM),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isDark ? Colors.white : DS.neutral800,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: DS.neutral500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker(bool isDark) {
    final hasDate = _selectedDate != null;
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(DS.spaceMD),
        decoration: BoxDecoration(
          color: isDark ? DS.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(DS.radiusXL),
          border: Border.all(
            color: hasDate
                ? DS.success
                : (isDark ? DS.neutral700 : DS.neutral300),
            width: hasDate ? 1.5 : 1,
          ),
          boxShadow: isDark ? null : DS.shadowSM,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: hasDate
                    ? DS.success.withOpacity(0.12)
                    : (isDark
                        ? DS.primary500.withOpacity(0.12)
                        : DS.primary50),
                borderRadius: BorderRadius.circular(DS.radiusLG),
              ),
              child: Icon(
                hasDate
                    ? Icons.event_available_rounded
                    : Icons.calendar_month_rounded,
                color: hasDate ? DS.success : DS.primary500,
                size: 22,
              ),
            ),
            const SizedBox(width: DS.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasDate ? 'Selected Date' : 'Select Date',
                    style: TextStyle(fontSize: 12, color: DS.neutral500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasDate
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Tap to choose a date',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          hasDate ? FontWeight.w600 : FontWeight.w400,
                      color: hasDate
                          ? (isDark ? Colors.white : DS.neutral800)
                          : DS.neutral400,
                    ),
                  ),
                ],
              ),
            ),
            if (hasDate)
              const Icon(Icons.check_circle_rounded,
                  color: DS.success, size: 22)
            else
              Icon(Icons.chevron_right_rounded,
                  color: DS.neutral400, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? DS.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(DS.radiusXL),
        border: Border.all(
          color: isDark ? DS.neutral700 : DS.neutral300,
        ),
        boxShadow: isDark ? null : DS.shadowSM,
      ),
      child: TextField(
        controller: _reasonController,
        maxLines: 4,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Describe why you were absent...',
          hintStyle: TextStyle(color: DS.neutral400, fontSize: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.all(DS.spaceMD),
        ),
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : DS.neutral800,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildFileUpload(bool isDark) {
    final hasFile = _fileName != null;
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.all(DS.spaceLG),
        decoration: BoxDecoration(
          color: isDark ? DS.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(DS.radiusXL),
          border: Border.all(
            color: hasFile
                ? DS.success
                : (isDark ? DS.neutral700 : DS.neutral300),
            width: hasFile ? 1.5 : 1,
          ),
          boxShadow: isDark ? null : DS.shadowSM,
        ),
        child: hasFile
            ? _buildFileUploaded(isDark)
            : _buildFileEmpty(isDark),
      ),
    );
  }

  Widget _buildFileEmpty(bool isDark) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isDark
                ? DS.primary500.withOpacity(0.12)
                : DS.primary50,
            borderRadius: BorderRadius.circular(DS.radiusXL),
          ),
          child: const Icon(
            Icons.cloud_upload_outlined,
            color: DS.primary500,
            size: 28,
          ),
        ),
        const SizedBox(height: DS.spaceMD),
        Text(
          'Tap to upload',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : DS.neutral800,
          ),
        ),
        const SizedBox(height: DS.spaceXS),
        Text(
          'PDF, JPG, or PNG (max 10MB)',
          style: TextStyle(fontSize: 12, color: DS.neutral500),
        ),
      ],
    );
  }

  Widget _buildFileUploaded(bool isDark) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: DS.success.withOpacity(0.12),
            borderRadius: BorderRadius.circular(DS.radiusLG),
          ),
          child: const Icon(
            Icons.description_rounded,
            color: DS.success,
            size: 22,
          ),
        ),
        const SizedBox(width: DS.spaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fileName!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : DS.neutral800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              const Text(
                'Tap to change file',
                style: TextStyle(fontSize: 12, color: DS.neutral500),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_circle_rounded,
            color: DS.success, size: 22),
      ],
    );
  }
}