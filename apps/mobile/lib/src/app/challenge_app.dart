part of '../../main.dart';

class ChallengeApp extends StatefulWidget {
  const ChallengeApp({super.key});

  @override
  State<ChallengeApp> createState() => _ChallengeAppState();
}

class _ChallengeAppState extends State<ChallengeApp> {
  static const _secureStorage = FlutterSecureStorage();
  final ScreenSecurityController _security = ScreenSecurityController();
  final OfflineAppController _offline = OfflineAppController.instance;

  AuthSession? _session;
  final String _baseUrl = _defaultBaseUrl();
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  static String _defaultBaseUrl() {
    final envUrl = dotenv.env['API_BASE_URL']?.trim();
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  Future<void> _restore() async {
    await _security.initialize();
    await _offline.initialize(baseUrl: _baseUrl);
    final savedSession = await _secureStorage.read(key: 'auth_session');
    if (savedSession != null) {
      try {
        _session = AuthSession.fromJson(
          jsonDecode(savedSession) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    _offline.updateSession(_session);
    if (mounted) setState(() => _booting = false);
  }

  Future<void> _saveSession(AuthSession? session) async {
    _session = session;
    if (session == null) {
      await _secureStorage.delete(key: 'auth_session');
    } else {
      await _secureStorage.write(
        key: 'auth_session',
        value: jsonEncode(session.toJson()),
      );
    }
    _offline.updateSession(session);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _offline.dispose();
    _security.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _security,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Retos Fotográficos',
          home: _booting
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : (_session == null
                    ? AuthScreen(
                        baseUrl: _baseUrl,
                        onAuthenticated: _saveSession,
                      )
                    : HomeScreen(
                        baseUrl: _baseUrl,
                        session: _session!,
                        onSessionUpdated: _saveSession,
                        onLogout: () => _saveSession(null),
                      )),
        );
      },
    );
  }
}
