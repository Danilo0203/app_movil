part of '../../../../main.dart';

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
