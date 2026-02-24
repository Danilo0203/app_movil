part of '../../../../main.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key, required this.session, required this.api});
  final AuthSession session;
  final ApiClient api;

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  bool _loading = true;
  String? _error;
  List<ChallengeModel> _challenges = const [];

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
      var list = await widget.api.listChallenges();
      if (list.isEmpty) {
        await widget.api.seedChallenges();
        list = await widget.api.listChallenges();
      }
      if (mounted) {
        setState(() => _challenges = list);
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
                    'Hola, ${widget.session.userName}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Selecciona un reto y captura evidencias con una experiencia guiada.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF51666F),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SummaryChip(
                        icon: Icons.flag_outlined,
                        label: 'retos',
                        value: _loading ? '...' : '${_challenges.length}',
                      ),
                      const SummaryChip(
                        icon: Icons.security_outlined,
                        label: 'protegido',
                        value: 'Modo',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
          else if (_challenges.isEmpty)
            InlineStatusCard(
              message: 'No hay retos disponibles todavía.',
              icon: Icons.inbox_outlined,
              color: Theme.of(context).colorScheme.secondary,
              action: _load,
              actionLabel: 'Actualizar',
            )
          else
            ..._challenges.asMap().entries.map((entry) {
              final index = entry.key;
              final challenge = entry.value;
              void open() {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChallengeRunScreen(
                      api: widget.api,
                      session: widget.session,
                      challenge: challenge,
                    ),
                  ),
                );
              }

              return FadeSlideIn(
                delay: Duration(milliseconds: 90 + (index * 40)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: open,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: challenge.type
                                    .color(context)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                challenge.type.icon,
                                color: challenge.type.color(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    challenge.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _PillLabel(
                                        text: challenge.type.shortLabel,
                                        color: challenge.type.color(context),
                                      ),
                                      _PillLabel(
                                        text:
                                            '${challenge.items.length} evidencias',
                                        color: const Color(0xFF5A707A),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              onPressed: open,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
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
