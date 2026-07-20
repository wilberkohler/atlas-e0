import '../models/experience_state_summary.dart';

class ExperienceStateInferer {
  const ExperienceStateInferer();

  List<String> infer(ExperienceStateSummary summary) {
    if (summary.events.isEmpty) {
      return const [
        'A sessão terminou sem interações suficientes para observar a exploração.',
        'As próximas observações dependerão apenas do que acontecer dentro da sala.',
        'Nenhuma classificação pessoal foi feita a partir desta sessão.',
      ];
    }

    return [
      _curiosityObservation(summary),
      _hesitationObservation(summary),
      _engagementObservation(summary),
    ];
  }

  String _curiosityObservation(ExperienceStateSummary summary) {
    final uniqueCount = summary.uniqueElementIds.length;

    if (summary.returnedToKnownElements && summary.exploredOptionalElements) {
      return 'Você explorou pontos opcionais e voltou a elementos já vistos, como se estivesse confirmando pistas.';
    }

    if (uniqueCount >= 4) {
      return 'Você distribuiu a atenção por vários elementos da sala antes de concluir a experiência.';
    }

    return 'Você concentrou a exploração em poucos elementos antes de seguir para a saída.';
  }

  String _hesitationObservation(ExperienceStateSummary summary) {
    final repeatedTouch = summary.events.any(
      (event) => event.timesElementTapped >= 3,
    );

    if (summary.hasLongPause && repeatedTouch) {
      return 'Houve pausas maiores e repetição de toque no mesmo elemento, sugerindo uma tentativa de ler melhor a cena.';
    }

    if (summary.hasLongPause) {
      return 'Você desacelerou entre algumas interações, especialmente depois que a sala começou a responder.';
    }

    if (repeatedTouch) {
      return 'Você tocou repetidamente no mesmo elemento, como se buscasse uma segunda camada de resposta.';
    }

    return 'As interações avançaram sem grandes pausas ou repetições prolongadas.';
  }

  String _engagementObservation(ExperienceStateSummary summary) {
    if (summary.completed &&
        summary.exploredOptionalElements &&
        summary.attemptedExitBeforeExploring) {
      return 'Você tentou sair cedo, mas ainda explorou elementos opcionais antes de encerrar a sessão.';
    }

    if (summary.completed && summary.exploredMoreThanMinimum) {
      return 'Você permaneceu ativo além do mínimo necessário para liberar a conclusão da sala.';
    }

    if (summary.completed) {
      return 'Você completou a experiência depois de reunir sinais suficientes para atravessar a porta.';
    }

    return 'A sala foi explorada parcialmente, sem chegar à conclusão registrada.';
  }
}
