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
    final scheme = Theme.of(context).colorScheme;
    final isRegister = _registerMode;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text(''),
      ),
      body: AppShell(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 74, 16, 16),
              child: Column(
                children: [
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          Text(
                            'Acredicom Retos',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 10),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.08),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child: Column(
                              key: ValueKey(isRegister),
                              children: [
                                Text(
                                  isRegister
                                      ? 'Crear Cuenta'
                                      : 'Bienvenido de nuevo',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isRegister
                                      ? 'Registra tu cuenta para capturar evidencias y generar reportes.'
                                      : 'Ingresa con email y contraseña para continuar con tus retos.',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.84,
                                        ),
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: SoftGlassCard(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F4F5),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _AuthTabButton(
                                      label: 'Log in',
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
                                      label: 'Sign up',
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
                            const SizedBox(height: 14),
                            InlineStatusCard(
                              message:
                                  'Protección activa: capturas de pantalla deshabilitadas durante la operación.',
                              icon: Icons.shield_outlined,
                              color: scheme.primary,
                            ),
                            const SizedBox(height: 14),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              child: Column(
                                children: [
                                  if (isRegister) ...[
                                    TextFormField(
                                      controller: _nameCtrl,
                                      enabled: !_loading,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: const InputDecoration(
                                        labelText: 'Nombre',
                                        hintText: 'Ingresa tu nombre',
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
                                  TextFormField(
                                    controller: _emailCtrl,
                                    enabled: !_loading,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      hintText: 'tucorreo@empresa.com',
                                      prefixIcon: Icon(Icons.mail_outline),
                                    ),
                                    validator: (v) =>
                                        (v == null || !v.contains('@'))
                                        ? 'Email inválido'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordCtrl,
                                    enabled: !_loading,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    obscureText: !_showPassword,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      hintText: 'Ingresa tu contraseña',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: _loading
                                            ? null
                                            : () => setState(
                                                () => _showPassword =
                                                    !_showPassword,
                                              ),
                                        icon: Icon(
                                          _showPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.length < 6)
                                        ? 'Mínimo 6 caracteres'
                                        : null,
                                  ),
                                  if (isRegister) ...[
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _confirmPasswordCtrl,
                                      enabled: !_loading,
                                      obscureText: !_showConfirmPassword,
                                      decoration: InputDecoration(
                                        labelText: 'Confirm Password',
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
                                ],
                              ),
                            ),
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
                                  visualDensity: VisualDensity.compact,
                                ),
                                const Text('Recordarme'),
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
                            const SizedBox(height: 14),
                            FilledButton(
                              onPressed: _loading ? null : _submit,
                              child: AnimatedSwitcher(
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
                                        isRegister ? 'Register' : 'Login',
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
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
                                      : '¿No tienes cuenta? Crea una cuenta',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
                  color: Color(0x10000000),
                  blurRadius: 10,
                  offset: Offset(0, 5),
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
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFF11252A)
                    : const Color(0xFF637780),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
