import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceNetService {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    try {
      // إعدادات اختيارية لزيادة السرعة والاستقرار
      final options = InterpreterOptions()..threads = 4;

      _interpreter = await Interpreter.fromAsset(
        'assets/models/mobilefacenet.tflite',
        options: options,
      );

      final inTensor = _interpreter!.getInputTensor(0);
      final outTensor = _interpreter!.getOutputTensor(0);

      print('✅ Model Loaded Successfully');
      print('✅ Expected Input Shape: ${inTensor.shape}');
      print('✅ Expected Output Shape: ${outTensor.shape}');
    } catch (e) {
      print('❌ Error loading model: $e');
    }
  }

  Future<List<double>> extractEmbeddingFromFile(String imagePath) async {
    if (_interpreter == null) {
      throw Exception("Model not loaded. Call loadModel() first.");
    }

    // 1) كشف الوجه باستخدام ML Kit
    final detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

    final faces =
        await detector.processImage(InputImage.fromFilePath(imagePath));
    await detector.close();

    if (faces.isEmpty) throw Exception("No face detected");

    // 2) تحويل الصورة ومعالجتها
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception("Failed to decode image");

    // 3) قص الوجه (Crop) وتغيير الحجم إلى 112x112
    final box = faces.first.boundingBox;
    final faceCrop = img.copyCrop(
      decoded,
      x: box.left.toInt(),
      y: box.top.toInt(),
      width: box.width.toInt(),
      height: box.height.toInt(),
    );
    final resized = img.copyResize(faceCrop, width: 112, height: 112);

    // 4) تجهيز المدخلات (Input)
    // بما أن الـ Log عندك أظهر [2, 112, 112, 3]، سنقوم بتكرار الصورة مرتين لتجنب الخطأ
    // ولكن سنحاول أولاً إرسالها كـ Batch واحد وإذا كان الموديل صارم سيتعامل معها
    final inputShape = _interpreter!
        .getInputTensor(0)
        .shape; // غالباً [1, 112, 112, 3] أو [2, 112, 112, 3]
    final batchSize = inputShape[0];

    var input = List.generate(
      batchSize,
      (i) => List.generate(
        112,
        (y) => List.generate(
          112,
          (x) {
            final p = resized.getPixel(x, y);
            return [
              (p.r - 127.5) / 128.0,
              (p.g - 127.5) / 128.0,
              (p.b - 127.5) / 128.0,
            ];
          },
        ),
      ),
    );

    // 5) تجهيز المخرجات (Output)
    final outputShape =
        _interpreter!.getOutputTensor(0).shape; // [batchSize, 192]
    final outputSize = outputShape[1];
    final output =
        List.generate(batchSize, (_) => List.filled(outputSize, 0.0));

    // 6) تشغيل الموديل
    try {
      _interpreter!.run(input, output);
    } catch (e) {
      print("❌ Interpreter Run Error: $e");
      rethrow;
    }

    // إرجاع أول بصمة وجه (Embedding) في المصفوفة
    return List<double>.from(output[0]);
  }
}
