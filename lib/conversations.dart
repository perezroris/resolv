import 'package:flutter/material.dart';

import 'chat_models.dart';
import 'chat_job_card.dart';
import 'data.dart';
import 'ui.dart';

void openConversation(
  BuildContext context,
  AppData data,
  String peerId, {
  String? postId,
}) {
  if (peerId == data.currentId) return;
  data.markChatRead(peerId, postId: postId);
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => _ChatPage(data: data, peerId: peerId, postId: postId),
    ),
  );
}

String _day(BuildContext context, DateTime date) {
  final now = DateTime.now();
  if (DateUtils.isSameDay(date, now)) return 'Hoje';
  if (DateUtils.isSameDay(date, DateTime(now.year, now.month, now.day - 1))) {
    return 'Ontem';
  }
  return MaterialLocalizations.of(context).formatShortDate(date);
}

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key, required this.data});
  final AppData data;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Conversas'), centerTitle: false),
    body: SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: data,
        builder: (context, _) {
          final chats = data.inbox;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                itemCount: chats.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 8),
                      child: Text(
                        chats.isEmpty
                            ? 'Abra um perfil na Vitrine para começar a conversar.'
                            : 'Mensagens neste aparelho',
                        style: const TextStyle(
                          color: InkColors.muted,
                          fontSize: 15,
                        ),
                      ),
                    );
                  }
                  final chat = chats[index - 1],
                      peer = data.person(chat.peerId),
                      last = chat.messages.last;
                  final job = data.jobSummary(peer.id, postId: chat.postId);
                  return Material(
                    color: InkColors.white,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: InkColors.line),
                    ),
                    child: InkWell(
                      onTap: () => openConversation(
                        context,
                        data,
                        peer.id,
                        postId: chat.postId,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            PersonAvatar(peer, size: 46),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          peer.name,
                                          style: const TextStyle(
                                            color: InkColors.navy,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _day(context, last.sentAt),
                                        style: const TextStyle(
                                          color: InkColors.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (job.title.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        job.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: InkColors.blue,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${last.outgoing ? 'Você: ' : ''}${last.body}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: chat.unread
                                          ? InkColors.ink
                                          : InkColors.muted,
                                      fontWeight: chat.unread
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      height: 1.35,
                                    ),
                                  ),
                                  if (chat.unread)
                                    const Text(
                                      'Não lida',
                                      style: TextStyle(
                                        color: InkColors.blue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _ChatPage extends StatefulWidget {
  const _ChatPage({required this.data, required this.peerId, this.postId});
  final AppData data;
  final String peerId;
  final String? postId;
  @override
  State<_ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<_ChatPage> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_text.text.trim().isEmpty) return;
    widget.data.sendMessage(widget.peerId, _text.text, postId: widget.postId);
    _text.clear();
    await _afterSend();
  }

  Future<void> _editJob() async {
    final data = widget.data;
    final summary = await editChatJob(
      context,
      data.jobSummary(widget.peerId, postId: widget.postId),
    );
    if (summary == null || !mounted) return;
    data.updateJobSummary(widget.peerId, summary, postId: widget.postId);
    await _afterSend();
  }

  Future<void> _afterSend() async {
    if (_scroll.hasClients) _scroll.jumpTo(0);
    await widget.data.saved;
    if (mounted && widget.data.storageError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(widget.data.storageError!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final peer = widget.data.person(widget.peerId);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            PersonAvatar(peer, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                peer.name,
                style: const TextStyle(
                  color: InkColors.navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListenableBuilder(
                  listenable: widget.data,
                  builder: (_, _) => ChatJobCard(
                    summary: widget.data.jobSummary(
                      peer.id,
                      postId: widget.postId,
                    ),
                    fromPost: widget.postId != null,
                    onEdit: _editJob,
                  ),
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: widget.data,
                    builder: (context, _) {
                      final messages =
                          widget.data
                              .conversation(peer.id, postId: widget.postId)
                              ?.messages ??
                          const <ChatMessage>[];
                      if (messages.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Escreva a primeira mensagem.',
                              style: TextStyle(color: InkColors.muted),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: _scroll,
                        reverse: true,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final i = messages.length - 1 - index,
                              m = messages[i];
                          final start =
                              i == 0 ||
                              !DateUtils.isSameDay(
                                messages[i - 1].sentAt,
                                m.sentAt,
                              ) ||
                              messages[i - 1].example != m.example;
                          return Column(
                            children: [
                              if (start)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    '${m.example ? 'Histórico de exemplo · ' : ''}${_day(context, m.sentAt)}',
                                    style: const TextStyle(
                                      color: InkColors.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              _Bubble(message: m, peerName: peer.name),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _text,
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Escreva uma mensagem',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _text,
                        builder: (context, value, _) => IconButton.filled(
                          tooltip: 'Enviar mensagem',
                          onPressed: value.text.trim().isEmpty ? null : _send,
                          constraints: const BoxConstraints(
                            minHeight: 48,
                            minWidth: 48,
                          ),
                          icon: const Icon(Icons.arrow_upward_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.peerName});
  final ChatMessage message;
  final String peerName;
  @override
  Widget build(BuildContext context) {
    final mine = message.outgoing;
    final stamp = TimeOfDay.fromDateTime(message.sentAt).format(context);
    return Semantics(
      label: '${mine ? 'Você' : peerName}, $stamp: ${message.body}',
      excludeSemantics: true,
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: .83,
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Align(
            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: mine ? InkColors.navy : InkColors.white,
                border: Border.all(
                  color: mine ? InkColors.navy : InkColors.line,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.body,
                    style: TextStyle(
                      color: mine ? Colors.white : InkColors.ink,
                      fontSize: 16,
                      height: 1.35,
                    ),
                  ),
                  Text(
                    stamp,
                    style: TextStyle(
                      color: mine ? const Color(0xFFDCE9F6) : InkColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
