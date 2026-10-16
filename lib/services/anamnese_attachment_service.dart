import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import '../config/supabase_config.dart';
import '../models/anamnese_model.dart';
import '../repositories/anamnese_repository.dart';

class AnamneseAttachment {
  final String reference;
  final String name;
  final Uint8List bytes;
  const AnamneseAttachment(this.reference, this.name, this.bytes);
}

class AnamneseAttachmentService {
  static const maxBytes = 10 * 1024 * 1024;
  final AnamneseRepository repository;
  final Future<XFile?> Function(bool photosOnly) picker;

  AnamneseAttachmentService({
    AnamneseRepository? repository,
    Future<XFile?> Function(bool photosOnly)? picker,
  }) : repository = repository ?? AnamneseRepository(),
       picker = picker ?? _pick;

  static Future<XFile?> _pick(bool photosOnly) => openFile(
    acceptedTypeGroups: [
      XTypeGroup(
        label: photosOnly ? 'Fotos' : 'Laudos e fotos',
        extensions: photosOnly
            ? ['jpg', 'jpeg', 'png']
            : ['pdf', 'jpg', 'jpeg', 'png'],
        uniformTypeIdentifiers: photosOnly
            ? ['public.jpeg', 'public.png']
            : ['com.adobe.pdf', 'public.jpeg', 'public.png'],
      ),
    ],
  );

  static String validate(
    String name,
    Uint8List bytes, {
    bool photosOnly = false,
  }) {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw const FormatException(
        'Selecione um arquivo de ate 10 MB, nao vazio.',
      );
    }
    final extension = name.split('.').last.toLowerCase();
    final pdf =
        bytes.length >= 5 && String.fromCharCodes(bytes.take(5)) == '%PDF-';
    final png =
        bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71;
    final jpg =
        bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255;
    if (extension == 'pdf' && pdf && !photosOnly) return 'application/pdf';
    if (extension == 'png' && png) return 'image/png';
    if (['jpg', 'jpeg'].contains(extension) && jpg) return 'image/jpeg';
    throw const FormatException('Formato invalido. Selecione PDF, JPG ou PNG.');
  }

  Future<AnamneseAttachment?> selectAndUpload(
    String studentId, {
    PostureAngle? angle,
  }) async {
    if (studentId.isEmpty || !SupabaseConfig.hasAuthenticatedUser) {
      throw const FormatException(
        'Entre na sua conta e salve o aluno antes de anexar arquivos.',
      );
    }
    final file = await picker(angle != null);
    if (file == null) return null;
    if (await file.length() > maxBytes) {
      throw const FormatException('O arquivo excede o limite de 10 MB.');
    }
    final bytes = await file.readAsBytes();
    final type = validate(file.name, bytes, photosOnly: angle != null);
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final reference = angle == null
        ? await repository.uploadMedicalDocument(
            studentId: studentId,
            docId: id,
            fileName: file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_'),
            docBytes: bytes,
            contentType: type,
          )
        : await repository.uploadPosturePhoto(
            studentId: studentId,
            photoId: id,
            angle: angle,
            imageBytes: bytes,
            contentType: type,
          );
    if (reference == null) {
      throw const FormatException(
        'Nao foi possivel enviar o arquivo. Verifique sua conexao e tente novamente.',
      );
    }
    return AnamneseAttachment(reference, file.name, bytes);
  }
}
