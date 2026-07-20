enum InteractiveElementType {
  unknownObject,
  sealedDoor,
  distantWindow,
  deskDrawer,
  dormantPanel,
}

class InteractiveElement {
  const InteractiveElement({
    required this.id,
    required this.type,
    required this.title,
    required this.sensoryHint,
    required this.firstReaction,
    required this.repeatReaction,
    this.isOptional = false,
    this.isExit = false,
  });

  final String id;
  final InteractiveElementType type;
  final String title;
  final String sensoryHint;
  final String firstReaction;
  final String repeatReaction;
  final bool isOptional;
  final bool isExit;

  String reactionForTapCount(int tapCount) {
    if (tapCount <= 1) {
      return firstReaction;
    }

    return repeatReaction;
  }
}

const zeroRoomElements = <InteractiveElement>[
  InteractiveElement(
    id: 'object',
    type: InteractiveElementType.unknownObject,
    title: 'Objeto central',
    sensoryHint: 'Pulsa sem som.',
    firstReaction: 'O objeto responde com um pulso baixo e regular.',
    repeatReaction: 'O pulso volta mais curto, como se reconhecesse o toque.',
  ),
  InteractiveElement(
    id: 'door',
    type: InteractiveElementType.sealedDoor,
    title: 'Porta fechada',
    sensoryHint: 'Maçaneta fria.',
    firstReaction: 'A porta vibra, mas ainda não abre.',
    repeatReaction: 'A fechadura responde melhor depois que a sala foi lida.',
    isExit: true,
  ),
  InteractiveElement(
    id: 'window',
    type: InteractiveElementType.distantWindow,
    title: 'Janela distante',
    sensoryHint: 'Luz na névoa.',
    firstReaction: 'A névoa se afasta por um instante e revela outra sala.',
    repeatReaction:
        'A luz distante repete o mesmo movimento, agora mais fraco.',
    isOptional: true,
  ),
  InteractiveElement(
    id: 'drawer',
    type: InteractiveElementType.deskDrawer,
    title: 'Gaveta da mesa',
    sensoryHint: 'Madeira cedendo.',
    firstReaction: 'Dentro da gaveta há uma fita marcada com três pontos.',
    repeatReaction: 'A fita permanece imóvel, mas os pontos parecem alinhados.',
  ),
  InteractiveElement(
    id: 'panel',
    type: InteractiveElementType.dormantPanel,
    title: 'Painel apagado',
    sensoryHint: 'Reflexo atrasado.',
    firstReaction: 'O painel acende uma linha breve e volta ao silêncio.',
    repeatReaction:
        'A linha reaparece no mesmo lugar, como uma pista confirmada.',
    isOptional: true,
  ),
];
