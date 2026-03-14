import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // نحتاج هذه المكتبة لرفع الملفات
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
      setState(() => _fileName = result.files.first.name);
    }
  }

  void _submit() {
    if (_selectedDate == null ||
        _reasonController.text.isEmpty ||
        _fileName == null) {
      SnackHelper.error(context, 'Please fill all fields and upload a file');
      return;
    }

    // هنا نضع كود الرفع للسيرفر لاحقاً
    JadeerDialog(
      title: 'Success',
      primaryLabel: 'Back to Home',
      content:
          const Text('Your excuse has been submitted and is under review.'),
      primaryResult: true,
    ).show(
        context); // ملاحظة: تأكد من إضافة دالة show في كلاس JadeerDialog أو استدعاء showDialog
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

  // مكوّن عنوان القسم
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  // مكوّن زر الاختيار (للتاريخ والملف)
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
