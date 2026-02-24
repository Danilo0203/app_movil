part of '../../../../main.dart';

class _PillLabel extends StatelessWidget {
  const _PillLabel({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _pdfFilePrefix(ChallengeType type) {
  switch (type) {
    case ChallengeType.mystery:
      return 'reporte_hallazgos';
    case ChallengeType.officeSafari:
      return 'safari_completado';
    case ChallengeType.technicalInspector:
      return 'reporte_tecnico';
  }
}
