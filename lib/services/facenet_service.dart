import 'package:tflite_flutter/tflite_flutter.dart';

class FaceNetService {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');

    final inTensor = _interpreter!.getInputTensor(0);
    final outTensor = _interpreter!.getOutputTensor(0);

    // هذا الدليل القاطع
    print('✅ Input: ${inTensor.shape} type: ${inTensor.type}');
    print('✅ Output: ${outTensor.shape} type: ${outTensor.type}');
  }
}
