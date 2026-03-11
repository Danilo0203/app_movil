part of '../../../../main.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({
    super.key,
    required this.api,
    required this.initial,
  });

  final ApiClient api;
  final UserProfileModel initial;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final OfflineAppController _offline = OfflineAppController.instance;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  final TextEditingController _currentPasswordCtrl = TextEditingController();
  final TextEditingController _newPasswordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  bool _saving = false;
  bool _uploadingAvatar = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  String? _avatarUrl;
  String? _localAvatarPath;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial.name);
    _emailCtrl = TextEditingController(text: widget.initial.email);
    _phoneCtrl = TextEditingController(text: widget.initial.phone ?? '');
    _addressCtrl = TextEditingController(text: widget.initial.address ?? '');
    _avatarUrl = widget.initial.avatarUrl;
    _localAvatarPath = widget.initial.localAvatarPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_uploadingAvatar || _saving) return;
    final file = await Navigator.of(context).push<File>(
      MaterialPageRoute(
        builder: (_) => const CameraCaptureScreen(itemLabel: 'Foto de perfil'),
      ),
    );

    if (file == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final updated = await _offline.saveAvatarOffline(file);
      if (!mounted) return;
      setState(() {
        _avatarUrl = updated.avatarUrl;
        _localAvatarPath = updated.localAvatarPath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _offline.isOnline
                ? 'Foto de perfil guardada. Se sincronizará enseguida.'
                : 'Foto de perfil guardada offline.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final shouldChangePassword =
        _newPasswordCtrl.text.trim().isNotEmpty ||
        _confirmPasswordCtrl.text.trim().isNotEmpty ||
        _currentPasswordCtrl.text.trim().isNotEmpty;

    setState(() => _saving = true);
    try {
      if (shouldChangePassword && !_offline.isOnline) {
        throw Exception('El cambio de contraseña requiere conexión.');
      }

      final updated = await _offline.saveProfileOffline(
        base: widget.initial.copyWith(
          avatarUrl: _avatarUrl,
          localAvatarPath: _localAvatarPath,
        ),
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
      );

      if (shouldChangePassword) {
        await widget.api.changeMyPassword(
          currentPassword: _currentPasswordCtrl.text,
          newPassword: _newPasswordCtrl.text,
        );
      }

      final result = UserProfileModel(
        id: updated.id,
        name: updated.name,
        email: updated.email,
        phone: updated.phone,
        address: updated.address,
        avatarUrl: _avatarUrl ?? updated.avatarUrl,
        localAvatarPath: _localAvatarPath,
        syncStatus: updated.syncStatus,
        createdAt: updated.createdAt,
        updatedAt: updated.updatedAt,
      );

      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedAvatarUrl = _avatarUrl?.trim();
    final normalizedLocalAvatarPath = _localAvatarPath?.trim();
    final hasLocalAvatar =
        normalizedLocalAvatarPath != null &&
        normalizedLocalAvatarPath.isNotEmpty;
    final hasRemoteAvatar =
        normalizedAvatarUrl != null && normalizedAvatarUrl.startsWith('http');

    return Scaffold(
      body: AppShell(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  color: Colors.white.withValues(alpha: 0.8),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Volver'),
                      ),
                      const Expanded(
                        child: Text(
                          'Editar Perfil',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 27 / 1.4,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F2435),
                          ),
                        ),
                      ),
                      const SizedBox(width: 80),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    children: [
                      SoftGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Foto de perfil',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: GestureDetector(
                                onTap: _pickAndUploadAvatar,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 118,
                                      height: 118,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF12AAB0),
                                            Color(0xFF59B741),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                        image: hasLocalAvatar
                                            ? DecorationImage(
                                                image: FileImage(
                                                  File(
                                                    normalizedLocalAvatarPath,
                                                  ),
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : hasRemoteAvatar
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                  normalizedAvatarUrl,
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: !hasRemoteAvatar
                                          ? const Icon(
                                              Icons.person_outline,
                                              color: Colors.white,
                                              size: 54,
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      right: -6,
                                      bottom: -6,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0FA8B3),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: _uploadingAvatar
                                            ? const Padding(
                                                padding: EdgeInsets.all(10),
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.camera_alt_outlined,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Center(
                              child: Text(
                                'Toca para cambiar tu foto de perfil',
                                style: TextStyle(color: Color(0xFF6E8298)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SoftGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información personal',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 16),
                            if (!_offline.isOnline)
                              const Text(
                                'El cambio de contraseña solo está disponible con conexión.',
                                style: TextStyle(color: Color(0xFFAD6A00)),
                              ),
                            if (!_offline.isOnline) const SizedBox(height: 16),
                            const _FieldLabel('Nombre completo'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameCtrl,
                              enabled: !_saving,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().length < 2)
                                  ? 'Mínimo 2 caracteres'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            const _FieldLabel('Correo electrónico'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailCtrl,
                              enabled: !_saving,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: (v) => (v == null || !v.contains('@'))
                                  ? 'Correo inválido'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            const _FieldLabel('Teléfono'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _phoneCtrl,
                              enabled: !_saving,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: '+52 123 456 7890',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (value.isNotEmpty && value.length < 7) {
                                  return 'Teléfono inválido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            const _FieldLabel('Dirección'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _addressCtrl,
                              enabled: !_saving,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText: 'Calle, número, colonia, ciudad...',
                                prefixIcon: Icon(Icons.location_on_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SoftGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cambiar contraseña',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Deja en blanco si no deseas cambiarla',
                              style: TextStyle(color: Color(0xFF6E8298)),
                            ),
                            const SizedBox(height: 14),
                            const _FieldLabel('Contraseña actual'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _currentPasswordCtrl,
                              enabled: !_saving,
                              obscureText: !_showCurrentPassword,
                              decoration: InputDecoration(
                                hintText: 'Tu contraseña actual',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: _saving
                                      ? null
                                      : () => setState(
                                          () => _showCurrentPassword =
                                              !_showCurrentPassword,
                                        ),
                                  icon: Icon(
                                    _showCurrentPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                final hasNew = _newPasswordCtrl.text
                                    .trim()
                                    .isNotEmpty;
                                if (hasNew && (v == null || v.isEmpty)) {
                                  return 'Ingresa tu contraseña actual';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            const _FieldLabel('Nueva contraseña'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _newPasswordCtrl,
                              enabled: !_saving,
                              obscureText: !_showNewPassword,
                              decoration: InputDecoration(
                                hintText: 'Mínimo 8 caracteres',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: _saving
                                      ? null
                                      : () => setState(
                                          () => _showNewPassword =
                                              !_showNewPassword,
                                        ),
                                  icon: Icon(
                                    _showNewPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (value.isNotEmpty && value.length < 8) {
                                  return 'Mínimo 8 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            const _FieldLabel('Confirmar nueva contraseña'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _confirmPasswordCtrl,
                              enabled: !_saving,
                              obscureText: !_showConfirmPassword,
                              decoration: InputDecoration(
                                hintText: 'Repite tu nueva contraseña',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: _saving
                                      ? null
                                      : () => setState(
                                          () => _showConfirmPassword =
                                              !_showConfirmPassword,
                                        ),
                                  icon: Icon(
                                    _showConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (_newPasswordCtrl.text.trim().isNotEmpty &&
                                    value != _newPasswordCtrl.text.trim()) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0AAAB3), Color(0xFF085A95)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33006A90),
                              blurRadius: 14,
                              offset: Offset(0, 7),
                            ),
                          ],
                        ),
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          onPressed: (_saving || _uploadingAvatar)
                              ? null
                              : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Guardar cambios'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF0F2435),
        fontWeight: FontWeight.w700,
        fontSize: 18 / 1.3,
      ),
    );
  }
}
