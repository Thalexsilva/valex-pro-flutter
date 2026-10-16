import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/workout_model.dart';
import '../utils/prescription_load.dart';

class PdfGeneratorService {
  static String _getDayBadgeText(String dow) {
    if (dow.isEmpty) return 'A';
    String clean = dow
        .replaceAll(RegExp(r'treino\s*', caseSensitive: false), '')
        .trim();
    if (clean.isEmpty) clean = dow.trim();
    if (clean.length > 3) {
      final match = RegExp(
        r'\b[A-Z0-9]{1,2}\b',
        caseSensitive: false,
      ).firstMatch(clean);
      if (match != null) return match.group(0)!.toUpperCase();
      return clean.substring(0, 2).toUpperCase();
    }
    return clean.toUpperCase();
  }

  static Map<String, String> _splitSetLine(String line) {
    String typeOverride = '';
    String label = '';
    String desc = line.trim();
    String setLoad = '';

    final match = RegExp(r'^\[(warmup|prep|work)\](.*)').firstMatch(desc);
    if (match != null) {
      typeOverride = match.group(1)!;
      desc = match.group(2)!;
    }

    if (desc.contains(':')) {
      final idx = desc.indexOf(':');
      label = desc.substring(0, idx).trim();
      desc = desc.substring(idx + 1).trim();
    }

    if (desc.contains(' @ ')) {
      final parts = desc.split(' @ ');
      desc = parts[0].trim();
      setLoad = parts.sublist(1).join(' @ ').trim();
    }

    return {
      'typeOverride': typeOverride,
      'label': label,
      'desc': desc,
      'setLoad': setLoad,
    };
  }

  static String _getSetType(String label, String override) {
    if (override.isNotEmpty) return override;
    final l = label.toLowerCase();
    if (l.contains('aquecimento')) return 'warmup';
    if (l.contains('prepara')) return 'prep';
    return 'work';
  }

  static Future<Uint8List> generateWorkoutPdf(WorkoutSheet sheet) async {
    final pdf = pw.Document();

    // Carregar Fontes Oficiais
    pw.Font? fontBebas;
    pw.Font? fontPoppinsRegular;
    pw.Font? fontPoppinsBold;
    pw.MemoryImage? imgLogo;
    pw.MemoryImage? imgCharacter;

    try {
      final bebasBytes = await rootBundle.load(
        'assets/fonts/BebasNeue-Regular.ttf',
      );
      fontBebas = pw.Font.ttf(bebasBytes);
    } catch (_) {
      try {
        final f = File('assets/fonts/BebasNeue-Regular.ttf');
        if (await f.exists()) {
          final bytes = await f.readAsBytes();
          fontBebas = pw.Font.ttf(bytes.buffer.asByteData());
        }
      } catch (_) {}
      fontBebas ??= pw.Font.helveticaBold();
    }

    try {
      final regBytes = await rootBundle.load(
        'assets/fonts/Poppins-Regular.ttf',
      );
      fontPoppinsRegular = pw.Font.ttf(regBytes);
    } catch (_) {
      try {
        final f = File('assets/fonts/Poppins-Regular.ttf');
        if (await f.exists()) {
          final bytes = await f.readAsBytes();
          fontPoppinsRegular = pw.Font.ttf(bytes.buffer.asByteData());
        }
      } catch (_) {}
      fontPoppinsRegular ??= pw.Font.helvetica();
    }

    try {
      final boldBytes = await rootBundle.load('assets/fonts/Poppins-Bold.ttf');
      fontPoppinsBold = pw.Font.ttf(boldBytes);
    } catch (_) {
      try {
        final f = File('assets/fonts/Poppins-Bold.ttf');
        if (await f.exists()) {
          final bytes = await f.readAsBytes();
          fontPoppinsBold = pw.Font.ttf(bytes.buffer.asByteData());
        }
      } catch (_) {}
      fontPoppinsBold ??= pw.Font.helveticaBold();
    }

    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      imgLogo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      // Logo asset is optional
    }

    try {
      final charBytes = await rootBundle.load('assets/images/character.png');
      imgCharacter = pw.MemoryImage(charBytes.buffer.asUint8List());
    } catch (_) {
      // Character asset is optional
    }

    final theme = pw.ThemeData.withFont(
      base: fontPoppinsRegular,
      bold: fontPoppinsBold,
    );

    // Cores Oficiais do style.css
    final colorCarbon = PdfColor.fromHex('#12151b');
    final colorCarbon2 = PdfColor.fromHex('#1b202a');
    final colorCarbon3 = PdfColor.fromHex('#232a36');
    final colorSteel = PdfColor.fromHex('#aab4c0');
    final colorSteelDim = PdfColor.fromHex('#8e9aa8');
    final colorBlue = PdfColor.fromHex('#2f8fe6');
    final colorBlueLight = PdfColor.fromHex('#6fc4ff');
    final colorPaper = PdfColor.fromHex('#f7f4ef');
    final colorPaperCard = PdfColor.fromHex('#ffffff');
    final colorInk = PdfColor.fromHex('#1c2027');
    final colorMuted = PdfColor.fromHex('#74808d');
    final colorLine = PdfColor.fromHex('#e7e2d9');

    final totalWorkoutPages = sheet.days.length;
    final totalPages =
        1 + 1 + totalWorkoutPages + 1; // Cover + Index + Days + Cardio

    // -------------------------------------------------------------
    // PAGE 1: COVER PAGE (.cover-page)
    // -------------------------------------------------------------
    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Fundo Carbon Gradiente (Radial)
              pw.Container(
                width: double.infinity,
                height: double.infinity,
                decoration: pw.BoxDecoration(
                  gradient: pw.RadialGradient(
                    center: const pw.FractionalOffset(0.78, 0.08),
                    radius: 0.8,
                    colors: [
                      PdfColor(47 / 255, 143 / 255, 230 / 255, 0.28),
                      colorCarbon,
                      colorCarbon2,
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
              ),

              // Character Image à direita se disponível
              if (imgCharacter != null)
                pw.Positioned(
                  right: -20,
                  bottom: 0,
                  child: pw.Image(imgCharacter, height: 600),
                ),

              // Conteúdo da Capa
              pw.Padding(
                padding: const pw.EdgeInsets.only(
                  left: 45,
                  top: 60,
                  right: 45,
                  bottom: 40,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo + Kicker
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (imgLogo != null)
                          pw.Image(imgLogo, height: 65)
                        else
                          pw.Text(
                            'VALEX',
                            style: pw.TextStyle(
                              font: fontBebas,
                              fontSize: 32,
                              color: colorBlueLight,
                            ),
                          ),
                        pw.SizedBox(height: 35),
                        pw.Text(
                          'PROGRAMA SEMANAL · ${sheet.days.length} TREINOS',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: colorBlueLight,
                            letterSpacing: 3.5,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'FICHA\nDE\nTREINO',
                          style: pw.TextStyle(
                            font: fontBebas,
                            fontSize: 60,
                            color: PdfColors.white,
                            lineSpacing: 0.9,
                          ),
                        ),
                        pw.SizedBox(height: 15),
                        pw.Container(
                          width: 70,
                          height: 2,
                          color: colorBlueLight,
                        ),
                        pw.SizedBox(height: 12),
                        pw.Text(
                          'BIOMECHANICS & REHABILITATION',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: colorSteel,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ],
                    ),

                    // Card do Aluno (.cover-student-card) - Solução PDF-01 (Container Uniforme + Faixa Interna)
                    pw.Container(
                      width: 280,
                      decoration: pw.BoxDecoration(
                        color: colorCarbon2,
                        borderRadius: pw.BorderRadius.circular(12),
                        border: pw.Border.all(color: colorCarbon3, width: 1),
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          // Faixa Lateral Azul (PDF-01)
                          pw.Container(width: 4, color: colorBlueLight),
                          // Conteúdo Interno
                          pw.Expanded(
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.all(14),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                mainAxisSize: pw.MainAxisSize.min,
                                children: [
                                  pw.Text(
                                    sheet.studentName.toUpperCase(),
                                    style: pw.TextStyle(
                                      font: fontBebas,
                                      fontSize: 24,
                                      color: PdfColors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  pw.SizedBox(height: 8),
                                  pw.Row(
                                    children: [
                                      pw.Container(
                                        padding: const pw.EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: pw.BoxDecoration(
                                          color: colorCarbon3,
                                          borderRadius:
                                              pw.BorderRadius.circular(4),
                                        ),
                                        child: pw.Text(
                                          'NICHO: ${sheet.gymName}',
                                          style: pw.TextStyle(
                                            fontSize: 8,
                                            color: colorBlueLight,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      pw.SizedBox(width: 8),
                                      pw.Text(
                                        'DATA: ${sheet.month}',
                                        style: pw.TextStyle(
                                          fontSize: 8,
                                          color: colorSteel,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (sheet.instructorNotes.isNotEmpty) ...[
                                    pw.SizedBox(height: 8),
                                    pw.Divider(
                                      thickness: 0.5,
                                      color: colorMuted,
                                    ),
                                    pw.SizedBox(height: 4),
                                    pw.Text(
                                      'OBS: ${sheet.instructorNotes}',
                                      style: pw.TextStyle(
                                        fontSize: 8,
                                        color: colorSteelDim,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Pílulas dos Treinos (.cover-days)
                    pw.Row(
                      children: sheet.days.map((d) {
                        return pw.Container(
                          margin: const pw.EdgeInsets.only(right: 8),
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: pw.BoxDecoration(
                            color: colorBlueLight,
                            borderRadius: pw.BorderRadius.circular(999),
                          ),
                          child: pw.Text(
                            _getDayBadgeText(d.dow),
                            style: pw.TextStyle(
                              font: fontBebas,
                              fontSize: 11,
                              color: colorCarbon,
                              letterSpacing: 1.5,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // -------------------------------------------------------------
    // PAGE 2: INDEX PAGE (.index-page)
    // -------------------------------------------------------------
    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          int pageCounter = 3;

          return pw.Container(
            color: colorPaper,
            child: pw.Column(
              children: [
                // Day Header (.day-header)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  decoration: pw.BoxDecoration(
                    color: colorCarbon,
                    borderRadius: const pw.BorderRadius.only(
                      bottomLeft: pw.Radius.circular(26),
                      bottomRight: pw.Radius.circular(26),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          if (imgLogo != null)
                            pw.Image(imgLogo, height: 24)
                          else
                            pw.Text(
                              'VALEX',
                              style: pw.TextStyle(
                                font: fontBebas,
                                fontSize: 16,
                                color: colorBlueLight,
                              ),
                            ),
                          pw.Text(
                            'FICHA DE TREINO',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: colorSteel,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        'SUMÁRIO DO PROGRAMA',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: colorBlueLight,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Índice de Treinos',
                        style: pw.TextStyle(
                          font: fontBebas,
                          fontSize: 32,
                          color: PdfColors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Index Body (.day-body)
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(30),
                    child: pw.Column(
                      children: [
                        ...sheet.days.map((day) {
                          final badge = _getDayBadgeText(day.dow);
                          final pNum = pageCounter++;

                          return pw.Container(
                            margin: const pw.EdgeInsets.only(bottom: 10),
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: pw.BoxDecoration(
                              color: colorPaperCard,
                              borderRadius: pw.BorderRadius.circular(12),
                              border: pw.Border.all(color: colorLine),
                            ),
                            child: pw.Row(
                              children: [
                                pw.Container(
                                  width: 28,
                                  height: 28,
                                  alignment: pw.Alignment.center,
                                  decoration: pw.BoxDecoration(
                                    color: colorCarbon3,
                                    shape: pw.BoxShape.circle,
                                  ),
                                  child: pw.Text(
                                    badge,
                                    style: pw.TextStyle(
                                      font: fontBebas,
                                      fontSize: 12,
                                      color: colorBlueLight,
                                    ),
                                  ),
                                ),
                                pw.SizedBox(width: 12),
                                pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      '${day.dow} - ${day.muscle}'
                                          .toUpperCase(),
                                      style: pw.TextStyle(
                                        fontSize: 10,
                                        fontWeight: pw.FontWeight.bold,
                                        color: colorInk,
                                      ),
                                    ),
                                    pw.Text(
                                      '${day.exercises.length} exercícios',
                                      style: pw.TextStyle(
                                        fontSize: 8,
                                        color: colorMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                pw.Spacer(),
                                pw.Text(
                                  'Página $pNum',
                                  style: pw.TextStyle(
                                    font: fontBebas,
                                    fontSize: 14,
                                    color: colorBlue,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        // Cardio Index Item
                        pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 10),
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: pw.BoxDecoration(
                            color: colorPaperCard,
                            borderRadius: pw.BorderRadius.circular(12),
                            border: pw.Border.all(color: colorLine),
                          ),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: pw.BoxDecoration(
                                  color: colorCarbon3,
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Text(
                                  'CARDIO',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: colorBlueLight,
                                  ),
                                ),
                              ),
                              pw.SizedBox(width: 12),
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Protocolo de Cardio & Observações'
                                        .toUpperCase(),
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                      color: colorInk,
                                    ),
                                  ),
                                  pw.Text(
                                    'Orientações finais',
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      color: colorMuted,
                                    ),
                                  ),
                                ],
                              ),
                              pw.Spacer(),
                              pw.Text(
                                'Página $totalPages',
                                style: pw.TextStyle(
                                  font: fontBebas,
                                  fontSize: 14,
                                  color: colorBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer (.page-footer)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: colorLine)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'VALEX · BIOMECHANICS & REHABILITATION',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: colorMuted,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.Text(
                        'PÁGINA 2 DE $totalPages',
                        style: pw.TextStyle(
                          font: fontBebas,
                          fontSize: 10,
                          color: colorCarbon,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // -------------------------------------------------------------
    // PAGES 3+: DAY WORKOUT PAGES (.day-page)
    // -------------------------------------------------------------
    for (int dayIdx = 0; dayIdx < sheet.days.length; dayIdx++) {
      final day = sheet.days[dayIdx];
      final pageNo = 3 + dayIdx;

      pdf.addPage(
        pw.Page(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Container(
              color: colorPaper,
              child: pw.Column(
                children: [
                  // Day Header (.day-header)
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 16,
                    ),
                    decoration: pw.BoxDecoration(
                      gradient: pw.RadialGradient(
                        center: const pw.FractionalOffset(0.90, -0.10),
                        radius: 0.55,
                        colors: [
                          PdfColor(47 / 255, 143 / 255, 230 / 255, 0.35),
                          colorCarbon,
                        ],
                        stops: [0.0, 0.55],
                      ),
                      borderRadius: const pw.BorderRadius.only(
                        bottomLeft: pw.Radius.circular(26),
                        bottomRight: pw.Radius.circular(26),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            if (imgLogo != null)
                              pw.Image(imgLogo, height: 22)
                            else
                              pw.Text(
                                'VALEX',
                                style: pw.TextStyle(
                                  font: fontBebas,
                                  fontSize: 16,
                                  color: colorBlueLight,
                                ),
                              ),
                            pw.Text(
                              'FICHA DE TREINO',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: colorSteel,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 10),
                        pw.Row(
                          children: [
                            pw.Container(
                              width: 38,
                              height: 38,
                              alignment: pw.Alignment.center,
                              decoration: pw.BoxDecoration(
                                gradient: pw.LinearGradient(
                                  colors: [
                                    colorBlue,
                                    PdfColor.fromHex('#1a5fa3'),
                                  ],
                                  begin: pw.Alignment.topLeft,
                                  end: pw.Alignment.bottomRight,
                                ),
                                shape: pw.BoxShape.circle,
                              ),
                              child: pw.Text(
                                _getDayBadgeText(day.dow),
                                style: pw.TextStyle(
                                  font: fontBebas,
                                  fontSize: 18,
                                  color: PdfColors.white,
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 14),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  day.dow.toUpperCase(),
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: colorBlueLight,
                                    letterSpacing: 2,
                                  ),
                                ),
                                pw.Text(
                                  day.muscle.toUpperCase(),
                                  style: pw.TextStyle(
                                    font: fontBebas,
                                    fontSize: 28,
                                    color: PdfColors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Day Body (.day-body)
                  pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(24),
                      child: pw.Column(
                        children: [
                          ...day.exercises.asMap().entries.map((exEntry) {
                            final exIdx = exEntry.key;
                            final ex = exEntry.value;

                            return pw.Container(
                              margin: const pw.EdgeInsets.only(bottom: 8),
                              padding: const pw.EdgeInsets.all(10),
                              decoration: pw.BoxDecoration(
                                color: colorPaperCard,
                                borderRadius: pw.BorderRadius.circular(12),
                                border: pw.Border.all(color: colorLine),
                              ),
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  // Exercise Number (.ex-num)
                                  pw.Container(
                                    width: 22,
                                    height: 22,
                                    alignment: pw.Alignment.center,
                                    decoration: pw.BoxDecoration(
                                      gradient: pw.LinearGradient(
                                        colors: [colorCarbon3, colorCarbon],
                                        begin: pw.Alignment.topLeft,
                                        end: pw.Alignment.bottomRight,
                                      ),
                                      shape: pw.BoxShape.circle,
                                    ),
                                    child: pw.Text(
                                      (exIdx + 1).toString().padLeft(2, '0'),
                                      style: pw.TextStyle(
                                        font: fontBebas,
                                        fontSize: 11,
                                        color: colorBlueLight,
                                      ),
                                    ),
                                  ),
                                  pw.SizedBox(width: 10),
                                  pw.Expanded(
                                    child: pw.Column(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Row(
                                          mainAxisAlignment:
                                              pw.MainAxisAlignment.spaceBetween,
                                          children: [
                                            pw.Text(
                                              ex.title.toUpperCase(),
                                              style: pw.TextStyle(
                                                fontSize: 10,
                                                fontWeight: pw.FontWeight.bold,
                                                color: colorInk,
                                              ),
                                            ),
                                            if (ex.loadKg.isNotEmpty)
                                              pw.Container(
                                                padding:
                                                    const pw.EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: pw.BoxDecoration(
                                                  color: PdfColors.grey200,
                                                  borderRadius: pw
                                                      .BorderRadius.circular(4),
                                                ),
                                                child: pw.Text(
                                                  'CARGA: ${ex.loadKg} kg',
                                                  style: pw.TextStyle(
                                                    fontSize: 8,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                    color: colorInk,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (ex.cue.isNotEmpty) ...[
                                          pw.SizedBox(height: 2),
                                          pw.Text(
                                            ex.cue,
                                            style: pw.TextStyle(
                                              fontSize: 8,
                                              fontStyle: pw.FontStyle.italic,
                                              color: colorMuted,
                                            ),
                                          ),
                                        ],
                                        pw.SizedBox(height: 6),
                                        // Set rows with colored left borders (.set-row t-warmup, t-prep, t-work)
                                        pw.Column(
                                          children: ex.sets.map((s) {
                                            final parsed = _splitSetLine(s);
                                            final setType = _getSetType(
                                              parsed['label']!,
                                              parsed['typeOverride']!,
                                            );
                                            final finalLoadText =
                                                resolvePrescriptionLoad(
                                                  ex.loadKg,
                                                  parsed['setLoad']!,
                                                  parsed['desc']!,
                                                );

                                            PdfColor borderColor;
                                            PdfColor tagColor;
                                            if (setType == 'warmup') {
                                              borderColor = PdfColor.fromHex(
                                                '#c7cdd4',
                                              );
                                              tagColor = PdfColor.fromHex(
                                                '#8a94a0',
                                              );
                                            } else if (setType == 'prep') {
                                              borderColor = PdfColor.fromHex(
                                                '#c9a24d',
                                              );
                                              tagColor = PdfColor.fromHex(
                                                '#a5822f',
                                              );
                                            } else {
                                              borderColor = colorBlue;
                                              tagColor = PdfColor.fromHex(
                                                '#1f6fbf',
                                              );
                                            }

                                            return pw.Container(
                                              margin: const pw.EdgeInsets.only(
                                                bottom: 3,
                                              ),
                                              padding: const pw.EdgeInsets.only(
                                                left: 6,
                                                top: 2,
                                                bottom: 2,
                                              ),
                                              decoration: pw.BoxDecoration(
                                                border: pw.Border(
                                                  left: pw.BorderSide(
                                                    color: borderColor,
                                                    width: 2.5,
                                                  ),
                                                ),
                                              ),
                                              child: pw.Row(
                                                crossAxisAlignment:
                                                    pw.CrossAxisAlignment.start,
                                                children: [
                                                  if (parsed['label']!
                                                      .isNotEmpty)
                                                    pw.Text(
                                                      '${parsed['label']!}: ',
                                                      style: pw.TextStyle(
                                                        fontSize: 8,
                                                        fontWeight:
                                                            pw.FontWeight.bold,
                                                        color: tagColor,
                                                      ),
                                                    ),
                                                  pw.Expanded(
                                                    child: pw.Text(
                                                      parsed['desc']!,
                                                      style: pw.TextStyle(
                                                        fontSize: 8,
                                                        color: PdfColor.fromHex(
                                                          '#3a4048',
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  if (finalLoadText.isNotEmpty)
                                                    pw.Container(
                                                      margin:
                                                          const pw.EdgeInsets.only(
                                                            left: 4,
                                                          ),
                                                      padding:
                                                          const pw.EdgeInsets.symmetric(
                                                            horizontal: 5,
                                                            vertical: 1,
                                                          ),
                                                      decoration: pw.BoxDecoration(
                                                        color: PdfColor(
                                                          47 / 255,
                                                          143 / 255,
                                                          230 / 255,
                                                          0.12,
                                                        ),
                                                        border: pw.Border.all(
                                                          color: PdfColor(
                                                            47 / 255,
                                                            143 / 255,
                                                            230 / 255,
                                                            0.25,
                                                          ),
                                                          width: 1,
                                                        ),
                                                        borderRadius:
                                                            pw.BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: pw.Text(
                                                        finalLoadText,
                                                        style: pw.TextStyle(
                                                          fontSize: 7.5,
                                                          fontWeight: pw
                                                              .FontWeight
                                                              .bold,
                                                          color: colorBlue,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          pw.Spacer(),

                          if (day.cardio) ...[
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: pw.BoxDecoration(
                                color: colorCarbon,
                                borderRadius: pw.BorderRadius.circular(999),
                              ),
                              child: pw.Row(
                                mainAxisSize: pw.MainAxisSize.min,
                                children: [
                                  pw.Text(
                                    'Finalizar com protocolo de ',
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      color: PdfColors.white,
                                    ),
                                  ),
                                  pw.Text(
                                    'Cardio',
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                      color: colorBlueLight,
                                    ),
                                  ),
                                  pw.Text(
                                    ' - ver pág $totalPages',
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      color: PdfColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Footer (.page-footer)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(color: colorLine)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'VALEX · BIOMECHANICS & REHABILITATION',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: colorMuted,
                            letterSpacing: 1,
                          ),
                        ),
                        pw.Text(
                          'PÁGINA $pageNo DE $totalPages',
                          style: pw.TextStyle(
                            font: fontBebas,
                            fontSize: 10,
                            color: colorCarbon,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // -------------------------------------------------------------
    // FINAL PAGE: CARDIO PAGE (.cardio-page)
    // -------------------------------------------------------------
    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Container(
            color: colorPaper,
            child: pw.Column(
              children: [
                // Day Header (.day-header)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 16,
                  ),
                  decoration: pw.BoxDecoration(
                    color: colorCarbon,
                    borderRadius: const pw.BorderRadius.only(
                      bottomLeft: pw.Radius.circular(26),
                      bottomRight: pw.Radius.circular(26),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          if (imgLogo != null)
                            pw.Image(imgLogo, height: 22)
                          else
                            pw.Text(
                              'VALEX',
                              style: pw.TextStyle(
                                font: fontBebas,
                                fontSize: 16,
                                color: colorBlueLight,
                              ),
                            ),
                          pw.Text(
                            'FICHA DE TREINO',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: colorSteel,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: pw.BoxDecoration(
                              color: colorBlue,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              'CARDIO',
                              style: pw.TextStyle(
                                font: fontBebas,
                                fontSize: 14,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 14),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'TODOS OS DIAS',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: colorBlueLight,
                                  letterSpacing: 2,
                                ),
                              ),
                              pw.Text(
                                'Protocolo de Cardio',
                                style: pw.TextStyle(
                                  font: fontBebas,
                                  fontSize: 28,
                                  color: PdfColors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Body
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(24),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Cardio Options Cards (.cardio-card)
                        pw.Row(
                          children: sheet.cardioOptions.map((c) {
                            return pw.Expanded(
                              child: pw.Container(
                                margin: const pw.EdgeInsets.only(right: 8),
                                padding: const pw.EdgeInsets.all(12),
                                decoration: pw.BoxDecoration(
                                  color: colorPaperCard,
                                  borderRadius: pw.BorderRadius.circular(12),
                                  border: pw.Border.all(color: colorLine),
                                ),
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Container(
                                      padding: const pw.EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: pw.BoxDecoration(
                                        color: colorBlue,
                                        borderRadius: pw.BorderRadius.circular(
                                          4,
                                        ),
                                      ),
                                      child: pw.Text(
                                        'AERÓBICO',
                                        style: pw.TextStyle(
                                          fontSize: 8,
                                          fontWeight: pw.FontWeight.bold,
                                          color: PdfColors.white,
                                        ),
                                      ),
                                    ),
                                    pw.SizedBox(height: 8),
                                    pw.Text(
                                      c,
                                      style: pw.TextStyle(
                                        fontSize: 10,
                                        fontWeight: pw.FontWeight.bold,
                                        color: colorInk,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        pw.SizedBox(height: 16),

                        // Observações Box (.obs-box)
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(16),
                          decoration: pw.BoxDecoration(
                            color: colorCarbon,
                            borderRadius: pw.BorderRadius.circular(16),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'OBSERVAÇÕES',
                                style: pw.TextStyle(
                                  font: fontBebas,
                                  fontSize: 20,
                                  color: colorBlueLight,
                                  letterSpacing: 1,
                                ),
                              ),
                              pw.SizedBox(height: 8),
                              ...sheet.generalNotes.map((obs) {
                                return pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 6),
                                  child: pw.Row(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Container(
                                        width: 14,
                                        height: 14,
                                        alignment: pw.Alignment.center,
                                        decoration: pw.BoxDecoration(
                                          color: colorCarbon3,
                                          shape: pw.BoxShape.circle,
                                        ),
                                        child: pw.Container(
                                          width: 4,
                                          height: 4,
                                          decoration: pw.BoxDecoration(
                                            color: colorBlueLight,
                                            shape: pw.BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      pw.SizedBox(width: 8),
                                      pw.Expanded(
                                        child: pw.Text(
                                          obs,
                                          style: pw.TextStyle(
                                            fontSize: 9,
                                            color: PdfColors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer (.page-footer)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: colorLine)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'VALEX · BIOMECHANICS & REHABILITATION',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: colorMuted,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.Text(
                        'PÁGINA $totalPages DE $totalPages',
                        style: pw.TextStyle(
                          font: fontBebas,
                          fontSize: 10,
                          color: colorCarbon,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateBatchWorkoutPdf(
    List<WorkoutSheet> sheets,
  ) async {
    final pdf = pw.Document();
    for (var sheet in sheets) {
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Center(
            child: pw.Text('Ficha de Treino - ${sheet.studentName}'),
          ),
        ),
      );
    }
    return pdf.save();
  }
}
