import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceNetService {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    _interpreter =
        await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');

    final inTensor = _interpreter!.getInputTensor(0);
    final outTensor = _interpreter!.getOutputTensor(0);

    print('✅ Input: ${inTensor.shape} type: ${inTensor.type}');
    print('✅ Output: ${outTensor.shape} type: ${outTensor.type}');
  }

  Future<List<double>> extractEmbeddingFromFile(String imagePath) async {
  if (_interpreter == null) {
    throw Exception("Model not loaded. Call loadModel() first.");
  }

  // اقرأ الصورة
  final bytes = await File(imagePath).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw Exception("Failed to decode image");

  // Resize إلى 112x112
  final resized = img.copyResize(decoded, width: 112, height: 112);

  // batch size من الموديل (عندك = 2)
  final inShape = _interpreter!.getInputTensor(0).shape;   // [2,112,112,3]
  final outShape = _interpreter!.getOutputTensor(0).shape; // [2,192]
  final batch = inShape[0];
  final embSize = outShape[1];

  // نبني صورة واحدة 112x112x3
  final single = List.generate(
    112,
    (y) => List.generate(
      112,
      (x) {
        final p = resized.getPixel(x, y);
        final r = p.r.toDouble();
        final g = p.g.toDouble();
        final b = p.b.toDouble();

        return [
          (r - 127.5) / 128.0,
          (g - 127.5) / 128.0,
          (b - 127.5) / 128.0,
        ];
      },
    ),
  );

  // input: [batch,112,112,3] (نكرر نفس الصورة batch مرات)
  final input = List.generate(batch, (_) => single);

  // output: [batch,192]
  final output = List.generate(batch, (_) => List.filled(embSize, 0.0));

  _interpreter!.run(input, output);

  // ناخذ أول embedding (index 0)
  final emb = List<double>.from(output[0]);

  print("🔥 Embedding sample: ${emb.take(10).toList()}");
  print("✅ Embedding length: ${emb.length}");

  return emb;
}

}

extension _Reshape on List<double> {
  List<List<double>> reshape(List<int> dims) {
    final rows = dims[0];
    final cols = dims[1];
    final out = List.generate(rows, (_) => List.filled(cols, 0.0));
    int k = 0;
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        out[i][j] = this[k++];
      }
    }
    return out;
  }
}