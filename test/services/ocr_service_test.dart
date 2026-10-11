import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/services/ocr_service.dart';

void main() {
  group('OcrService', () {
    // Only the file-existence guard is unit-testable here — actually
    // recognizing text requires the ML Kit platform channel, which is not
    // available outside a real device/emulator (see final report's
    // documented limitation).
    test(
      'returns OcrFailure (not an empty success) when the file does not exist',
      () async {
        final result = await OcrService.recognizeText(
          'this/path/definitely/does/not/exist.jpg',
        );

        expect(result, isA<OcrFailure>());
        expect((result as OcrFailure).message, contains('tidak ditemukan'));
      },
    );
  });
}
