import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/services/anamnese_attachment_service.dart';

void main() {
  test('accepts PDF only for documents', () {
    final pdf = Uint8List.fromList('%PDF-1.7'.codeUnits);
    expect(
      AnamneseAttachmentService.validate('report.pdf', pdf),
      'application/pdf',
    );
    expect(
      () => AnamneseAttachmentService.validate(
        'report.pdf',
        pdf,
        photosOnly: true,
      ),
      throwsFormatException,
    );
  });
  test('rejects empty, oversized and disguised files', () {
    for (final bytes in [
      Uint8List(0),
      Uint8List(AnamneseAttachmentService.maxBytes + 1),
      Uint8List.fromList('<html>'.codeUnits),
    ]) {
      expect(
        () => AnamneseAttachmentService.validate('photo.jpg', bytes),
        throwsFormatException,
      );
    }
  });
  test('accepts supported photo signatures', () {
    expect(
      AnamneseAttachmentService.validate(
        'photo.JPG',
        Uint8List.fromList([255, 216, 255, 0]),
        photosOnly: true,
      ),
      'image/jpeg',
    );
    expect(
      AnamneseAttachmentService.validate(
        'photo.png',
        Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
        photosOnly: true,
      ),
      'image/png',
    );
  });
}
