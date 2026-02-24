part of '../../../main.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0C6877),
                  const Color(0xFF127788).withValues(alpha: 0.92),
                  const Color(0xFFEAF3F5),
                  const Color(0xFFF5F8F9),
                ],
                stops: const [0, 0.26, 0.62, 1],
              ),
            ),
          ),
        ),
        Positioned(
          top: -40,
          left: -30,
          child: _DecorCircle(
            size: 190,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        Positioned(
          top: 90,
          right: -45,
          child: _DecorCircle(
            size: 160,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        Positioned(
          top: 220,
          left: 35,
          child: _DecorCircle(
            size: 80,
            color: scheme.primaryContainer.withValues(alpha: 0.22),
          ),
        ),
        child,
      ],
    );
  }
}

class _DecorCircle extends StatelessWidget {
  const _DecorCircle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class InlineStatusCard extends StatelessWidget {
  const InlineStatusCard({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color,
    this.action,
    this.actionLabel,
  });

  final String message;
  final IconData icon;
  final Color? color;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = color ?? scheme.primary;
    return Card(
      color: tone.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: tone),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            if (action != null && actionLabel != null)
              TextButton(onPressed: action, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}

class SummaryChip extends StatelessWidget {
  const SummaryChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 6),
          Text('$value $label'),
        ],
      ),
    );
  }
}

class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.04),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (!mounted) return;
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : widget.offset,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}

class SoftGlassCard extends StatelessWidget {
  const SoftGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
