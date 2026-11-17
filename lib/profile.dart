import 'package:flutter/material.dart';

import 'data.dart';
import 'directory.dart';
import 'services.dart';
import 'ui.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.data, required this.onOpenPost});
  final AppData data;
  final ValueChanged<String> onOpenPost;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _showReviews = false;

  void _edit(Widget sheet) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => sheet,
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.data,
    builder: (context, _) {
      final data = widget.data;
      final me = data.me;
      final mine = data.posts.where((p) => p.authorId == me.id).toList()
        ..sort((a, b) => b.created.compareTo(a.created));
      final given = data.reviews
          .where((r) => data.post(r.postId)?.authorId == me.id)
          .toList()
          .reversed;
      final received = data.reviews
          .where((r) => r.providerId == me.id)
          .toList()
          .reversed;
      return ListView(
        key: const PageStorageKey('profile'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                header: true,
                child: const Text(
                  'Perfil',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: InkColors.ink,
                    letterSpacing: -1.4,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _edit(_PersonalEditor(data: data)),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar perfil'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: InkColors.navy,
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PersonAvatar(me, size: 60),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            me.name,
                            style: const TextStyle(
                              fontSize: 23,
                              letterSpacing: -.5,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            me.area,
                            style: const TextStyle(
                              color: Color(0xFFDCE9F6),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (me.bio.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      me.bio,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Quero oferecer serviços',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: InkColors.navy,
                    ),
                  ),
                  subtitle: Text(
                    me.professional
                        ? 'Seu perfil aparece na Vitrine.'
                        : 'Divulgue seu trabalho para os vizinhos.',
                  ),
                  value: me.professional,
                  onChanged: (enabled) {
                    if (enabled) {
                      showServiceSettings(context, data, startEnabled: true);
                    } else {
                      data.setProfessional(false);
                    }
                  },
                ),
                if (me.professional) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    children: [for (final tag in me.tags) BrandTag(tag)],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    me.areas.join(' · '),
                    style: const TextStyle(color: InkColors.muted),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => showServiceSettings(context, data),
                      child: const Text('Ajustar atendimento'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('Meus pedidos')),
              ButtonSegment(value: true, label: Text('Avaliações')),
            ],
            selected: {_showReviews},
            onSelectionChanged: (value) =>
                setState(() => _showReviews = value.single),
          ),
          const SizedBox(height: 14),
          if (!_showReviews) ...[
            if (mine.isEmpty)
              const Text(
                'Seus pedidos vão aparecer aqui quando você publicar no Mural.',
              ),
            for (final post in mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => widget.onOpenPost(post.id),
                        title: Text(
                          post.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: InkColors.ink,
                          ),
                        ),
                        subtitle: Text(
                          '${post.resolved ? 'Resolvido' : 'Em aberto'} · ${post.tag}',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                      if (post.resolved &&
                          !data.reviews.any((r) => r.postId == post.id))
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () =>
                                _edit(_ReviewEditor(data: data, post: post)),
                            icon: const Icon(
                              Icons.star_outline_rounded,
                              size: 18,
                            ),
                            label: const Text('Avaliar atendimento'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ] else ...[
            _reviewSection(
              'Recebidas',
              'Você ainda não recebeu avaliações.',
              received,
              true,
            ),
            const SizedBox(height: 12),
            _reviewSection(
              'Enviadas',
              'Você pode avaliar um atendimento na lista de pedidos resolvidos.',
              given,
              false,
            ),
          ],
        ],
      );
    },
  );

  Widget _reviewSection(
    String title,
    String empty,
    Iterable<ServiceReview> entries,
    bool received,
  ) {
    final data = widget.data;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: InkColors.navy,
              ),
            ),
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                empty,
                style: const TextStyle(color: InkColors.muted),
              ),
            ),
          for (final entry in entries) ...[
            const SizedBox(height: 10),
            Text(
              '${data.person(received ? data.post(entry.postId)!.authorId : entry.providerId).name} · ${entry.stars}/5',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(data.post(entry.postId)!.title),
            if (entry.note.isNotEmpty)
              Text(entry.note, style: const TextStyle(color: InkColors.muted)),
          ],
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: InkColors.line),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: child,
    ),
  );
}

class _PersonalEditor extends StatefulWidget {
  const _PersonalEditor({required this.data});
  final AppData data;
  @override
  State<_PersonalEditor> createState() => _PersonalEditorState();
}

class _PersonalEditorState extends State<_PersonalEditor> {
  final _form = GlobalKey<FormState>();
  late String _name = widget.data.me.name,
      _area = widget.data.me.area,
      _bio = widget.data.me.bio;
  @override
  Widget build(BuildContext context) => _Editor(
    title: 'Editar perfil',
    child: Form(
      key: _form,
      child: Column(
        children: [
          TextFormField(
            initialValue: _name,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nome',
              counterText: '',
            ),
            onSaved: (v) => _name = v!.trim(),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Informe seu nome.' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _area,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Meu bairro'),
            items: areas
                .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                .toList(),
            onChanged: (v) {
              if (v != null) _area = v;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _bio,
            minLines: 2,
            maxLines: 4,
            maxLength: 180,
            decoration: const InputDecoration(
              labelText: 'Sobre mim (opcional)',
              alignLabelWithHint: true,
            ),
            onSaved: (v) => _bio = v!.trim(),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              if (!_form.currentState!.validate()) return;
              _form.currentState!.save();
              widget.data.editProfile(_name, _area, _bio);
              Navigator.pop(context);
            },
            child: const Text('Salvar perfil'),
          ),
        ],
      ),
    ),
  );
}

class _ReviewEditor extends StatefulWidget {
  const _ReviewEditor({required this.data, required this.post});
  final AppData data;
  final Post post;
  @override
  State<_ReviewEditor> createState() => _ReviewEditorState();
}

class _ReviewEditorState extends State<_ReviewEditor> {
  String? _provider;
  int _stars = 0;
  String _note = '';
  @override
  Widget build(BuildContext context) {
    final people =
        serviceDirectory(widget.data)
            .where((p) => p.person.id != widget.data.currentId)
            .toList()
          ..sort((a, b) => a.person.name.compareTo(b.person.name));
    return _Editor(
      title: 'Avaliar atendimento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.post.title,
            style: const TextStyle(color: InkColors.muted, fontSize: 16),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _provider,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Quem fez o serviço?'),
            items: people
                .map(
                  (p) => DropdownMenuItem(
                    value: p.person.id,
                    child: Text(p.person.name),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _provider = v),
          ),
          const SizedBox(height: 14),
          const Text('Sua nota', style: TextStyle(fontWeight: FontWeight.w600)),
          Wrap(
            children: [
              for (var i = 1; i <= 5; i++)
                Semantics(
                  selected: i == _stars,
                  child: IconButton(
                    tooltip: i == 1 ? '1 estrela' : '$i estrelas',
                    onPressed: () => setState(() => _stars = i),
                    icon: Icon(
                      i <= _stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: InkColors.blue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            minLines: 2,
            maxLines: 4,
            maxLength: 240,
            onChanged: (v) => _note = v,
            decoration: const InputDecoration(
              labelText: 'Comentário (opcional)',
              alignLabelWithHint: true,
            ),
          ),
          FilledButton(
            onPressed: _provider == null || _stars == 0
                ? null
                : () {
                    widget.data.reviewService(
                      widget.post.id,
                      _provider!,
                      _stars,
                      _note,
                    );
                    Navigator.pop(context);
                  },
            child: const Text('Salvar avaliação'),
          ),
        ],
      ),
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: InkColors.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 23,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cancelar',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}
