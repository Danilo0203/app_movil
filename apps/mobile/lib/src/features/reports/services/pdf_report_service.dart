part of '../../../../main.dart';

class PdfReportService {
  static Future<Uint8List> buildReport({
    required ChallengeModel challenge,
    required String userName,
    required String userEmail,
    required Map<String, File> evidenceFiles,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final title = switch (challenge.type) {
      ChallengeType.mystery => 'Reporte de hallazgos',
      ChallengeType.officeSafari => 'Safari completado',
      ChallengeType.technicalInspector => 'Reporte profesional',
    };

    final imageWidgets = <pw.Widget>[];
    for (final item in challenge.items) {
      final file = evidenceFiles[item.code];
      if (file == null) {
        imageWidgets.add(
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            margin: const pw.EdgeInsets.only(bottom: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
            ),
            child: pw.Text('${item.label}: pendiente'),
          ),
        );
        continue;
      }
      final imageBytes = await file.readAsBytes();
      imageWidgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                item.label,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Image(
                pw.MemoryImage(imageBytes),
                fit: pw.BoxFit.contain,
                height: 180,
              ),
              pw.SizedBox(height: 4),
              pw.Text('Archivo: ${p.basename(file.path)}'),
            ],
          ),
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Reto: ${challenge.title}'),
          pw.Text('Usuario: $userName <$userEmail>'),
          pw.Text('Fecha: ${DateFormat('yyyy-MM-dd HH:mm').format(now)}'),
          pw.Text('ID de sesión: ${now.millisecondsSinceEpoch}'),
          pw.SizedBox(height: 12),
          pw.Text('Checklist'),
          pw.SizedBox(height: 6),
          ...challenge.items.map(
            (item) => pw.Bullet(
              text:
                  '${evidenceFiles.containsKey(item.code) ? '✓' : '•'} ${item.label}',
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Evidencias', style: pw.TextStyle(fontSize: 16)),
          pw.SizedBox(height: 8),
          ...imageWidgets,
        ],
      ),
    );

    return doc.save();
  }
}
