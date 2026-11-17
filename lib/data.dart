import 'dart:convert';

import 'chat_models.dart';
import 'job_summary.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const serviceTags = [
  'Hidráulica',
  'Elétrica',
  'Limpeza',
  'Pintura',
  'Montagem de móveis',
  'Pequenos reparos',
  'Jardinagem',
  'Costura',
  'Aulas particulares',
  'Informática',
  'Cuidados com pets',
  'Conserto de eletrodomésticos',
  'Fretes e mudanças',
  'Beleza',
  'Fotografia',
  'Culinária',
];
const adviceTag = 'Preciso de orientação';
const areas = [
  'Centro',
  'Jardim das Flores',
  'Vila Nova',
  'Bela Vista',
  'Santa Clara',
  'Vila Esperança',
  'Jardim Primavera',
  'Parque do Sol',
];

typedef Json = Map<String, dynamic>;

List<Json> _rows(Object? value) => value is List
    ? value.whereType<Map>().map((v) => Json.from(v)).toList()
    : <Json>[];
DateTime _date(dynamic value) =>
    DateTime.tryParse(value?.toString() ?? '') ??
    DateTime.fromMillisecondsSinceEpoch(0);

class Person {
  Person(
    this.id,
    this.name,
    this.area,
    this.bio, {
    this.professional = false,
    List<String>? tags,
    List<String>? areas,
    this.avatar,
  }) : tags = tags ?? [],
       areas = areas ?? [];
  final String id;
  String name, area, bio;
  final String? avatar;
  bool professional;
  List<String> tags, areas;
  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    return '${words.first[0]}${words.length > 1 ? words.last[0] : ''}'
        .toUpperCase();
  }
}

class Reply {
  Reply(this.authorId, this.text, this.created, {this.recommendedId});
  final String authorId, text;
  final DateTime created;
  final String? recommendedId;
  Json toJson() => {
    'author': authorId,
    'text': text,
    'at': created.toIso8601String(),
    'rec': recommendedId,
  };
  factory Reply.fromJson(Json j) =>
      Reply(j['author'], j['text'], _date(j['at']), recommendedId: j['rec']);
}

class Post {
  Post(
    this.id,
    this.authorId,
    this.title,
    this.body,
    this.tag,
    this.created, {
    this.resolved = false,
    this.photo,
    this.area,
    this.estimate,
    List<Reply>? comments,
  }) : comments = comments ?? [];
  final String id, authorId, title, body;
  String tag;
  final DateTime created;
  bool resolved;
  final String? photo;
  final Estimate? estimate;
  String? area;
  final List<Reply> comments;
  Json toJson() => {
    'id': id,
    'author': authorId,
    'title': title,
    'body': body,
    'tag': tag,
    'at': created.toIso8601String(),
    'resolved': resolved,
    'photo': photo,
    'estimate': estimate?.toJson(),
    'area': area,
    'comments': comments.map((c) => c.toJson()).toList(),
  };
  factory Post.fromJson(Json j) => Post(
    j['id'],
    j['author'],
    j['title'],
    j['body'] ?? '',
    j['tag'] ?? adviceTag,
    _date(j['at']),
    resolved: j['resolved'] == true,
    photo: j['photo'],
    estimate: Estimate.restore(j['estimate']),
    area: j['area'],
    comments: _rows(j['comments']).map(Reply.fromJson).toList(),
  );
}

class ServiceReview {
  const ServiceReview(this.postId, this.providerId, this.stars, this.note);
  final String postId, providerId, note;
  final int stars;
  Json toJson() => {
    'post': postId,
    'provider': providerId,
    'stars': stars,
    'note': note,
  };
}

class AppData extends ChangeNotifier {
  AppData() {
    _seed();
  }
  static const _storage = MethodChannel('resolv/storage');
  final List<Person> people = [];
  final List<Post> posts = [];
  final List<ServiceReview> reviews = [];
  final List<Conversation> _conversations = exampleConversations();

  List<Conversation> get inbox => _conversations.toList()
    ..sort((a, b) => b.messages.last.sentAt.compareTo(a.messages.last.sentAt));
  int get unreadChats => _conversations.where((c) => c.unread).length;
  Conversation? conversation(String peer, {String? postId}) => _conversations
      .where((c) => c.peerId == peer && c.postId == postId)
      .firstOrNull;

  void markChatRead(String peer, {String? postId}) {
    final chat = conversation(peer, postId: postId);
    if (chat == null || !chat.unread) return;
    chat.unread = false;
    _changed();
  }

  void sendMessage(String peer, String text, {String? postId}) {
    final body = text.trim();
    if (body.isEmpty) return;
    final chat = _getOrCreateChat(peer, postId);
    _appendOutgoing(chat, body);
  }

  Conversation _getOrCreateChat(String peer, String? postId) {
    if (peer == currentId || !people.any((p) => p.id == peer)) {
      throw ArgumentError('Escolha outro morador para conversar.');
    }
    final existing = conversation(peer, postId: postId);
    if (existing != null) return existing;

    if (postId != null) {
      final pedido = post(postId);
      if (pedido == null ||
          (pedido.authorId != peer && pedido.authorId != currentId)) {
        throw ArgumentError(
          'O pedido precisa pertencer a um dos participantes.',
        );
      }
    }
    final chat = Conversation(peer, postId: postId);
    _conversations.add(chat);
    return chat;
  }

  void _appendOutgoing(Conversation chat, String body) {
    chat.messages.add(ChatMessage(body, DateTime.now(), outgoing: true));
    chat.unread = false;
    _changed();
  }

  JobSummary jobSummary(String peer, {String? postId}) {
    final chat = conversation(peer, postId: postId);
    final summary = chat?.summary;
    if (summary != null) return summary;
    if (postId != null) {
      final pedido = post(postId);
      if (pedido != null) {
        return JobSummary(pedido.title, pedido.body, pedido.estimate);
      }
    } else if (chat != null && chat.messages.any((m) => m.example)) {
      final demo = demoJobs[peer];
      if (demo != null) return demo;
    }
    return const JobSummary('', '');
  }

  void updateJobSummary(String peer, JobSummary next, {String? postId}) {
    final before = jobSummary(peer, postId: postId);
    final title = next.title.trim(), details = next.description.trim();
    if (title.isEmpty || (next.price != null && next.price!.cents <= 0)) {
      throw ArgumentError('Informe o serviço e um valor válido.');
    }
    final changedScope = before.title != title || before.description != details;
    final changedPrice =
        before.price?.cents != next.price?.cents ||
        before.price?.unit != next.price?.unit;
    if (!changedScope && !changedPrice) return;
    final chat = _getOrCreateChat(peer, postId);
    chat.summary = JobSummary(title, details, next.price);
    final lines = [
      if (changedScope) 'Serviço: $title',
      if (changedScope && details.isNotEmpty) details,
      if (changedPrice && next.price != null) 'Proponho ${next.priceLabel}.',
      if (changedPrice && next.price == null)
        'Prefiro combinar o valor por aqui.',
      if (changedPrice && before.price != null)
        'Estimativa anterior: ${before.priceLabel}.',
    ];
    _appendOutgoing(chat, lines.join('\n'));
  }

  final String currentId = 'u0';
  String? storageError;
  Future<void> _pending = Future<void>.value();
  int _sequence = 0;
  String _next(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';
  Person get me => person(currentId);
  Person person(String id) => people.firstWhere((p) => p.id == id);
  Post? post(String id) => posts.where((p) => p.id == id).firstOrNull;
  bool _validTag(String tag) => tag == adviceTag || serviceTags.contains(tag);

  void editProfile(String name, String area, String bio) {
    if (name.trim().isEmpty || !areas.contains(area)) {
      throw ArgumentError('Informe seu nome e seu bairro.');
    }
    if (me.area != area) {
      for (final post in posts.where((p) => p.authorId == currentId)) {
        post.area ??= me.area;
      }
    }
    me.name = name.trim();
    me.area = area;
    me.bio = bio.trim();
    _changed();
  }

  void reviewService(String postId, String providerId, int stars, String note) {
    final item = post(postId);
    if (item == null ||
        item.authorId != currentId ||
        !item.resolved ||
        providerId == currentId ||
        !people.any((resident) => resident.id == providerId) ||
        stars < 1 ||
        stars > 5 ||
        reviews.any((review) => review.postId == postId)) {
      throw StateError('Este atendimento não pode ser avaliado.');
    }
    reviews.add(ServiceReview(postId, providerId, stars, note.trim()));
    _changed();
  }

  void setProfessional(
    bool enabled, {
    List<String>? tags,
    List<String>? serviceAreas,
  }) {
    final person = me;
    if (enabled) {
      final specialties = serviceTags
          .where((tag) => (tags ?? person.tags).contains(tag))
          .toList();
      final coverage = areas
          .where((area) => (serviceAreas ?? person.areas).contains(area))
          .toList();
      if (specialties.isEmpty || coverage.isEmpty) {
        throw ArgumentError(
          'Escolha pelo menos uma especialidade e um bairro.',
        );
      }
      person.tags = specialties;
      person.areas = coverage;
    }
    person.professional = enabled;
    _changed();
  }

  Post addPost(
    String title,
    String body,
    String tag, {
    String? photo,
    Estimate? estimate,
  }) {
    if (title.trim().isEmpty || !_validTag(tag)) {
      throw ArgumentError('Informe o título e a tag.');
    }
    final item = Post(
      _next('p'),
      currentId,
      title.trim(),
      body.trim(),
      tag,
      DateTime.now(),
      photo: photo,
      area: me.area,
      estimate: estimate,
    );
    posts.insert(0, item);
    _changed();
    return item;
  }

  void changeTag(String postId, String tag) {
    final item = post(postId);
    if (item == null ||
        item.authorId != currentId ||
        item.resolved ||
        !_validTag(tag)) {
      return;
    }
    item.tag = tag;
    _changed();
  }

  void comment(String postId, String body, {String? recommendedId}) {
    final item = post(postId);
    if (item == null || body.trim().isEmpty) return;
    if (recommendedId != null &&
        !people.any((p) => p.id == recommendedId && p.professional)) {
      return;
    }
    item.comments.add(
      Reply(
        currentId,
        body.trim(),
        DateTime.now(),
        recommendedId: recommendedId,
      ),
    );
    _changed();
  }

  void resolve(String postId) {
    final item = post(postId);
    if (item == null || item.authorId != currentId || item.resolved) return;
    item.resolved = true;
    _changed();
  }

  Future<void> load() async {
    try {
      final raw = await _storage.invokeMethod<String>('read');
      if (raw == null || raw.isEmpty) return;
      final j = Json.from(jsonDecode(raw) as Map);
      if (j['version'] != 1) return;
      if (j['conversations'] is List) {
        final peers = people
            .where((p) => p.id != currentId)
            .map((p) => p.id)
            .toSet();
        _conversations.clear();
        for (final row in _rows(j['conversations'])) {
          final chat = Conversation.restore(row, peers);
          if (chat != null &&
              conversation(chat.peerId, postId: chat.postId) == null) {
            _conversations.add(chat);
          }
        }
      }
      final savedPosts = _rows(j['posts']).map(Post.fromJson).toList();
      if (j['posts'] is List) {
        final savedIds = savedPosts.map((post) => post.id).toSet();
        final newExamples = posts
            .where(
              (post) =>
                  post.id.startsWith('extra-') && !savedIds.contains(post.id),
            )
            .toList();
        posts
          ..clear()
          ..addAll(savedPosts)
          ..addAll(newExamples);
      }
      final personal = j['personalProfile'];
      if (personal is Map) {
        final name = personal['name'];
        final area = personal['area'];
        final bio = personal['bio'];
        if (name is String && name.trim().isNotEmpty) me.name = name.trim();
        if (area is String && areas.contains(area)) me.area = area;
        if (bio is String) me.bio = bio;
      }
      reviews.clear();
      for (final row in _rows(j['reviews'])) {
        final postId = row['post'],
            provider = row['provider'],
            stars = row['stars'];
        if (postId is String &&
            post(postId)?.resolved == true &&
            provider is String &&
            people.any((p) => p.id == provider) &&
            stars is int &&
            stars >= 1 &&
            stars <= 5 &&
            !reviews.any((r) => r.postId == postId)) {
          reviews.add(
            ServiceReview(
              postId,
              provider,
              stars,
              row['note'] is String ? row['note'] : '',
            ),
          );
        }
      }
      final preferences = j['professionalProfile'];
      if (preferences is Map) {
        final tags = preferences['tags'];
        final coverage = preferences['areas'];
        me.tags = tags is List ? serviceTags.where(tags.contains).toList() : [];
        me.areas = coverage is List
            ? areas.where(coverage.contains).toList()
            : [];
        me.professional =
            preferences['active'] == true &&
            me.tags.isNotEmpty &&
            me.areas.isNotEmpty;
      }
    } on MissingPluginException {
      return;
    } catch (_) {
      storageError = 'Não foi possível ler os dados salvos neste aparelho.';
    }
    notifyListeners();
  }

  void _changed() {
    final encoded = jsonEncode({
      'version': 1,
      'user': currentId,
      'personalProfile': {'name': me.name, 'area': me.area, 'bio': me.bio},
      'reviews': reviews.map((r) => r.toJson()).toList(),
      'conversations': _conversations.map((c) => c.toJson()).toList(),
      'professionalProfile': {
        'active': me.professional,
        'tags': me.tags,
        'areas': me.areas,
      },
      'posts': posts.map((p) => p.toJson()).toList(),
    });
    _pending = _pending.then((_) async {
      try {
        await _storage.invokeMethod<void>('write', encoded);
        storageError = null;
      } on MissingPluginException {
        return;
      } catch (_) {
        storageError =
            'Não foi possível salvar a última alteração no aparelho.';
      }
    });
    notifyListeners();
  }

  Future<void> get saved => _pending;

  void _seed() {
    const names = [
      'Júlia Martins',
      'Ana Ribeiro',
      'Rafael Dias',
      'Celina Moraes',
      'Bia Azevedo',
      'Lia Ramos',
      'Paulo Nunes',
      'Bruno Tavares',
      'Lúcia',
      'Mateus',
      'Regina',
      'Arthur',
      'Célia',
      'Marcos',
      'Luana',
      'Pedro',
      'Nádia',
      'Caio',
      'Marta',
      'Gilberto',
      'Carla',
      'João',
      'Elisa',
      'Daniel',
      'Sandra',
      'Ravi',
      'Teresa',
      'Vitor',
      'Camila',
      'Antônio',
      'Rita',
      'Diogo',
      'Lara',
      'Gabriel',
      'Flávia',
      'André',
      'Denise',
      'Raul',
      'Yara',
      'Fabiano',
      'Neide',
      'Enzo',
      'Clara',
      'José',
      'Mônica',
      'Felipe',
      'Íris',
      'Jonas',
      'Talita',
      'Samuel',
      'Olívia',
      'Elias',
      'Vera',
      'Henrique',
      'Laura',
      'Fábio',
      'Marina',
      'Eduardo',
      'Dora',
      'Chico',
      'Aline',
      'Murilo',
      'Valéria',
      'Heitor',
      'Eliana',
      'Lucas',
      'Sara',
      'Otávio',
      'Angela',
      'Gustavo',
      'Sol',
      'Vinícius',
      'Patrícia',
      'Davi',
      'Helena',
      'Joel',
      'Inês',
      'Alfredo',
      'Noemi',
      'Cássio',
    ];
    const surnames = [
      'Lima',
      'Santos',
      'Pereira',
      'Andrade',
      'Maia',
      'Teixeira',
      'Alves',
      'Rocha',
      'Campos',
    ];
    const portraits = {
      1: 'assets/ana.jpg',
      5: 'assets/lia.jpg',
      6: 'assets/paulo.jpg',
    };
    for (var i = 0; i < names.length; i++) {
      final fullName = i < 8
          ? names[i]
          : '${names[i]} ${surnames[i % surnames.length]}';
      final district = i == 4 ? areas.first : areas[i % areas.length];
      people.add(Person('u$i', fullName, district, '', avatar: portraits[i]));
    }
    final now = DateTime.now();
    for (var i = 0; i < _feed.length; i++) {
      final (author, category, title, body, photo) = _feed[i];
      final p = Post(
        'p$i',
        'u$author',
        title,
        body,
        category < 0 ? adviceTag : serviceTags[category],
        now.subtract(Duration(minutes: 12 + i * 34)),
        photo: photo,
        resolved: i >= 21 && i % 4 == 1,
      );
      posts.add(p);
    }
    posts.first.comments.addAll([
      Reply(
        'u6',
        'Sou do Centro. Ela soltou dos dois lados ou só do lado de dentro?',
        now.subtract(const Duration(minutes: 8)),
      ),
      Reply(
        'u4',
        'Só do lado de dentro, Paulo. O de fora continua firme.',
        now.subtract(const Duration(minutes: 5)),
      ),
    ]);
    posts[1].comments.add(
      Reply(
        'u5',
        'Faço esse ajuste, sim. Você já tem uma calça com a medida certa?',
        now.subtract(const Duration(minutes: 19)),
      ),
    );
    posts[2].comments.add(
      Reply(
        'u1',
        'Consigo levar alguns exercícios para a primeira aula.',
        now.subtract(const Duration(minutes: 47)),
      ),
    );
    for (var i = 0; i < _otherTitles.length; i++) {
      final (category, title, body) = _otherTitles[i];
      final index = posts.length;
      posts.add(
        Post(
          'p$index',
          'u${(index * 17 + 5) % people.length}',
          title,
          body,
          category < 0 ? adviceTag : serviceTags[category],
          now.subtract(Duration(minutes: 12 + index * 34)),
          resolved: index >= 70,
        ),
      );
    }
    for (final (id, author, tag, title, body) in _newServiceExamples) {
      posts.add(
        Post(
          'extra-$id',
          'u$author',
          title,
          body,
          tag,
          now.subtract(Duration(days: 3, hours: id)),
        ),
      );
    }
  }
}

const _newServiceExamples = <(int, int, String, String, String)>[
  (
    1,
    8,
    'Fretes e mudanças',
    'Preciso buscar uma mesa usada',
    'A mesa tem quatro lugares e já está desmontada. A retirada e a entrega são aqui no Centro.',
  ),
  (
    2,
    16,
    'Beleza',
    'Alguém faz tranças em casa?',
    'Procuro alguém para trançar meu cabelo no sábado de manhã.',
  ),
  (
    3,
    24,
    'Fotografia',
    'Fotos para um catálogo de peças de cerâmica',
    'São seis peças pequenas. Tenho um espaço com luz natural para fotografar.',
  ),
  (
    4,
    32,
    'Culinária',
    'Quem prepara marmitas para congelar?',
    'Quero combinar um cardápio para duas pessoas e buscar as porções no bairro.',
  ),
  (
    5,
    12,
    'Fretes e mudanças',
    'Levar caixas para o apartamento novo',
    'As duas portarias têm elevador. São dez caixas e uma bicicleta.',
  ),
  (
    6,
    2,
    'Beleza',
    'Corte de cabelo em domicílio',
    'Minha avó prefere receber alguém em casa. Pode ser em uma tarde desta semana.',
  ),
  (
    7,
    1,
    'Fotografia',
    'Aniversário no salão do prédio',
    'Queria fotos da família e do parabéns. A comemoração dura duas horas.',
  ),
  (
    8,
    13,
    'Culinária',
    'Bolo de cenoura para o lanche da escola',
    'Precisamos de um bolo para vinte pessoas na quarta de manhã.',
  ),
];

const _feed = <(int, int, String, String, String?)>[
  (
    4,
    5,
    'Quem conserta essa dobradiça?',
    'A dobradiça da porta de entrada ficou solta. Alguém aqui do bairro consegue dar uma olhada?',
    'assets/reparos.jpg',
  ),
  (
    3,
    7,
    'Preciso fazer a barra de dois uniformes',
    'As calças já estão com a medida marcada. Consigo levar as peças hoje depois das 17h.',
    null,
  ),
  (
    13,
    8,
    'Aulas de matemática para o 7º ano',
    'Meu filho está estudando frações e queria rever os exercícios com alguém daqui. Ele tem as tardes livres.',
    'assets/aulas.jpg',
  ),
  (
    0,
    -1,
    'Apareceu uma mancha no teto da sala',
    'Foi logo depois da chuva. Alguém sabe qual profissional pode avaliar de onde vem a umidade?',
    null,
  ),
  (
    5,
    7,
    'Alguém ajusta uma saia de linho?',
    'O comprimento está certo, mas preciso apertar um pouco a cintura. Posso levar até o ateliê.',
    'assets/costura.jpg',
  ),
  (
    10,
    0,
    'Torneira da cozinha pingando',
    'O registro fecha e a torneira continua pingando. Procuro alguém para avaliar durante a semana.',
    null,
  ),
  (
    14,
    4,
    'Alguém monta uma mesa dobrável?',
    'A mesa veio desmontada, com as peças e o manual. Queria deixar tudo pronto antes de sábado.',
    null,
  ),
  (
    16,
    10,
    'Passeio com o Tobias no sábado',
    'Meu cachorro já está acostumado à guia. Queria combinar um passeio curto no fim da tarde.',
    null,
  ),
  (
    20,
    2,
    'Limpeza de janelas que dão para a varanda',
    'São três janelas de correr, todas acessíveis pelo chão da varanda.',
    null,
  ),
  (
    18,
    9,
    'Ajuda para organizar fotos no celular',
    'Minha mãe quer separar as fotos por ano e fazer uma cópia no computador dela.',
    null,
  ),
  (
    22,
    6,
    'Replantio de uma jabuticabeira em vaso',
    'A muda cresceu e já tenho um vaso maior. Preciso de ajuda para fazer a troca.',
    null,
  ),
  (
    25,
    3,
    'Pintura de uma parede no quarto',
    'A parede tem uns três metros. Já escolhi a cor e gostaria de combinar o preparo e a pintura.',
    null,
  ),
  (
    30,
    -1,
    'Quem pode ver um barulho na janela?',
    'Quando venta, a esquadria faz um barulho. Qual serviço devo procurar?',
    null,
  ),
  (
    28,
    11,
    'Batedeira parou de girar',
    'O motor faz barulho, mas o batedor fica parado. Procuro alguém que conserte esse modelo.',
    null,
  ),
  (
    32,
    1,
    'Instalação de luminária na sala',
    'A luminária nova já chegou. Preciso de um eletricista para instalar no ponto existente.',
    null,
  ),
  (
    24,
    8,
    'Reforço de português para vestibular',
    'Queria praticar redação uma vez por semana e receber comentários nos textos.',
    null,
  ),
  (
    38,
    5,
    'Recolocar um puxador de gaveta',
    'O puxador soltou com um pedaço da madeira. Ainda tenho a peça original.',
    null,
  ),
  (
    34,
    4,
    'Desmontagem de uma estante antes da mudança',
    'Gostaria de guardar as peças e parafusos em ordem para montar no outro endereço.',
    null,
  ),
  (
    41,
    -1,
    'Como descobrir o tamanho do trilho?',
    'Preciso trocar uma peça da cortina e queria uma indicação de onde começar.',
    null,
  ),
  (
    44,
    0,
    'Reparo na descarga do banheiro',
    'A água continua correndo depois de apertar o botão. Tenho foto da caixa.',
    null,
  ),
  (
    46,
    7,
    'Troca do zíper da mochila',
    'O tecido está inteiro. Só o cursor e os dentes do zíper estão gastos.',
    null,
  ),
  (
    50,
    6,
    'Poda da roseira do quintal',
    'Ela cresceu sobre a passagem. Procuro alguém com experiência em poda de roseiras.',
    null,
  ),
  (
    52,
    2,
    'Faxina depois de uma mudança',
    'O apartamento está vazio. São dois quartos, sala e cozinha.',
    null,
  ),
  (
    55,
    10,
    'Visitas para alimentar duas gatas',
    'Vou viajar no fim de semana e preciso combinar os horários da alimentação.',
    null,
  ),
];
const _otherTitles = <(int, String, String)>[
  (
    0,
    'Trocar o sifão da pia',
    'A pia do banheiro está vazando embaixo. Tenho disponibilidade pela manhã.',
  ),
  (
    1,
    'Instalar tomada para o escritório',
    'Preciso de uma avaliação antes de comprar o material.',
  ),
  (
    2,
    'Limpeza dos azulejos da cozinha',
    'A cozinha é pequena e consigo deixar os armários livres.',
  ),
  (
    3,
    'Pintar a porta da varanda',
    'A madeira já está exposta em alguns pontos. Queria orçamento para preparar e pintar.',
  ),
  (
    4,
    'Montagem de um armário de duas portas',
    'Tenho o manual de montagem e todas as caixas originais.',
  ),
  (
    5,
    'Trocar rodízios de uma cadeira',
    'É uma cadeira de escritório. Posso mandar a medida dos encaixes.',
  ),
  (
    6,
    'Ajuda com a horta da varanda',
    'Quero reorganizar os temperos e separar os que precisam de mais sol.',
  ),
  (
    7,
    'Ajustar manga do blazer',
    'A manga ficou longa. Consigo levar a peça para tirar as medidas.',
  ),
  (
    8,
    'Aulas de inglês para viagem',
    'Quero praticar conversação básica uma vez por semana.',
  ),
  (
    9,
    'Configurar a impressora de casa',
    'A impressora funciona pelo cabo, mas não encontro a rede sem fio.',
  ),
  (
    10,
    'Cuidado com coelho durante a viagem',
    'Deixo as porções de comida separadas e a rotina por escrito.',
  ),
  (
    11,
    'Avaliação de liquidificador',
    'O copo está bom, mas a base deixou de ligar.',
  ),
  (
    -1,
    'A porta de correr está pesada',
    'Não sei se é o trilho ou uma peça da porta. Alguém já resolveu algo assim?',
  ),
  (
    0,
    'Instalar filtro na bancada',
    'O filtro chegou com as conexões. Preciso conferir se servem na minha torneira.',
  ),
  (
    1,
    'Trocar um interruptor duplo',
    'Um dos botões não fica mais no lugar. Posso enviar foto do modelo.',
  ),
  (
    2,
    'Limpar o sofá de dois lugares',
    'Queria saber como funciona a limpeza em casa e o tempo para secar.',
  ),
  (
    3,
    'Renovar a pintura do corredor',
    'O corredor está livre. Posso receber uma visita na terça.',
  ),
  (
    4,
    'Montar cama com baú',
    'As peças estão no quarto e a estrutura ainda está embalada.',
  ),
  (
    5,
    'Fixar suporte de cortina',
    'Um dos suportes soltou. Quero deixar o varão nivelado de novo.',
  ),
  (
    6,
    'Manutenção do jardim em frente de casa',
    'Preciso tirar ervas do canteiro e aparar a grama.',
  ),
  (
    7,
    'Fazer capa de almofada',
    'Já comprei o tecido e tenho uma capa de exemplo.',
  ),
  (
    8,
    'Ajuda com física do ensino médio',
    'O assunto agora é movimento. Tenho as listas da escola.',
  ),
  (
    9,
    'Rever o Wi-Fi no quarto',
    'O sinal pega bem na sala e cai quando vou para o fundo da casa.',
  ),
  (
    10,
    'Passeios de manhã com a Mel',
    'É uma cadela tranquila, porte médio. Gostaria de combinar duas manhãs por semana.',
  ),
  (
    11,
    'Ventilador com hélice travando',
    'Queria saber se vale a pena trocar a peça. Posso levar à oficina.',
  ),
  (
    -1,
    'A gaveta não fecha até o fim',
    'Não encontrei nada preso atrás dela. Quem costuma mexer com isso?',
  ),
  (
    0,
    'Reparo no registro do tanque',
    'Ao abrir o registro, pinga água perto da parede.',
  ),
  (
    1,
    'Revisar a campainha do portão',
    'Parou de tocar esta semana e quero uma avaliação.',
  ),
  (2, 'Limpar o box do banheiro', 'O vidro ficou manchado depois da reforma.'),
  (
    3,
    'Retocar a pintura perto da janela',
    'Tenho a lata da tinta usada na última pintura.',
  ),
  (
    4,
    'Montar escrivaninha da minha filha',
    'A mesa tem uma gaveta. As peças chegaram numeradas.',
  ),
  (
    5,
    'Colocar prateleira de livros',
    'A madeira e os suportes já estão aqui. Queria conferir a fixação na parede.',
  ),
  (
    6,
    'Preparar terra para mudas',
    'Quero plantar manjericão e salsinha em duas jardineiras.',
  ),
  (
    7,
    'Refazer a bainha de uma cortina',
    'A barra precisa subir alguns centímetros nas duas partes.',
  ),
  (
    8,
    'Acompanhamento de alfabetização',
    'Minha filha quer praticar leitura no contraturno da escola.',
  ),
  (
    9,
    'Copiar os arquivos do notebook antigo',
    'Quero preservar os documentos e passar tudo para o computador novo.',
  ),
  (
    10,
    'Alimentar o gato na hora do almoço',
    'Vou passar o dia fora e queria combinar uma visita curta.',
  ),
  (
    11,
    'Consertar o cabo da panela elétrica',
    'A conexão parece frouxa. Estou procurando assistência aqui perto.',
  ),
  (
    -1,
    'A parede começou a descascar',
    'A pintura é recente. Qual profissional verifica a causa antes de repintar?',
  ),
  (
    0,
    'Vazamento perto do tanque',
    'Notei água no chão depois de usar a lavanderia. Consigo receber uma visita amanhã.',
  ),
  (
    1,
    'Mudar luminária de lugar',
    'Quero reposicionar a luz da mesa de jantar e avaliar o ponto elétrico.',
  ),
  (
    2,
    'Faxina de fim de obra na sala',
    'Tem pó fino nos rodapés e nas janelas. O piso já está liberado.',
  ),
  (
    3,
    'Lixar e pintar uma banqueta',
    'Ela é de madeira e está em bom estado. Queria renovar a cor.',
  ),
  (
    4,
    'Montar nichos no quarto',
    'São três nichos do mesmo tamanho, já com ferragens.',
  ),
  (
    5,
    'Regular a dobradiça do armário',
    'A porta está raspando quando abre e fecha.',
  ),
  (
    6,
    'Orientação para cuidar das orquídeas',
    'Ganhei três vasos e queria ajuda para escolher um canto da casa.',
  ),
  (
    7,
    'Ajustar um vestido para festa',
    'Preciso acertar o comprimento e consigo ir fazer a prova.',
  ),
  (
    8,
    'Revisar química antes da prova',
    'Tenho dúvidas em ligações químicas e gostaria de uma aula nesta semana.',
  ),
  (
    9,
    'Instalar programas de acessibilidade',
    'Quero configurar letras maiores e leitura em voz alta no computador.',
  ),
  (
    10,
    'Levar o Bento para caminhar',
    'Procuro alguém que se sinta à vontade com um cachorro idoso.',
  ),
  (
    11,
    'Trocar borracha da geladeira',
    'A porta está fechando mal e preciso conferir o modelo da borracha.',
  ),
  (
    -1,
    'O tapete escorrega pelo corredor',
    'Alguém tem indicação de quem faz um acabamento adequado?',
  ),
  (
    0,
    'Conexão para a máquina de lavar',
    'Mudei de casa e preciso adaptar a entrada e a saída de água.',
  ),
  (
    1,
    'Avaliar iluminação da escada',
    'Alguns degraus ficam escuros à noite. Queria conversar sobre opções.',
  ),
  (
    2,
    'Organizar a despensa depois da reforma',
    'Os armários estão vazios. Preciso limpar por dentro e recolocar os potes.',
  ),
  (
    3,
    'Pintar o portão pequeno',
    'Quero preparar o metal antes da pintura. Posso mandar as medidas.',
  ),
  (
    4,
    'Desmontar beliche para transporte',
    'Preciso separar as ferragens e proteger as partes de madeira.',
  ),
  (
    5,
    'Instalar espelho no hall',
    'Já tenho o espelho e a indicação de peso da embalagem.',
  ),
  (
    6,
    'Trocar os vasos das folhagens',
    'As raízes estão aparecendo. Os vasos novos chegam amanhã.',
  ),
  (
    7,
    'Reparar a alça de uma bolsa',
    'A costura abriu, mas a alça ainda está inteira.',
  ),
  (
    8,
    'Aulas de violão para iniciante',
    'Tenho um violão em casa e gostaria de começar por acordes simples.',
  ),
  (
    9,
    'Ajuda para usar chamada de vídeo',
    'Quero deixar os contatos da família fáceis de encontrar no celular.',
  ),
  (
    10,
    'Água e ração para duas calopsitas',
    'Preciso de alguém com experiência com aves para uma visita no sábado.',
  ),
  (
    11,
    'Avaliar o ferro de passar',
    'Ele esquenta pouco mesmo na posição mais alta.',
  ),
  (
    -1,
    'A porta do banheiro encosta no chão',
    'Não sei se é a dobradiça ou a madeira que inchou. Quem pode verificar?',
  ),
  (
    0,
    'Conferir a vedação do chuveiro',
    'Depois do banho há um gotejamento perto da conexão.',
  ),
  (
    1,
    'Revisão de ponto de luz na varanda',
    'A lâmpada nova também não acendeu. Gostaria de marcar uma visita.',
  ),
  (
    2,
    'Limpeza de duas poltronas',
    'São de tecido claro. Posso mandar foto antes do orçamento.',
  ),
  (
    3,
    'Pintar uma parede da cozinha',
    'Preciso de ajuda para escolher a tinta apropriada para a superfície.',
  ),
  (
    4,
    'Montar um criado-mudo',
    'A peça é pequena, mas veio com trilhos para duas gavetas.',
  ),
  (
    5,
    'Substituir fecho da janela',
    'O fecho ainda abre, mas deixou de travar.',
  ),
  (
    6,
    'Aparar a cerca viva',
    'A cerca acompanha o muro da frente e precisa de uma poda regular.',
  ),
  (
    7,
    'Costurar aventais de cozinha',
    'Tenho o tecido e queria fazer duas peças iguais.',
  ),
  (
    8,
    'Revisão de história do Brasil',
    'Tenho um roteiro da escola e gostaria de discutir os tópicos em uma aula.',
  ),
  (
    9,
    'Organizar documentos no computador',
    'Queria separar os arquivos por assunto e aprender a fazer a cópia de segurança.',
  ),
  (
    10,
    'Companhia para uma cadela recém-adotada',
    'Ela ainda está se acostumando à casa. Queria combinar uma visita de apresentação.',
  ),
];
