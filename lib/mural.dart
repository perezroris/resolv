import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data.dart';
import 'conversations.dart';
import 'estimate_fields.dart';
import 'job_summary.dart';
import 'ui.dart';

String _when(DateTime date) {
  final age = DateTime.now().difference(date);
  if (age.inMinutes < 1) return 'agora';
  if (age.inHours < 1) return 'há ${age.inMinutes} min';
  if (age.inDays < 1) return 'há ${age.inHours} h';
  if (age.inDays == 1) return 'ontem';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}

class MuralPage extends StatefulWidget {
  const MuralPage({super.key, required this.data});
  final AppData data;

  @override
  State<MuralPage> createState() => MuralPageState();
}

class MuralPageState extends State<MuralPage> {
  final _scroll = ScrollController();
  String _filter = 'Todos';
  String _tag = '';
  String _draftTag = '';
  String? _expanded;
  bool _composing = false;

  void showComposer(String? tag) {
    if (!_composing) {
      setState(() {
        _draftTag = tag ?? '';
        _composing = true;
      });
    }
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.data,
      builder: (context, _) {
        final posts = widget.data.posts
            .where(
              (post) =>
                  (_tag.isEmpty || post.tag == _tag) &&
                  (switch (_filter) {
                    'Em aberto' => !post.resolved,
                    'Resolvidos' => post.resolved,
                    _ => true,
                  }),
            )
            .toList();
        return CustomScrollView(
          key: const PageStorageKey('mural-feed'),
          controller: _scroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text('Mural', style: _title(context)),
                          ),
                        ),
                        if (!_composing)
                          FilledButton.icon(
                            onPressed: () => showComposer(_tag),
                            icon: const Icon(Icons.add_rounded, size: 19),
                            label: const Text('Pedir ajuda'),
                          ),
                      ],
                    ),
                    if (_composing)
                      _ComposeInline(
                        data: widget.data,
                        initialTag: _draftTag,
                        onCancel: () => setState(() => _composing = false),
                        onPublished: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          setState(() {
                            _composing = false;
                            _filter = 'Todos';
                            _tag = '';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pedido publicado no Mural.'),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: ['Todos', 'Em aberto', 'Resolvidos']
                                  .map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                        label: Text(item),
                                        selected: _filter == item,
                                        showCheckmark: false,
                                        onSelected: (_) =>
                                            setState(() => _filter = item),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Filtrar por tag',
                          initialValue: _tag,
                          onSelected: (tag) => setState(() => _tag = tag),
                          icon: Icon(Icons.tune_rounded, color: InkColors.navy),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: '',
                              child: Text('Todas as tags'),
                            ),
                            for (final tag in [adviceTag, ...serviceTags])
                              PopupMenuItem(value: tag, child: Text(tag)),
                          ],
                        ),
                      ],
                    ),
                    if (_tag.isNotEmpty)
                      InputChip(
                        label: Text(_tag),
                        onDeleted: () => setState(() => _tag = ''),
                        deleteButtonTooltipMessage: 'Remover filtro de tag',
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (posts.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Ainda não há pedidos nesta lista.'),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              sliver: SliverList.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Padding(
                    key: ValueKey(post.id),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PostCard(
                      post: post,
                      person: widget.data.person(post.authorId),
                      featured: index == 0,
                      expanded: _expanded == post.id,
                      data: widget.data,
                      onTap: () => setState(
                        () => _expanded = _expanded == post.id ? null : post.id,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class MuralPostPanel extends StatelessWidget {
  const MuralPostPanel({
    super.key,
    required this.data,
    required this.postId,
    required this.onBack,
    required this.backLabel,
  });

  final AppData data;
  final String postId;
  final VoidCallback onBack;
  final String backLabel;

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) onBack();
    },
    child: ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final post = data.post(postId);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(backLabel),
              ),
            ),
            Semantics(
              header: true,
              child: Text('Pedido no Mural', style: _title(context)),
            ),
            const SizedBox(height: 12),
            if (post == null)
              const Text('Este pedido já saiu do Mural.')
            else
              _PostCard(
                post: post,
                person: data.person(post.authorId),
                data: data,
                featured: false,
                expanded: true,
              ),
          ],
        );
      },
    ),
  );
}

class _ComposeInline extends StatefulWidget {
  const _ComposeInline({
    required this.data,
    required this.initialTag,
    required this.onCancel,
    required this.onPublished,
  });
  final AppData data;
  final String initialTag;
  final VoidCallback onCancel, onPublished;
  @override
  State<_ComposeInline> createState() => _ComposeInlineState();
}

class _ComposeInlineState extends State<_ComposeInline> {
  final _form = GlobalKey<FormState>();
  final _headline = TextEditingController();
  final _details = TextEditingController();
  final _amount = TextEditingController();
  var _unit = PriceUnit.service;
  bool _showEstimate = false;
  late String? _tag;
  String? _photo;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _tag = widget.initialTag.isEmpty ? null : widget.initialTag;
  }

  @override
  void dispose() {
    _headline.dispose();
    _details.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    setState(() => _picking = true);
    try {
      final path = await const MethodChannel('resolv/storage')
          .invokeMethod<String>('pickPhoto');
      if (mounted && path != null) setState(() => _photo = path);
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir a foto. Tente novamente.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _publish() {
    if (!_form.currentState!.validate() || _tag == null || _picking) return;
    widget.data.addPost(
      _headline.text.trim(),
      _details.text.trim(),
      _tag!,
      photo: _photo,
      estimate: _showEstimate ? Estimate.fromInput(_amount.text, _unit) : null,
    );
    widget.onPublished();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: InkColors.line),
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Novo pedido',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
                  ),
                ),
                IconButton(
                  onPressed: widget.onCancel,
                  tooltip: 'Cancelar pedido',
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _headline,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Título',
                counterText: '',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Dê um título ao pedido.'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _details,
              minLines: 2,
              maxLines: 5,
              maxLength: 1400,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                alignLabelWithHint: true,
                counterText: '',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Descreva o que aconteceu.'
                  : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _tag,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Tag do pedido'),
              items: [adviceTag, ...serviceTags]
                  .map((tag) => DropdownMenuItem(value: tag, child: Text(tag)))
                  .toList(),
              onChanged: (v) => setState(() => _tag = v),
              validator: (v) =>
                  v == null ? 'Escolha uma tag para publicar.' : null,
            ),
            const SizedBox(height: 9),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _showEstimate = !_showEstimate),
                icon: Icon(
                  _showEstimate
                      ? Icons.remove_circle_outline
                      : Icons.add_circle_outline,
                ),
                label: Text(
                  _showEstimate
                      ? 'Deixar a combinar'
                      : 'Informar valor estimado',
                ),
              ),
            ),
            if (_showEstimate) ...[
              EstimateFields(
                amount: _amount,
                unit: _unit,
                onUnitChanged: (unit) => setState(() => _unit = unit),
              ),
              const SizedBox(height: 12),
            ],
            if (_photo != null) _Photo(path: _photo!),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _picking
                      ? null
                      : (_photo != null
                            ? () => setState(() => _photo = null)
                            : _choosePhoto),
                  icon: Icon(
                    _photo == null
                        ? Icons.add_photo_alternate_outlined
                        : Icons.close_rounded,
                    size: 20,
                  ),
                  label: Text(_photo == null ? 'Anexar foto' : 'Remover foto'),
                ),
                FilledButton(
                  onPressed: _picking ? null : _publish,
                  child: const Text('Publicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle _title(BuildContext context) =>
    (Theme.of(context).textTheme.headlineLarge ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -1.5,
      color: InkColors.ink,
    );

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.person,
    required this.featured,
    this.onTap,
    required this.expanded,
    required this.data,
  });
  final Post post;
  final Person person;
  final bool featured;
  final bool expanded;
  final AppData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ink = featured ? Colors.white : InkColors.ink;
    final secondary = featured ? const Color(0xFFCFDDEB) : InkColors.muted;
    final border = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(23),
      side: BorderSide(color: featured ? InkColors.navy : InkColors.line),
    );
    return Material(
      color: featured ? InkColors.navy : Colors.white,
      shape: border,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(featured ? 20 : 16, 17, 16, 0),
              child: _Author(person: person, post: post, onDark: featured),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(featured ? 20 : 16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: expanded ? null : 3,
                    overflow: expanded ? null : TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: featured ? 25 : 19,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      letterSpacing: featured ? -.75 : -.35,
                      color: ink,
                    ),
                  ),
                  if (post.body.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      post.body,
                      maxLines: expanded ? null : 2,
                      overflow: expanded ? null : TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.42,
                        color: secondary,
                      ),
                    ),
                  ],
                  if (post.estimate != null) ...[
                    const SizedBox(height: 7),
                    Text(
                      'Estimativa · ${post.estimate!.label}',
                      style: TextStyle(color: ink, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            if (post.photo != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _Photo(path: post.photo!),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(featured ? 20 : 16, 13, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _TagLabel(tag: post.tag, dark: featured),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: '${post.comments.length} comentários',
                    excludeSemantics: true,
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: secondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${post.comments.length}',
                          style: TextStyle(color: secondary),
                        ),
                        if (onTap != null) ...[
                          const SizedBox(width: 3),
                          Icon(
                            expanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: secondary,
                            size: 19,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      color: featured
                          ? const Color(0xFF47657F)
                          : InkColors.line,
                    ),
                    if (post.authorId != data.currentId)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: ink),
                          onPressed: () => openConversation(
                            context,
                            data,
                            post.authorId,
                            postId: post.id,
                          ),
                          icon: const Icon(Icons.forum_outlined, size: 18),
                          label: const Text('Conversar com o morador'),
                        ),
                      ),
                    Semantics(
                      header: true,
                      child: Text(
                        'Comentários',
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (post.comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Ainda não há comentários.',
                          style: TextStyle(color: secondary),
                        ),
                      ),
                    for (final reply in post.comments)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    color: secondary,
                                    height: 1.35,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          '${data.person(reply.authorId).name}  ',
                                      style: TextStyle(
                                        color: ink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(text: reply.text),
                                  ],
                                ),
                              ),
                            ),
                            if (post.authorId == data.currentId &&
                                reply.authorId != data.currentId)
                              IconButton(
                                tooltip:
                                    'Conversar com ${data.person(reply.authorId).name}',
                                onPressed: () => openConversation(
                                  context,
                                  data,
                                  reply.authorId,
                                  postId: post.id,
                                ),
                                icon: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: ink,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    _CommentBox(onSend: (text) => data.comment(post.id, text)),
                    if (post.authorId == data.currentId && !post.resolved)
                      Wrap(
                        children: [
                          PopupMenuButton<String>(
                            tooltip: 'Alterar a tag do pedido',
                            initialValue: post.tag,
                            onSelected: (v) => data.changeTag(post.id, v),
                            itemBuilder: (_) => [adviceTag, ...serviceTags]
                                .map(
                                  (tag) => PopupMenuItem(
                                    value: tag,
                                    child: Text(tag),
                                  ),
                                )
                                .toList(),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'Editar tag',
                                style: TextStyle(color: ink),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => data.resolve(post.id),
                            style: TextButton.styleFrom(foregroundColor: ink),
                            child: const Text('Marcar como resolvido'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CommentBox extends StatefulWidget {
  const _CommentBox({required this.onSend});
  final ValueChanged<String> onSend;
  @override
  State<_CommentBox> createState() => _CommentBoxState();
}

class _CommentBoxState extends State<_CommentBox> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    controller.clear();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    textCapitalization: TextCapitalization.sentences,
    textInputAction: TextInputAction.send,
    onSubmitted: (_) => submit(),
    maxLength: 600,
    decoration: InputDecoration(
      filled: true,
      fillColor: InkColors.canvas,
      counterText: '',
      labelText: 'Comentar',
      suffixIcon: IconButton(
        onPressed: submit,
        tooltip: 'Enviar comentário',
        icon: const Icon(Icons.arrow_upward_rounded),
      ),
    ),
  );
}

class _TagLabel extends StatelessWidget {
  const _TagLabel({required this.tag, this.dark = false});
  final String tag;
  final bool dark;
  @override
  Widget build(BuildContext context) {
    if (!dark) return BrandTag(tag);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF385671),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          tag,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _Author extends StatelessWidget {
  const _Author({
    required this.person,
    required this.post,
    this.onDark = false,
  });
  final Person person;
  final Post post;
  final bool onDark;
  @override
  Widget build(BuildContext context) {
    final muted = onDark ? const Color(0xFFCFDDEB) : InkColors.muted;
    return Row(
      children: [
        PersonAvatar(person, size: 38),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                person.name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: onDark ? Colors.white : InkColors.ink,
                  fontSize: 14,
                ),
              ),
              Text(
                '${post.area ?? person.area} · ${_when(post.created)}',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          flex: 0,
          child: Text(
            post.resolved ? 'Resolvido' : 'Em aberto',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.path});
  final String path;
  @override
  Widget build(BuildContext context) {
    Widget failed(BuildContext context, Object error, StackTrace? trace) =>
        const SizedBox.shrink();
    final width =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round()
            .clamp(320, 1000);
    final img = path.startsWith('assets/')
        ? Image.asset(
            path,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 154,
            cacheWidth: width,
            errorBuilder: failed,
            semanticLabel: 'Foto do pedido',
          )
        : Image.file(
            File(path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: 154,
            cacheWidth: width,
            errorBuilder: failed,
            semanticLabel: 'Foto do pedido',
          );
    return ClipRRect(borderRadius: BorderRadius.circular(12), child: img);
  }
}
