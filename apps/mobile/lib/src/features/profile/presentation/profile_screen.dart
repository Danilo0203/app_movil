part of '../../../../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.session,
    required this.api,
    required this.onSessionUpdated,
    required this.onLogout,
  });

  final AuthSession session;
  final ApiClient api;
  final Future<void> Function(AuthSession session) onSessionUpdated;
  final VoidCallback onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  String? _error;
  UserProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await widget.api.myProfile();
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openEditProfile() async {
    final baseProfile =
        _profile ??
        UserProfileModel(
          id: widget.session.userId,
          name: widget.session.userName,
          email: widget.session.userEmail,
        );

    final updated = await Navigator.of(context).push<UserProfileModel>(
      MaterialPageRoute(
        builder: (_) =>
            ProfileEditScreen(api: widget.api, initial: baseProfile),
      ),
    );

    if (updated == null || !mounted) return;

    setState(() => _profile = updated);
    if (updated.name != widget.session.userName ||
        updated.email != widget.session.userEmail) {
      await widget.onSessionUpdated(
        AuthSession(
          accessToken: widget.session.accessToken,
          userId: widget.session.userId,
          userName: updated.name,
          userEmail: updated.email,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final displayName = profile?.name ?? widget.session.userName;
    final displayEmail = profile?.email ?? widget.session.userEmail;
    final displayPhone = (profile?.phone?.trim().isNotEmpty ?? false)
        ? profile!.phone!
        : '+502 0000 0000';
    final displayAddress = (profile?.address?.trim().isNotEmpty ?? false)
        ? profile!.address!
        : 'Sin dirección registrada';
    final memberSince = _formatMemberSince(profile?.createdAt);
    final avatarUrl = profile?.avatarUrl?.trim();
    final hasRemoteAvatar = avatarUrl != null && avatarUrl.startsWith('http');

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: [
          FadeSlideIn(
            delay: const Duration(milliseconds: 50),
            child: SoftGlassCard(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Mi Perfil',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F2435),
                            ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDF0DC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 15,
                              color: Color(0xFF4FAE34),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Activo',
                              style: TextStyle(color: Color(0xFF4FAE34)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF23A4A7), Color(0xFF57B63F)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          image: hasRemoteAvatar
                              ? DecorationImage(
                                  image: NetworkImage(avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: !hasRemoteAvatar
                            ? const Icon(
                                Icons.person_outline,
                                color: Colors.white,
                                size: 38,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF122A3A),
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              displayEmail,
                              style: const TextStyle(color: Color(0xFF667B90)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Miembro desde $memberSince',
                              style: const TextStyle(color: Color(0xFF70859A)),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: const Color(0xFFD2EBEF),
                        child: IconButton(
                          onPressed: _openEditProfile,
                          icon: const Icon(
                            Icons.edit,
                            color: Color(0xFF169CB0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2EFF2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCFE2E8)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          color: Color(0xFF1E8AAC),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            displayPhone,
                            style: const TextStyle(
                              color: Color(0xFF143043),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2EFF2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCFE2E8)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF1E8AAC),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            displayAddress,
                            style: const TextStyle(
                              color: Color(0xFF143043),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading) ...[
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            InlineStatusCard(
              message: _error!,
              icon: Icons.error_outline,
              color: Colors.red,
              action: _loadProfile,
              actionLabel: 'Reintentar',
            ),
          ],
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: OutlinedButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout, color: Color(0xFFFF3F3F)),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                foregroundColor: const Color(0xFFFF3F3F),
                side: const BorderSide(color: Color(0xFFFFB3B3)),
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMemberSince(DateTime? date) {
    final source = date ?? DateTime(2024, 3);
    const months = <String>[
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final month = months[source.month - 1];
    return '${month[0].toUpperCase()}${month.substring(1)} ${source.year}';
  }
}
