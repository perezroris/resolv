import 'data.dart';

class ServiceProfile {
  const ServiceProfile({
    required this.person,
    required this.tags,
    required this.serviceAreas,
    required this.bio,
    required this.rating,
    required this.reviewCount,
  });

  final Person person;
  final List<String> tags;
  final List<String> serviceAreas;
  final String bio;
  final double? rating;
  final int reviewCount;
}

// Os índices seguem a ordem de areas. Cada ligação aparece nos dois sentidos.
const _neighbors = [
  [1, 2],
  [0, 3, 4],
  [0, 4, 5],
  [1, 6],
  [1, 2, 6],
  [2, 7],
  [3, 4, 7],
  [5, 6],
];

const _outsideRegion = 99;

int neighborhoodDistance(String origin, String other) {
  final start = areas.indexOf(origin);
  final end = areas.indexOf(other);
  if (start < 0 || end < 0) return _outsideRegion;
  var frontier = [start];
  final visited = {start};
  for (var distance = 0; frontier.isNotEmpty; distance++) {
    if (frontier.contains(end)) return distance;
    frontier = [
      for (final district in frontier)
        for (final neighbor in _neighbors[district])
          if (visited.add(neighbor)) neighbor,
    ];
  }
  return _outsideRegion;
}

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp('[áàãâä]'), 'a')
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[íìîï]'), 'i')
    .replaceAll(RegExp('[óòõôö]'), 'o')
    .replaceAll(RegExp('[úùûü]'), 'u')
    .replaceAll('ç', 'c');

const _aliases = {
  'Hidráulica': 'encanador encanadora encanamento vazamento',
  'Elétrica': 'eletricista eletricidade tomada',
  'Limpeza': 'faxina faxineira faxineiro diarista',
  'Pintura': 'pintor pintora',
  'Montagem de móveis': 'montador montadora marcenaria',
  'Pequenos reparos': 'conserto manutenção reparos',
  'Jardinagem': 'jardineiro jardineira poda',
  'Costura': 'costureira costureiro ajustes',
  'Aulas particulares': 'professor professora reforço escolar',
  'Informática': 'computador técnico técnica suporte',
  'Cuidados com pets': 'cachorro gato passeio passeador cuidador',
  'Conserto de eletrodomésticos': 'assistência técnica manutenção',
  'Fretes e mudanças': 'frete carreto transporte de móveis mudança',
  'Beleza': 'cabelo tranças penteado cabeleireira manicure',
  'Fotografia': 'fotógrafo fotógrafa fotos ensaio retrato',
  'Culinária': 'cozinheiro cozinheira marmita comida refeição bolo encomenda',
};

List<ServiceProfile> findProviders(
  List<ServiceProfile> profiles, {
  required String area,
  String? tag,
  String query = '',
}) {
  if (!areas.contains(area)) return [];
  final terms = _normalize(query.trim())
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  final hasTag = tag != null && tag.isNotEmpty;
  final distances = {
    for (final district in areas)
      district: neighborhoodDistance(area, district),
  };
  final matches = profiles.where((profile) {
    if (!profile.serviceAreas.contains(area)) return false;
    if (hasTag && !profile.tags.contains(tag)) return false;
    if (terms.isEmpty) return true;
    final inventory = _normalize(
      [
        profile.person.name,
        profile.person.area,
        profile.bio,
        ...profile.tags,
        for (final tag in profile.tags) _aliases[tag] ?? '',
      ].join(' '),
    );
    return terms.every(inventory.contains);
  }).toList();

  int distance(ServiceProfile p) => distances[p.person.area] ?? _outsideRegion;
  matches.sort((a, b) {
    final order = distance(a).compareTo(distance(b));
    if (order != 0) return order;
    if ((a.person.avatar == null) != (b.person.avatar == null)) {
      return a.person.avatar == null ? 1 : -1;
    }
    return _normalize(a.person.name).compareTo(_normalize(b.person.name));
  });
  if (matches.isEmpty || !hasTag && terms.isEmpty) return matches;
  final nearest = distance(matches.first);
  return matches.takeWhile((p) => distance(p) == nearest).toList();
}

// As duas listas guardam índices de serviceTags e areas. O bairro de origem já faz parte da cobertura.
const _services = <(int, List<int>, List<int>, String, double?, int)>[
  (
    8,
    [2],
    [1, 2],
    'Faço faxina em apartamentos e levo meus próprios produtos quando você precisar.',
    4.9,
    19,
  ),
  (
    1,
    [8],
    [0, 3],
    'Dou reforço de matemática para o ensino fundamental. Posso levar exercícios para a primeira aula.',
    4.9,
    17,
  ),
  (
    2,
    [4],
    [0, 4],
    'Monto guarda-roupas, estantes e mesas. Uma foto das peças ajuda a combinar a visita.',
    4.8,
    12,
  ),
  (
    5,
    [7],
    [0, 2],
    'Ajusto uniformes e calças, faço barras e troco zíperes no meu ateliê.',
    5.0,
    8,
  ),
  (
    6,
    [5],
    [0, 3, 4],
    'Conserto portas, dobradiças e puxadores. Também instalo prateleiras e varões.',
    4.9,
    22,
  ),
  (
    3,
    [0],
    [0, 1, 6],
    'Troco torneiras e sifões, identifico vazamentos aparentes e reviso caixas de descarga.',
    4.8,
    9,
  ),
  (
    7,
    [11],
    [5, 6],
    'Faço diagnóstico de ventiladores e batedeiras de bancada. Busco aparelhos pequenos no bairro.',
    4.7,
    10,
  ),
  (
    9,
    [1],
    [0, 4],
    'Instalo luminárias, verifico tomadas e faço pequenos reparos elétricos em casa.',
    5.0,
    3,
  ),
  (
    10,
    [10],
    [0, 4],
    'Faço passeios com cães e visito gatos quando os tutores viajam.',
    4.9,
    14,
  ),
  (
    11,
    [3],
    [1, 4],
    'Pinto quartos e salas. Faço uma visita para medir as paredes e estimar o material.',
    4.6,
    7,
  ),
  (
    12,
    [7],
    [1, 2],
    'Ajusto vestidos e camisas e faço pequenos consertos em peças de malha.',
    4.8,
    11,
  ),
  (
    13,
    [6],
    [2, 7],
    'Faço poda de cercas vivas e manutenção de canteiros em quintais.',
    4.8,
    10,
  ),
  (
    14,
    [9],
    [0, 4, 7],
    'Ajudo com redes Wi-Fi, impressoras e configuração de computadores.',
    4.9,
    18,
  ),
  (
    15,
    [0, 5],
    [5, 6],
    'Conserto torneiras, chuveirinhos e portas de armário. Atendo com hora marcada.',
    null,
    0,
  ),
  (
    17,
    [6],
    [0, 3],
    'Cuido de hortas pequenas, replantio em vasos e adubação.',
    4.8,
    6,
  ),
  (
    18,
    [2],
    [4, 5],
    'Faço limpeza de fim de mudança e organização de armários.',
    5.0,
    4,
  ),
  (
    19,
    [8],
    [1, 6],
    'Dou aulas de violão para quem está começando. O primeiro encontro pode ser em casa.',
    4.9,
    9,
  ),
  (
    20,
    [3, 5],
    [0, 2],
    'Faço retoques em paredes e pequenos reparos em imóveis alugados.',
    4.8,
    8,
  ),
  (
    21,
    [4],
    [2, 7],
    'Monto e desmonto móveis para mudanças. Trabalho com manuais impressos ou digitais.',
    4.7,
    7,
  ),
  (
    22,
    [9],
    [3, 4],
    'Organizo arquivos e ensino o básico do celular, inclusive chamadas de vídeo.',
    null,
    0,
  ),
  (
    23,
    [11],
    [5],
    'Faço revisão de fogões e pequenos fornos elétricos. Combino a retirada dos aparelhos.',
    4.9,
    11,
  ),
  (
    25,
    [0],
    [3, 4],
    'Faço manutenção de caixas de descarga e instalação de filtros de água.',
    4.8,
    12,
  ),
  (
    26,
    [7],
    [0, 5],
    'Troco elásticos e ajusto barras de cortinas, toalhas e roupas infantis.',
    4.9,
    13,
  ),
  (
    27,
    [10],
    [1, 6],
    'Cuido de gatos em casa e envio notícias durante a visita.',
    null,
    0,
  ),
  (
    28,
    [1],
    [2, 6],
    'Instalo ventiladores de teto e luminárias. Verifico a fiação antes do serviço.',
    4.8,
    9,
  ),
  (
    29,
    [3],
    [2, 7],
    'Faço pintura de grades e portões e preparo as superfícies antes da tinta.',
    4.8,
    5,
  ),
  (
    30,
    [2],
    [3, 7],
    'Faço faxina e limpeza detalhada de cozinhas pequenas.',
    4.9,
    15,
  ),
  (
    31,
    [5],
    [5, 6],
    'Troco trilhos de gavetas e ajusto portas de correr.',
    null,
    0,
  ),
  (
    33,
    [9],
    [0, 3],
    'Configuro computadores e ofereço ajuda com backup de fotos e documentos.',
    4.8,
    16,
  ),
  (
    34,
    [6],
    [4, 5],
    'Recupero jardins de varanda e preparo vasos para receber mudas.',
    5.0,
    5,
  ),
  (
    35,
    [8],
    [0, 6],
    'Dou aulas de inglês e preparo atividades de conversação para adultos.',
    4.8,
    7,
  ),
  (
    36,
    [10],
    [1, 2],
    'Faço passeios curtos com cães idosos e visitas de alimentação.',
    4.9,
    10,
  ),
  (
    37,
    [12],
    [0, 2, 7],
    'Faço carretos de móveis e caixas. Combino os pontos de retirada e entrega antes da viagem.',
    4.8,
    6,
  ),
  (
    38,
    [13],
    [0, 3, 4],
    'Atendo em casa para cortes, tranças e penteados. Gosto de conversar sobre o estilo antes da visita.',
    4.9,
    8,
  ),
  (
    41,
    [14],
    [0, 3],
    'Fotografo produtos artesanais e festas de família. Entrego as fotos em uma galeria digital.',
    null,
    0,
  ),
  (
    40,
    [15],
    [1, 2],
    'Preparo marmitas e bolos caseiros por encomenda. Você pode retirar na minha cozinha no Centro.',
    4.9,
    9,
  ),
];

List<ServiceProfile> serviceDirectory(AppData data) {
  final residents = {for (final person in data.people) person.id: person};
  final result = <ServiceProfile>[];
  for (final (id, tags, coverage, bio, rating, count) in _services) {
    final resident = residents['u$id'];
    if (resident == null) continue;
    result.add(
      ServiceProfile(
        person: resident,
        tags: [for (final index in tags) serviceTags[index]],
        serviceAreas: {
          resident.area,
          for (final index in coverage) areas[index],
        }.toList(),
        bio: bio,
        rating: rating,
        reviewCount: count,
      ),
    );
  }
  final owner = data.me;
  if (owner.professional) {
    result.add(
      ServiceProfile(
        person: owner,
        tags: owner.tags,
        serviceAreas: owner.areas,
        bio: owner.bio,
        rating: null,
        reviewCount: 0,
      ),
    );
  }
  if (data.reviews.isEmpty) return result;
  return result.map((profile) {
    final reviews = data.reviews.where(
      (r) => r.providerId == profile.person.id,
    );
    if (reviews.isEmpty) return profile;
    final count = profile.reviewCount + reviews.length;
    final sum = reviews.fold<int>(0, (sum, review) => sum + review.stars);
    return ServiceProfile(
      person: profile.person,
      tags: profile.tags,
      serviceAreas: profile.serviceAreas,
      bio: profile.bio,
      rating: ((profile.rating ?? 0) * profile.reviewCount + sum) / count,
      reviewCount: count,
    );
  }).toList();
}

List<Post> serviceRequests(AppData data) {
  final owner = data.me;
  if (!owner.professional) return [];
  final districts = {for (final person in data.people) person.id: person.area};
  final distances = {
    for (final area in owner.areas)
      area: neighborhoodDistance(owner.area, area),
  };
  final matches = data.posts
      .where(
        (post) =>
            !post.resolved &&
            post.authorId != owner.id &&
            post.tag != adviceTag &&
            owner.tags.contains(post.tag) &&
            distances.containsKey(post.area ?? districts[post.authorId]),
      )
      .toList();
  matches.sort((a, b) {
    final first = distances[a.area ?? districts[a.authorId]]!;
    final second = distances[b.area ?? districts[b.authorId]]!;
    final distanceOrder = first.compareTo(second);
    return distanceOrder == 0 ? b.created.compareTo(a.created) : distanceOrder;
  });
  return matches;
}
