part of '../../main.dart';

class ChallengeApp extends StatefulWidget {
  const ChallengeApp({super.key});

  @override
  State<ChallengeApp> createState() => _ChallengeAppState();
}

class _ChallengeAppState extends State<ChallengeApp> {
  static const _secureStorage = FlutterSecureStorage();
  static const _apiBaseUrlFromDefine = String.fromEnvironment('API_BASE_URL');
  final ScreenSecurityController _security = ScreenSecurityController();

  AuthSession? _session;
  final String _baseUrl = _defaultBaseUrl();
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  static String _defaultBaseUrl() {
    if (_apiBaseUrlFromDefine.isNotEmpty) return _apiBaseUrlFromDefine;
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  Future<void> _restore() async {
    await _security.initialize();
    final savedSession = await _secureStorage.read(key: 'auth_session');
    if (savedSession != null) {
      try {
        _session = AuthSession.fromJson(
          jsonDecode(savedSession) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
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
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
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
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0097B0),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFE9F2F4),
            fontFamily: 'SF Pro Text',
            cardTheme: CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: Color(0xFFD6E4E9)),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: Color(0xFF0E2433),
              centerTitle: false,
            ),
            navigationBarTheme: NavigationBarThemeData(
              height: 76,
              backgroundColor: Colors.white.withValues(alpha: 0.97),
              indicatorColor: const Color(0xFF00A4B8).withValues(alpha: 0.14),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                return TextStyle(
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: states.contains(WidgetState.selected)
                      ? const Color(0xFF008FA6)
                      : const Color(0xFF5C6F85),
                );
              }),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF045C94),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            iconButtonTheme: IconButtonThemeData(
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF7FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFCFE0E6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFCFE0E6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFF0097B0),
                  width: 1.5,
                ),
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          home: Stack(
            children: [
              if (_booting)
                const Scaffold(body: Center(child: CircularProgressIndicator()))
              else if (_session == null)
                AuthScreen(baseUrl: _baseUrl, onAuthenticated: _saveSession)
              else
                HomeScreen(
                  baseUrl: _baseUrl,
                  session: _session!,
                  onSessionUpdated: _saveSession,
                  onLogout: () => _saveSession(null),
                ),
              if (_security.shouldObscure)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: Text(
                        _security.lastWarning ?? 'Contenido protegido',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
