part of '../../main.dart';

class ChallengeApp extends StatefulWidget {
  const ChallengeApp({super.key});

  @override
  State<ChallengeApp> createState() => _ChallengeAppState();
}

class _ChallengeAppState extends State<ChallengeApp> {
  static const _secureStorage = FlutterSecureStorage();
  final ScreenSecurityController _security = ScreenSecurityController();

  AuthSession? _session;
  String _baseUrl = _defaultBaseUrl();
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  static String _defaultBaseUrl() {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  Future<void> _restore() async {
    await _security.initialize();
    final savedSession = await _secureStorage.read(key: 'auth_session');
    final savedBase = await _secureStorage.read(key: 'api_base_url');
    if (savedBase != null && savedBase.isNotEmpty) _baseUrl = savedBase;
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

  Future<void> _saveBaseUrl(String baseUrl) async {
    _baseUrl = baseUrl;
    await _secureStorage.write(key: 'api_base_url', value: baseUrl);
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
              seedColor: const Color(0xFF0B6E6E),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF3F7F8),
            fontFamily: 'SF Pro Text',
            cardTheme: CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: Color(0xFFE3EAED)),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: Color(0xFF11252A),
              centerTitle: false,
            ),
            navigationBarTheme: NavigationBarThemeData(
              height: 72,
              backgroundColor: Colors.white.withValues(alpha: 0.95),
              indicatorColor: const Color(0xFF0B6E6E).withValues(alpha: 0.12),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                return TextStyle(
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: states.contains(WidgetState.selected)
                      ? const Color(0xFF0B6E6E)
                      : const Color(0xFF42565E),
                );
              }),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0A6B79),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
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
              fillColor: const Color(0xFFF9FBFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFD9E3E8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFD9E3E8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF0B6E6E),
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
                AuthScreen(
                  baseUrl: _baseUrl,
                  onBaseUrlChanged: _saveBaseUrl,
                  onAuthenticated: _saveSession,
                )
              else
                HomeScreen(
                  baseUrl: _baseUrl,
                  session: _session!,
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
