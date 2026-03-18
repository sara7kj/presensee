import 'dart:io'; // ضروري جداً للتعامل مع الملفات
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ضروري للتعامل مع قاعدة البيانات
import 'package:file_picker/file_picker.dart';
import 'theme.dart';

class SubmitExcusePage extends StatefulWidget {
  const SubmitExcusePage({super.key});

  @override
  State<SubmitExcusePage> createState() => _SubmitExcusePageState();
}

class _SubmitExcusePageState extends State<SubmitExcusePage> {
  final _reasonController = TextEditingController();
  DateTime? _selectedDate;
  String? _fileName;
  FilePickerResult? _pickerResult; // تم الاحتفاظ بتعريف واحد فقط

  // دالة لاختيار التاريخ
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // دالة لاختيار الملف (PDF أو صورة)
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
    // التحقق من تعبئة كافة الحقول
    if (_selectedDate == null ||
        _reasonController.text.isEmpty ||
        _pickerResult == null) {
      SnackHelper.error(context, 'Please fill all fields and upload a file');
      return;
    }

    try {
      // 1. رفع الملف إلى Firebase Storage
      // ننشئ اسماً فريداً للملف باستخدام الوقت لضمان عدم تكرار الأسماء
      /*String storageFileName =
          DateTime.now().millisecondsSinceEpoch.toString() + "_" + _fileName!;
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('excuses')
          .child(storageFileName);

      // تحويل المسار النصي إلى ملف حقيقي للرفع
      File file = File(_pickerResult!.files.first.path!);

      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();  */

      // 2. حفظ البيانات في كوليكشن attendance
      await FirebaseFirestore.instance.collection('attendance').add({
        'uid':
            "OBfCSGRm5iM68jRQtzm42K91JLp1", // ملاحظة: يفضل لاحقاً جلب الـ UID تلقائياً
        'checkIn': Timestamp.fromDate(_selectedDate!),
        'status': 'Excused',
        'reason': _reasonController.text,
        'attachmentUrl': " ",
        'createdAt': FieldValue.serverTimestamp(),
      });

      // إظهار رسالة النجاح
      JadeerDialog(
        title: 'Success',
        primaryLabel: 'Back to Home',
        content:
            const Text('Your excuse has been submitted and is under review.'),
        primaryResult: true,
      ).show(context);

      // مسح البيانات بعد النجاح
      setState(() {
        _selectedDate = null;
        _reasonController.clear();
        _fileName = null;
        _pickerResult = null;
      });
    } catch (e) {
      SnackHelper.error(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      appBar: const CustomHeader(title: 'Submit Excuse', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DS.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Absence Date'),
            const SizedBox(height: DS.spaceSM),
            _buildPickerTile(
              label: _selectedDate == null
                  ? 'Select Date'
                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              icon: Icons.calendar_month_rounded,
              onTap: _pickDate,
            ),
            const SizedBox(height: DS.spaceLG),
            _buildSectionTitle('Reason for Absence'),
            const SizedBox(height: DS.spaceSM),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe why you were absent...',
              ),
            ),
            const SizedBox(height: DS.spaceLG),
            _buildSectionTitle('Supporting Document'),
            const SizedBox(height: DS.spaceSM),
            _buildPickerTile(
              label: _fileName ?? 'Upload PDF or Image',
              icon: Icons.cloud_upload_outlined,
              onTap: _pickFile,
              isUploaded: _fileName != null,
            ),
            const SizedBox(height: DS.space2XL),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Submit Excuse'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  Widget _buildPickerTile({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isUploaded = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DS.radiusMD),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: DS.spaceMD, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? DS.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(DS.radiusMD),
          border: Border.all(
            color: isUploaded
                ? DS.success
                : (isDark ? DS.neutral700 : DS.neutral300),
            width: isUploaded ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isUploaded ? DS.success : DS.primary500),
            const SizedBox(width: DS.spaceMD),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isUploaded
                      ? DS.success
                      : (isDark ? Colors.white : DS.neutral800),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isUploaded)
              const Icon(Icons.check_circle, color: DS.success, size: 20),
          ],
        ),
      ),
    );
  }
}
