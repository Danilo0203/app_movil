part of '../../../../main.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.session,
    required this.onLogout,
  });
  final AuthSession session;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FadeSlideIn(
          delay: const Duration(milliseconds: 50),
          child: SoftGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perfil',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7F9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(session.userName),
                    subtitle: Text(session.userEmail),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SummaryChip(
                      icon: Icons.badge_outlined,
                      label: 'ID',
                      value: '${session.userId}',
                    ),
                    const SummaryChip(
                      icon: Icons.verified_user_outlined,
                      label: 'sesión',
                      value: 'Activa',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const FadeSlideIn(
          delay: Duration(milliseconds: 100),
          child: InlineStatusCard(
            message:
                'Capturas de pantalla no permitidas. En iOS se aplica detección y mitigación (best effort).',
            icon: Icons.shield_outlined,
            color: Color(0xFFB26A00),
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 150),
          child: FilledButton.tonalIcon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ),
      ],
    );
  }
}
