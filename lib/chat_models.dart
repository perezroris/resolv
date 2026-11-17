import 'job_summary.dart';

class ChatMessage {
  const ChatMessage(
    this.body,
    this.sentAt, {
    required this.outgoing,
    this.example = false,
  });
  final String body;
  final DateTime sentAt;
  final bool outgoing, example;

  Map<String, Object?> toJson() => {
    'body': body,
    'at': sentAt.toIso8601String(),
    'outgoing': outgoing,
    'example': example,
  };
}

class Conversation {
  Conversation(
    this.peerId, {
    this.postId,
    this.unread = false,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];
  final String peerId;
  final String? postId;
  bool unread;
  JobSummary? summary;
  final List<ChatMessage> messages;

  Map<String, Object?> toJson() => {
    'peer': peerId,
    'post': postId,
    'unread': unread,
    'summary': summary?.toJson(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  static Conversation? restore(Map<String, dynamic> row, Set<String> peers) {
    final peer = row['peer'], post = row['post'], messages = row['messages'];
    if (!peers.contains(peer) ||
        (post != null && post is! String) ||
        messages is! List) {
      return null;
    }
    final result = Conversation(
      peer as String,
      postId: post as String?,
      unread: row['unread'] == true,
    );
    result.summary = JobSummary.restore(row['summary']);
    for (final m in messages.whereType<Map>()) {
      final body = m['body'], outgoing = m['outgoing'];
      final time = DateTime.tryParse(m['at']?.toString() ?? '');
      if (body is String &&
          body.trim().isNotEmpty &&
          time != null &&
          outgoing is bool) {
        result.messages.add(
          ChatMessage(
            body,
            time,
            outgoing: outgoing,
            example: m['example'] == true,
          ),
        );
      }
    }
    return result.messages.isEmpty ? null : result;
  }
}

List<Conversation> exampleConversations() {
  const examples = [
    (
      'u1',
      null,
      'Você dá aula de frações no Centro?',
      'Dou, sim! Posso levar os exercícios na quinta, às 15h.',
      'Quinta às 15h funciona para mim.',
    ),
    (
      'u5',
      null,
      'Lia, consigo levar duas calças para fazer a barra?',
      'Pode trazer amanhã depois das 14h. Traga também o sapato que costuma usar.',
      '',
    ),
    (
      'u6',
      'p3',
      'Oi, Paulo. Você consegue dar uma olhada na mancha do teto?',
      'Consigo passar na sexta de manhã para avaliar de perto.',
      'Pode ser às 9h?',
    ),
    (
      'u2',
      null,
      'Rafael, você monta estante de madeira?',
      'Monto! Para calcular o valor, preciso saber o tamanho e quantas prateleiras são.',
      '',
    ),
    (
      'u8',
      null,
      'Lúcia, você tem um horário para uma faxina no sábado?',
      'Tenho a manhã livre. São quantos quartos?',
      'São dois quartos e uma sala pequena.',
    ),
    (
      'u3',
      null,
      'Você consegue trocar o sifão da pia da cozinha?',
      'Consigo, sim. Posso passar no fim da tarde para ver a peça.',
      '',
    ),
  ];
  return [
    for (final (index, item) in examples.indexed)
      Conversation(
        item.$1,
        postId: item.$2,
        unread: index == 1,
        messages: [
          ChatMessage(
            item.$3,
            DateTime(2026, 11, 15 - index, 14, 12),
            outgoing: true,
            example: true,
          ),
          ChatMessage(
            item.$4,
            DateTime(2026, 11, 15 - index, 14, 17),
            outgoing: false,
            example: true,
          ),
          if (item.$5.isNotEmpty)
            ChatMessage(
              item.$5,
              DateTime(2026, 11, 15 - index, 14, 23),
              outgoing: true,
              example: true,
            ),
        ],
      ),
  ];
}

const demoJobs = <String, JobSummary>{
  'u1': JobSummary(
    'Reforço de matemática',
    'Aula individual de uma hora sobre frações, no Centro.',
    Estimate(5000, PriceUnit.hour),
  ),
  'u5': JobSummary(
    'Barra de duas calças',
    'Barra reta em duas calças. O valor é por peça.',
    Estimate(3500, PriceUnit.piece),
  ),
  'u2': JobSummary(
    'Montagem de estante',
    'Montagem de uma estante de madeira. Falta informar as medidas.',
  ),
  'u8': JobSummary(
    'Faxina no sábado',
    'Apartamento com dois quartos e uma sala pequena.',
  ),
  'u3': JobSummary(
    'Troca de sifão',
    'Avaliar a peça e trocar o sifão da pia da cozinha.',
  ),
};
