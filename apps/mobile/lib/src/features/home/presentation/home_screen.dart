part of '../../../../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.baseUrl,
    required this.session,
    required this.onSessionUpdated,
    required this.onLogout,
  });

  final String baseUrl;
  final AuthSession session;
  final Future<void> Function(AuthSession session) onSessionUpdated;
  final VoidCallback onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final api = ApiClient(
      baseUrl: widget.baseUrl,
      token: widget.session.accessToken,
    );
    final offline = OfflineAppController.instance;
    final pages = [
      ChallengesScreen(session: widget.session, api: api),
      RankingScreen(api: api, currentUserId: widget.session.userId),
      ProfileScreen(
        session: widget.session,
        api: api,
        onSessionUpdated: widget.onSessionUpdated,
        onLogout: widget.onLogout,
      ),
    ];

    return AnimatedBuilder(
      animation: offline,
      builder: (context, _) => Scaffold(
        body: AppShell(
          child: SafeArea(
            child: Column(
              children: [
                _SyncBanner(offline: offline),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey(_index),
                      child: pages[_index],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (v) => setState(() => _index = v),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.flag), label: 'Retos'),
            NavigationDestination(
              icon: Icon(Icons.leaderboard),
              label: 'Ranking',
            ),
            NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.offline});

  final OfflineAppController offline;

  @override
  Widget build(BuildContext context) {
    final color = offline.isOnline
        ? const Color(0xFFDFF5E2)
        : const Color(0xFFFFE6CC);
    final textColor = offline.isOnline
        ? const Color(0xFF2F8F44)
        : const Color(0xFFAD6A00);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            offline.isOnline
                ? Icons.cloud_done_outlined
                : Icons.cloud_off_outlined,
            color: textColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              offline.isOnline
                  ? (offline.isSyncing
                        ? 'Sincronizando cambios pendientes...'
                        : 'Conectado. ${offline.pendingCount} pendientes.')
                  : 'Sin conexión. ${offline.pendingCount} cambios guardados localmente.',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
