part of '../../../../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.baseUrl,
    required this.session,
    required this.onLogout,
  });

  final String baseUrl;
  final AuthSession session;
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
    final pages = [
      ChallengesScreen(session: widget.session, api: api),
      RankingScreen(api: api, currentUserId: widget.session.userId),
      ProfileScreen(session: widget.session, onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: AppShell(
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
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
    );
  }
}
