import 'package:flutter/material.dart';
import 'services/facenet_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ModelTestPage());
  }
}

class ModelTestPage extends StatefulWidget {
  const ModelTestPage({super.key});

  @override
  State<ModelTestPage> createState() => _ModelTestPageState();
}

class _ModelTestPageState extends State<ModelTestPage> {
  final FaceNetService _service = FaceNetService();
  String status = 'Loading model...';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _service.loadModel();
      setState(() => status = '✅ Model loaded');
    } catch (e) {
      setState(() => status = '❌ $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Model Test')),
      body: Center(child: Text(status, textAlign: TextAlign.center)),
    );
  }
}
