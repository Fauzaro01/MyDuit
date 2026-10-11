import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result of an OCR attempt. Callers must handle all three cases explicitly —
/// a failed or empty scan is never silently treated as a successful one.
sealed class OcrResult {
  const OcrResult();
}

class OcrSuccess extends OcrResult {
  final String text;
  const OcrSuccess(this.text);
}

/// OCR ran successfully but found no readable text (blurry photo, blank image).
class OcrEmpty extends OcrResult {
  const OcrEmpty();
}

class OcrFailure extends OcrResult {
  final String message;
  const OcrFailure(this.message);
}

class OcrService {
  /// Extracts text from an image file using on-device ML Kit Text Recognition.
  ///
  /// Note: a fresh [TextRecognizer] is created per call and closed in
  /// [finally] — this is intentional (not a resource leak left unfixed).
  /// It's a one-shot scan triggered by a single user action, so there's no
  /// long-lived instance to manage; a cached singleton would need its own
  /// lifecycle wiring for no measurable benefit here.
  static Future<OcrResult> recognizeText(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      return const OcrFailure('Berkas gambar tidak ditemukan.');
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      if (recognized.text.trim().isEmpty) {
        return const OcrEmpty();
      }
      return OcrSuccess(recognized.text);
    } catch (e) {
      // Report the exception type only — never echo raw exception details,
      // which on some platforms can include the image path or decoder output.
      return OcrFailure('Gagal memproses gambar (${e.runtimeType}).');
    } finally {
      await recognizer.close();
    }
  }
}
