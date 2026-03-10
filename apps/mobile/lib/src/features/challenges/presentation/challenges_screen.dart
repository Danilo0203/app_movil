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
  List<SubmissionModel> _submissions = const [];

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
      var submissions = await widget.api.mySubmissions();
      if (list.isEmpty) {
        await widget.api.seedChallenges();
        list = await widget.api.listChallenges();
        submissions = await widget.api.mySubmissions();
      }
      if (mounted) {
        setState(() {
          _challenges = list;
          _submissions = submissions;
        });
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

  int get _totalEvidenceGoal => _challenges.fold<int>(
    0,
    (sum, challenge) => sum + challenge.items.length,
  );

  Map<int, SubmissionModel> get _latestSubmissionByChallenge {
    final latest = <int, SubmissionModel>{};
    for (final submission in _submissions) {
      final current = latest[submission.challengeId];
      if (current == null || submission.id > current.id) {
        latest[submission.challengeId] = submission;
      }
    }
    return latest;
  }

  int get _capturedEvidenceCount => _latestSubmissionByChallenge.values.fold(
    0,
    (sum, submission) => sum + submission.evidences.length,
  );

  int _capturedFor(ChallengeModel challenge) {
    return _latestSubmissionByChallenge[challenge.id]?.evidences.length ?? 0;
  }

  String _statusFor(ChallengeModel challenge) {
    final submission = _latestSubmissionByChallenge[challenge.id];
    if (submission == null) return 'Sin empezar';
    return submission.status == 'COMPLETED' ? 'Completado' : 'En progreso';
  }

  int _minutesFor(ChallengeType type) {
    switch (type) {
      case ChallengeType.technicalInspector:
        return 15;
      case ChallengeType.officeSafari:
        return 20;
      case ChallengeType.mystery:
        return 25;
    }
  }

  int _pointsFor(ChallengeType type) {
    switch (type) {
      case ChallengeType.technicalInspector:
        return 150;
      case ChallengeType.officeSafari:
        return 200;
      case ChallengeType.mystery:
        return 250;
    }
  }

  @override
  Widget build(BuildContext context) {
    final welcomeName = widget.session.userName;
    final protectedLabel = _loading ? '...' : 'Activo';
    final evidencesLabel = _loading
        ? '...'
        : '$_capturedEvidenceCount/$_totalEvidenceGoal';

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
                    'Bienvenido de nuevo',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF4FAF2D),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hola, $welcomeName',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF0E2435),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completa retos y sube en el ranking capturando evidencias de calidad.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF5A6D82),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFFD5E3E8).withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        _HeroMetric(
                          icon: Icons.flag_outlined,
                          value: _loading ? '...' : '${_challenges.length}',
                          label: 'Retos',
                        ),
                        const _MetricDivider(),
                        _HeroMetric(
                          icon: Icons.check_circle_outline,
                          value: evidencesLabel,
                          label: 'Evidencias',
                        ),
                        const _MetricDivider(),
                        _HeroMetric(
                          icon: Icons.shield_outlined,
                          value: protectedLabel,
                          label: 'Protección',
                          valueColor: const Color(0xFF47A934),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: const Duration(milliseconds: 100),
            child: SoftGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Text(
                    'Retos disponibles',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0E2435),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_challenges.length} activos',
                    style: const TextStyle(
                      color: Color(0xFF0397B0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
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
              final status = _statusFor(challenge);
              final captured = _capturedFor(challenge);
              final maxEvidence = challenge.items.length;

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
                delay: Duration(milliseconds: 120 + (index * 35)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ChallengeItemCard(
                    challenge: challenge,
                    evidenceProgress: '$captured/$maxEvidence evidencias',
                    status: status,
                    minutes: _minutesFor(challenge.type),
                    points: _pointsFor(challenge.type),
                    onTap: open,
                  ),
                ),
              );
            }),
          if (!_loading && _error == null && _challenges.isNotEmpty) ...[
            const SizedBox(height: 6),
            FadeSlideIn(
              delay: const Duration(milliseconds: 210),
              child: SoftGlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF0CAAB2), Color(0xFF3AB760)],
                        ),
                      ),
                      child: const Icon(Icons.bolt, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completa todos los retos',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10293A),
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Gana un bonus de 500 puntos extra',
                            style: TextStyle(color: Color(0xFF5E7287)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.star, color: Color(0xFFEF9A00)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor = const Color(0xFF122A3A),
  });

  final IconData icon;
  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F5F7),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: const Color(0xFF0798AF), size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Color(0xFF667B90), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFD8E5EA),
    );
  }
}

class _ChallengeItemCard extends StatelessWidget {
  const _ChallengeItemCard({
    required this.challenge,
    required this.evidenceProgress,
    required this.status,
    required this.minutes,
    required this.points,
    required this.onTap,
  });

  final ChallengeModel challenge;
  final String evidenceProgress;
  final String status;
  final int minutes;
  final int points;
  final VoidCallback onTap;

  bool get _inProgress => status == 'En progreso';
  bool get _completed => status == 'Completado';

  @override
  Widget build(BuildContext context) {
    final color = challenge.type.color(context);

    return SoftGlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.95),
                      color.withBlue(120),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(challenge.type.icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF102A3A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _descriptionFor(challenge.type),
                      style: const TextStyle(color: Color(0xFF60758A)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _TagPill(
                          text: challenge.type.shortLabel,
                          foreground: Colors.white,
                          background: color,
                        ),
                        _TagPill(
                          text: '$minutes min',
                          foreground: const Color(0xFF5A6E84),
                          background: const Color(0xFFEFF4F7),
                          icon: Icons.schedule,
                        ),
                        _TagPill(
                          text: '$points pts',
                          foreground: const Color(0xFFBA6C00),
                          background: const Color(0xFFFFE4B9),
                          icon: Icons.star_border,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkResponse(
                onTap: onTap,
                radius: 24,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _inProgress
                        ? const Color(0xFF62BB3A)
                        : _completed
                        ? const Color(0xFF0FA8B3)
                        : const Color(0xFFE1EFF1),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: (_inProgress || _completed)
                        ? Colors.white
                        : const Color(0xFF54A9AD),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFD9E7EB)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 16,
                color: Color(0xFF55B339),
              ),
              const SizedBox(width: 6),
              Text(
                evidenceProgress,
                style: const TextStyle(
                  color: Color(0xFF5E7388),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: _inProgress
                      ? const Color(0xFFFFE0B5)
                      : _completed
                      ? const Color(0xFFD9F1F2)
                      : const Color(0xFFDDEFF7),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: _inProgress
                        ? const Color(0xFFC86A00)
                        : _completed
                        ? const Color(0xFF0B8792)
                        : const Color(0xFF206B91),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _descriptionFor(ChallengeType type) {
    switch (type) {
      case ChallengeType.technicalInspector:
        return 'Verifica equipos y documenta su estado';
      case ChallengeType.officeSafari:
        return 'Explora y captura elementos del entorno';
      case ChallengeType.mystery:
        return 'Encuentra hallazgos ocultos en tu área';
    }
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.text,
    required this.foreground,
    required this.background,
    this.icon,
  });

  final String text;
  final Color foreground;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
