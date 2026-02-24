import { ChallengeType } from '@prisma/client';

export const defaultChallenges = [
  {
    title: 'Detector de Misterios',
    type: ChallengeType.MYSTERY,
    itemsJson: [
      { code: 'rare_object_1', label: 'Cosa rara #1' },
      { code: 'rare_object_2', label: 'Cosa rara #2' },
      { code: 'rare_object_3', label: 'Cosa rara #3' },
    ],
  },
  {
    title: 'Safari de Oficina',
    type: ChallengeType.OFFICE_SAFARI,
    itemsJson: [
      { code: 'green_object', label: 'Algo verde' },
      { code: 'small_object', label: 'Algo pequeño' },
      { code: 'noisy_object', label: 'Algo que haga ruido' },
      { code: 'shiny_object', label: 'Algo brillante' },
    ],
  },
  {
    title: 'Inspector Técnico',
    type: ChallengeType.TECHNICAL_INSPECTOR,
    itemsJson: [
      { code: 'equipment_photo', label: 'Foto del equipo' },
      { code: 'environment_photo', label: 'Foto del entorno' },
      { code: 'evidence_photo', label: 'Foto de evidencia' },
    ],
  },
] as const;
