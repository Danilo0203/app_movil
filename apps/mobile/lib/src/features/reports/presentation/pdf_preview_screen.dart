part of '../../../../main.dart';

class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.filePath,
  });
  final Uint8List pdfBytes;
  final String filePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF generado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Printing.sharePdf(
              bytes: pdfBytes,
              filename: p.basename(filePath),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          MaterialBanner(
            content: Text('Archivo guardado temporalmente en: $filePath'),
            actions: [
              TextButton(
                onPressed: () =>
                    Printing.layoutPdf(onLayout: (_) async => pdfBytes),
                child: const Text('Imprimir'),
              ),
            ],
          ),
          Expanded(
            child: PdfPreview(
              build: (_) async => pdfBytes,
              canChangePageFormat: false,
              canDebug: false,
              canChangeOrientation: false,
            ),
          ),
        ],
      ),
    );
  }
}
