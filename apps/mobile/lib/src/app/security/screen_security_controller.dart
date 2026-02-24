part of '../../../main.dart';

class ScreenSecurityController extends ChangeNotifier
    with WidgetsBindingObserver {
  static const _events = EventChannel('app_creditos/screen_security_events');

  bool _screenCaptured = false;
  bool _backgroundObscured = false;
  bool _flashOverlay = false;
  StreamSubscription<dynamic>? _sub;
  Timer? _flashTimer;
  String? lastWarning;

  bool get shouldObscure =>
      _screenCaptured || _backgroundObscured || _flashOverlay;

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    if (!Platform.isIOS) return;
    try {
      _sub = _events.receiveBroadcastStream().listen(_handleEvent);
    } on MissingPluginException {
      // Ignored on unsupported platforms.
    }
  }

  void _handleEvent(dynamic raw) {
    if (raw is! Map) return;
    final type = raw['type']?.toString();
    if (type == 'capture_state') {
      _screenCaptured = raw['isCaptured'] == true;
      if (_screenCaptured) {
        lastWarning =
            'Grabación/captura de pantalla detectada. Contenido oculto.';
      }
      notifyListeners();
      return;
    }
    if (type == 'screenshot') {
      lastWarning = 'Capturas de pantalla no permitidas.';
      _flashOverlay = true;
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(seconds: 2), () {
        _flashOverlay = false;
        notifyListeners();
      });
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _backgroundObscured = state != AppLifecycleState.resumed;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }
}
