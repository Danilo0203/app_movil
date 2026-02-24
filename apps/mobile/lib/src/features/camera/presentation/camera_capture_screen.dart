part of '../../../../main.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key, required this.itemLabel});
  final String itemLabel;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final permission = await Permission.camera.request();
      if (!permission.isGranted) {
        throw Exception('Permiso de cámara denegado');
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No se encontró cámara disponible');
      }
      final preferred = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        preferred,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final raw = await controller.takePicture();
      final compressed = await _compressImage(File(raw.path));
      if (!mounted) return;
      Navigator.of(context).pop(compressed);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Capturar: ${widget.itemLabel}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : Column(
              children: [
                Expanded(child: CameraPreview(_controller!)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera),
                    label: const Text('Tomar foto'),
                  ),
                ),
              ],
            ),
    );
  }
}

Future<File> _compressImage(File input) async {
  final bytes = await input.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return input;

  final resized = decoded.width > 1600
      ? img.copyResize(decoded, width: 1600)
      : decoded;
  final encoded = img.encodeJpg(resized, quality: 78);
  final tempDir = await getTemporaryDirectory();
  final out = File(
    p.join(
      tempDir.path,
      'evidence_${DateTime.now().millisecondsSinceEpoch}.jpg',
    ),
  );
  await out.writeAsBytes(encoded, flush: true);
  return out;
}
