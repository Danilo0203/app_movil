part of '../../../../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.baseUrl,
    required this.onAuthenticated,
  });

  final String baseUrl;
  final Future<void> Function(AuthSession session) onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Demo User');
  final _emailCtrl = TextEditingController(text: 'demo@example.com');
  final _passwordCtrl = TextEditingController(text: 'demo1234');
  final _confirmPasswordCtrl = TextEditingController();
  bool _registerMode = false;
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _rememberMe = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ApiClient(baseUrl: widget.baseUrl);
      final data = _registerMode
          ? await api.register(
              name: _nameCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
            )
          : await api.login(
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
            );
      final user = data['user'] as Map<String, dynamic>;
      await widget.onAuthenticated(
        AuthSession(
          accessToken: data['accessToken'] as String,
          userId: user['id'] as int,
          userName: user['name'] as String,
          userEmail: user['email'] as String,
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = _registerMode;
    return Scaffold(
      body: AppShell(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 36),
                    const _AuthBrandIcon(),
                    const SizedBox(height: 16),
                    Text(
                      'ACREDICOM RETOS',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isRegister ? 'Crea tu cuenta' : 'Bienvenido de nuevo',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 46),
                      child: Text(
                        isRegister
                            ? 'Regístrate para iniciar tus retos y sumar puntos.'
                            : 'Ingresa tus credenciales para continuar con tus retos.',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                              height: 1.3,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4F7F8),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(34),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCE2E7),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _AuthTabButton(
                                      label: 'Iniciar sesión',
                                      selected: !isRegister,
                                      onTap: _loading
                                          ? null
                                          : () => setState(
                                              () => _registerMode = false,
                                            ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _AuthTabButton(
                                      label: 'Registrarse',
                                      selected: isRegister,
                                      onTap: _loading
                                          ? null
                                          : () => setState(
                                              () => _registerMode = true,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (isRegister) ...[
                              _AuthLabel(
                                text: 'Nombre',
                                color: const Color(0xFF182B3B),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameCtrl,
                                enabled: !_loading,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  hintText: 'Tu nombre',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) =>
                                    isRegister &&
                                        (v == null || v.trim().length < 2)
                                    ? 'Mínimo 2 caracteres'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                            ],
                            const _AuthLabel(
                              text: 'Correo electrónico',
                              color: Color(0xFF182B3B),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailCtrl,
                              enabled: !_loading,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                hintText: 'tu@email.com',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: (v) => (v == null || !v.contains('@'))
                                  ? 'Email inválido'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            const _AuthLabel(
                              text: 'Contraseña',
                              color: Color(0xFF182B3B),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordCtrl,
                              enabled: !_loading,
                              autofillHints: const [AutofillHints.password],
                              obscureText: !_showPassword,
                              decoration: InputDecoration(
                                hintText: 'Tu contraseña',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: _loading
                                      ? null
                                      : () => setState(
                                          () => _showPassword = !_showPassword,
                                        ),
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 6)
                                  ? 'Mínimo 6 caracteres'
                                  : null,
                            ),
                            if (isRegister) ...[
                              const SizedBox(height: 12),
                              const _AuthLabel(
                                text: 'Confirmar contraseña',
                                color: Color(0xFF182B3B),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _confirmPasswordCtrl,
                                enabled: !_loading,
                                obscureText: !_showConfirmPassword,
                                decoration: InputDecoration(
                                  hintText: 'Confirma tu contraseña',
                                  prefixIcon: const Icon(
                                    Icons.lock_reset_outlined,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: _loading
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
                                  if (!isRegister) return null;
                                  if (v == null || v.isEmpty) {
                                    return 'Confirma tu contraseña';
                                  }
                                  if (v != _passwordCtrl.text) {
                                    return 'Las contraseñas no coinciden';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: _loading
                                      ? null
                                      : (v) => setState(
                                          () => _rememberMe = v ?? false,
                                        ),
                                  side: const BorderSide(
                                    color: Color(0xFF7C90A6),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const Text(
                                  'Recordarme',
                                  style: TextStyle(color: Color(0xFF5A6D82)),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () => ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Recuperación de contraseña aún no disponible.',
                                                ),
                                              ),
                                            ),
                                  child: const Text(
                                    '¿Olvidaste tu contraseña?',
                                  ),
                                ),
                              ],
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 4),
                              InlineStatusCard(
                                message: _error!,
                                icon: Icons.error_outline,
                                color: Colors.red,
                              ),
                            ],
                            const SizedBox(height: 10),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0AAAB3),
                                    Color(0xFF085A95),
                                  ],
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
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ),
                                onPressed: _loading ? null : _submit,
                                iconAlignment: IconAlignment.end,
                                icon: const Icon(Icons.arrow_forward),
                                label: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: _loading
                                      ? const SizedBox(
                                          key: ValueKey('loading'),
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          key: ValueKey(isRegister),
                                          isRegister
                                              ? 'Crear cuenta'
                                              : 'Iniciar sesión',
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => setState(
                                        () => _registerMode = !_registerMode,
                                      ),
                                child: Text(
                                  isRegister
                                      ? '¿Ya tienes cuenta? Inicia sesión'
                                      : '¿No tienes cuenta? Regístrate aquí',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthBrandIcon extends StatelessWidget {
  const _AuthBrandIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: const Color(0xFF184B75),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF3DC062),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF63B93F),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _AuthLabel extends StatelessWidget {
  const _AuthLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 22 / 1.6,
      ),
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  const _AuthTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected
                    ? const Color(0xFF12293A)
                    : const Color(0xFF6B7F95),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
