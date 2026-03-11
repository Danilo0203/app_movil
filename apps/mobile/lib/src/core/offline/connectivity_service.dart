part of '../../../main.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _hasConnection = true;
  bool _isBackendReachable = false;

  bool get hasConnection => _hasConnection;
  bool get isBackendReachable => _isBackendReachable;
  bool get isOnline => _hasConnection && _isBackendReachable;

  Future<void> initialize(String baseUrl) async {
    final results = await _connectivity.checkConnectivity();
    _hasConnection = results.any((item) => item != ConnectivityResult.none);
    _isBackendReachable = await _probeBackend(baseUrl);
    notifyListeners();
    _subscription ??= _connectivity.onConnectivityChanged.listen((
      results,
    ) async {
      _hasConnection = results.any((item) => item != ConnectivityResult.none);
      _isBackendReachable = await _probeBackend(baseUrl);
      notifyListeners();
    });
  }

  Future<void> refresh(String baseUrl, {bool notify = true}) async {
    _isBackendReachable = await _probeBackend(baseUrl);
    if (notify) {
      notifyListeners();
    }
  }

  Future<bool> _probeBackend(String baseUrl) async {
    if (!_hasConnection) return false;
    try {
      await ApiClient(baseUrl: baseUrl).healthCheck();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
