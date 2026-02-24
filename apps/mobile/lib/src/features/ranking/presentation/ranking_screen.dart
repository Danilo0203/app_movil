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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FadeSlideIn(
            delay: const Duration(milliseconds: 40),
            child: SoftGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ranking global',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Puntaje por retos completados y cantidad de evidencias válidas.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SummaryChip(
                        icon: Icons.groups_outlined,
                        label: 'participantes',
                        value: _loading ? '...' : '${_rows.length}',
                      ),
                      const SummaryChip(
                        icon: Icons.emoji_events_outlined,
                        label: 'ranking',
                        value: 'Live',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
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
          else
            ..._rows.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final row = entry.value;
              final isCurrentUser = row['userId'] == widget.currentUserId;
              final medal = switch (idx) {
                1 => '🥇',
                2 => '🥈',
                3 => '🥉',
                _ => '#$idx',
              };
              return FadeSlideIn(
                delay: Duration(milliseconds: 90 + (entry.key * 40)),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: isCurrentUser
                      ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.95),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(medal)),
                    title: Text(row['name']?.toString() ?? 'Usuario'),
                    subtitle: Text(
                      'Retos: ${row['completedChallenges']} | Evidencias: ${row['evidences']}',
                    ),
                    trailing: Text(
                      '${row['points']} pts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
