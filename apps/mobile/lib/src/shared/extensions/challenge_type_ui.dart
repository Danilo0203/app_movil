part of '../../../main.dart';

extension ChallengeTypeUi on ChallengeType {
  IconData get icon {
    switch (this) {
      case ChallengeType.mystery:
        return Icons.search_rounded;
      case ChallengeType.officeSafari:
        return Icons.explore_rounded;
      case ChallengeType.technicalInspector:
        return Icons.engineering_rounded;
    }
  }

  Color color(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (this) {
      case ChallengeType.mystery:
        return scheme.primary;
      case ChallengeType.officeSafari:
        return scheme.tertiary;
      case ChallengeType.technicalInspector:
        return scheme.secondary;
    }
  }

  String get shortLabel {
    switch (this) {
      case ChallengeType.mystery:
        return 'Hallazgos';
      case ChallengeType.officeSafari:
        return 'Safari';
      case ChallengeType.technicalInspector:
        return 'Inspección';
    }
  }

  String get challengeTypeLabel => 'Tipo: $shortLabel';
}
