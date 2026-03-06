part of '../../../../main.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({
    super.key,
    required this.api,
    required this.currentUserId,
  });
  final ApiClient api;
  final int currentUserId;

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await widget.api.ranking();
      if (mounted) {
        setState(() => _rows = rows);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _rows.indexWhere(
      (r) => r['userId'] == widget.currentUserId,
    );
    final current = currentIndex >= 0 ? _rows[currentIndex] : null;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: [
          FadeSlideIn(
            delay: const Duration(milliseconds: 50),
            child: SoftGlassCard(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Competencia activa',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFEE8D00),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ranking Global',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF0E2435),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Compite por el primer lugar completando retos.',
                    style: TextStyle(color: Color(0xFF5D7287)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SummaryChip(
                        icon: Icons.people_outline,
                        label: 'participantes',
                        value: _loading ? '...' : '${_rows.length}',
                      ),
                      const SummaryChip(
                        icon: Icons.auto_awesome,
                        label: 'ranking',
                        value: 'Live',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_error != null)
            InlineStatusCard(
              message: _error!,
              icon: Icons.error_outline,
              color: Colors.red,
              action: _load,
              actionLabel: 'Reintentar',
            )
          else if (_rows.isEmpty)
            InlineStatusCard(
              message: 'Aún no hay submissions completadas.',
              icon: Icons.hourglass_empty,
              color: Theme.of(context).colorScheme.secondary,
            )
          else ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: _CurrentUserCard(
                row: current,
                position: currentIndex >= 0 ? currentIndex + 1 : null,
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 110),
              child: Text(
                'Podio',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF071A29),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            FadeSlideIn(
              delay: const Duration(milliseconds: 130),
              child: _Podium(topRows: _rows.take(3).toList()),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 150),
              child: Row(
                children: [
                  Text(
                    'Clasificación',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF071A29),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Pos. ${currentIndex + 1}',
                    style: const TextStyle(color: Color(0xFF7F8FA3)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ..._rows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              return FadeSlideIn(
                delay: Duration(milliseconds: 180 + (index * 30)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RankingRow(
                    row: row,
                    position: index + 1,
                    isCurrentUser: row['userId'] == widget.currentUserId,
                  ),
                ),
              );
            }),
            const SizedBox(height: 6),
            const SoftGlassCard(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFF027AA4),
                    child: Icon(Icons.trending_up, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sigue subiendo',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF122B3D),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Completa más retos para ganar puntos',
                          style: TextStyle(color: Color(0xFF5E7287)),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.adjust, color: Color(0xFF48B539)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CurrentUserCard extends StatelessWidget {
  const _CurrentUserCard({required this.row, required this.position});

  final Map<String, dynamic>? row;
  final int? position;

  @override
  Widget build(BuildContext context) {
    if (row == null) {
      return const InlineStatusCard(
        message: 'Aún no apareces en el ranking. Completa tu primer reto.',
        icon: Icons.info_outline,
        color: Color(0xFF126BA7),
      );
    }

    return SoftGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9CA8), Color(0xFF57B63F)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _initials(row?['name']?.toString()),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu posición actual',
                  style: TextStyle(color: Color(0xFF73859A)),
                ),
                Text(
                  row?['name']?.toString() ?? 'Usuario',
                  style: const TextStyle(
                    fontSize: 31 / 1.45,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F2535),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '⭐ ${row?['points']} pts',
                  style: const TextStyle(
                    color: Color(0xFF0F2535),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Posición',
                style: TextStyle(color: Color(0xFF77899E)),
              ),
              Text(
                position != null ? '#$position' : '--',
                style: const TextStyle(
                  color: Color(0xFF0491AB),
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _initials(String? fullName) {
    final words = (fullName ?? '').trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return 'DU';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.topRows});

  final List<Map<String, dynamic>> topRows;

  @override
  Widget build(BuildContext context) {
    final second = topRows.length > 1 ? topRows[1] : null;
    final first = topRows.isNotEmpty ? topRows[0] : null;
    final third = topRows.length > 2 ? topRows[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumItem(row: second, place: 2)),
        Expanded(child: _PodiumItem(row: first, place: 1, highlighted: true)),
        Expanded(child: _PodiumItem(row: third, place: 3)),
      ],
    );
  }
}

class _PodiumItem extends StatelessWidget {
  const _PodiumItem({
    required this.row,
    required this.place,
    this.highlighted = false,
  });

  final Map<String, dynamic>? row;
  final int place;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: highlighted ? 74 : 62,
          height: highlighted ? 74 : 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlighted
                ? const Color(0xFFF2A400)
                : const Color(0xFF738BA5),
            border: Border.all(
              color: highlighted ? const Color(0xFFFFD86E) : Colors.transparent,
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              _badgeLabel(row, place),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -8),
          child: CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white,
            child: Text(
              '$place',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        SoftGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            children: [
              Text(
                row?['name']?.toString().split(' ').first ?? '--',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF102B3D),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${row?['points'] ?? 0} pts',
                style: TextStyle(
                  color: highlighted
                      ? const Color(0xFFC66D00)
                      : const Color(0xFF607386),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _badgeLabel(Map<String, dynamic>? row, int place) {
    if (row == null) return '--';
    final name = row['name']?.toString() ?? '';
    final token = name.trim().split(RegExp(r'\s+')).firstOrNull ?? '';
    if (token.length < 2) return 'P$place';
    return token.substring(0, 2).toUpperCase();
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.row,
    required this.position,
    required this.isCurrentUser,
  });

  final Map<String, dynamic> row;
  final int position;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return SoftGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$position',
              style: const TextStyle(
                color: Color(0xFF5F7388),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          CircleAvatar(
            radius: 19,
            backgroundColor: isCurrentUser
                ? const Color(0xFF37AF66)
                : const Color(0xFF123B64),
            child: Text(
              _initials(row['name']?.toString()),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentUser
                      ? '${row['name']} (Tú)'
                      : row['name']?.toString() ?? 'Usuario',
                  style: const TextStyle(
                    color: Color(0xFF0F2738),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${row['completedChallenges']} retos  ·  ${row['evidences']} ev.',
                  style: const TextStyle(
                    color: Color(0xFF6C8095),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '⭐ ${row['points']}',
            style: const TextStyle(
              color: Color(0xFF0F2738),
              fontWeight: FontWeight.w800,
              fontSize: 22 / 1.2,
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String? fullName) {
    final words = (fullName ?? '').trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return 'NA';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
