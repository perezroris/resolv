import 'package:flutter/material.dart';

import 'data.dart';
import 'directory.dart';
import 'ui.dart';

Future<void> showServiceSettings(
  BuildContext context,
  AppData data, {
  bool startEnabled = false,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ServiceSettings(data: data, startEnabled: startEnabled),
  );
}

class ServicesPage extends StatelessWidget {
  const ServicesPage({
    super.key,
    required this.data,
    required this.onOpenPost,
    required this.onEditProfile,
  });

  final AppData data;
  final ValueChanged<String> onOpenPost;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: data,
    builder: (context, _) {
      final active = data.me.professional;
      final requests = active ? serviceRequests(data) : const <Post>[];
      return CustomScrollView(
        key: const PageStorageKey<String>('services'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Semantics(
                        header: true,
                        child: const Text(
                          'Serviços',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.5,
                            height: 1.2,
                            color: InkColors.ink,
                          ),
                        ),
                      ),
                      if (active)
                        TextButton.icon(
                          onPressed: onEditProfile,
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          label: const Text('Ajustar perfil'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!active)
                    _Invite(onEdit: onEditProfile)
                  else ...[
                    Container(
                      decoration: BoxDecoration(
                        color: InkColors.pale,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seu atendimento',
                            style: TextStyle(
                              color: InkColors.navy,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.me.tags.join(' · '),
                            style: const TextStyle(
                              color: InkColors.ink,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.me.areas.join(' · '),
                            style: const TextStyle(
                              color: InkColors.muted,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Semantics(
                      header: true,
                      child: const Text(
                        'Pedidos para você',
                        style: TextStyle(
                          fontSize: 23,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.65,
                          color: InkColors.ink,
                        ),
                      ),
                    ),
                    if (requests.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          'Ainda não há pedidos em aberto para os serviços e bairros que você escolheu.',
                          style: TextStyle(
                            color: InkColors.muted,
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (requests.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              sliver: SliverList.builder(
                itemCount: requests.length,
                itemBuilder: (_, index) {
                  final post = requests[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RequestCard(
                      post: post,
                      author: data.person(post.authorId),
                      onOpen: () => onOpenPost(post.id),
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

class _Invite extends StatelessWidget {
  const _Invite({required this.onEdit});
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      color: InkColors.navy,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 2.05,
            child: Image.asset(
              'assets/costura.jpg',
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: const Text(
                    'Quer oferecer serviços na sua região?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.13,
                      letterSpacing: -.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Escolha os serviços que você faz e os bairros onde atende. Os pedidos dos vizinhos vão aparecer aqui.',
                  style: TextStyle(
                    color: Color(0xFFE0EBF5),
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onEdit,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: InkColors.navy,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(Icons.person_outline_rounded, size: 19),
                  label: const Text('Configurar meu perfil'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.post,
    required this.author,
    required this.onOpen,
  });
  final Post post;
  final Person author;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: InkColors.line),
      borderRadius: BorderRadius.circular(18),
    ),
    child: InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: BrandTag(post.tag),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: InkColors.muted),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              post.title,
              style: const TextStyle(
                color: InkColors.ink,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -.35,
              ),
            ),
            if (post.body.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  post.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: InkColors.muted,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                PersonAvatar(author, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${author.name} · ${post.area ?? author.area}',
                    style: const TextStyle(
                      color: InkColors.muted,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ServiceSettings extends StatefulWidget {
  const _ServiceSettings({required this.data, required this.startEnabled});
  final AppData data;
  final bool startEnabled;

  @override
  State<_ServiceSettings> createState() => _ServiceSettingsState();
}

class _ServiceSettingsState extends State<_ServiceSettings> {
  late bool _enabled = widget.startEnabled || widget.data.me.professional;
  late final _tags = {...widget.data.me.tags};
  late final _areas = widget.data.me.areas.isEmpty
      ? {widget.data.me.area}
      : {...widget.data.me.areas};
  bool _showErrors = false;

  void _save() {
    if (_enabled && (_tags.isEmpty || _areas.isEmpty)) {
      setState(() => _showErrors = true);
      return;
    }
    if (_enabled) {
      widget.data.setProfessional(
        true,
        tags: _tags.toList(),
        serviceAreas: _areas.toList(),
      );
    } else {
      widget.data.setProfessional(false);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: const Text(
                        'Perfil de prestador',
                        style: TextStyle(
                          color: InkColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 23,
                          height: 1.2,
                          letterSpacing: -.55,
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
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Quero oferecer serviços',
                      style: TextStyle(
                        color: InkColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Seu perfil aparece na Vitrine quando esta opção está ligada.',
                    ),
                    value: _enabled,
                    onChanged: (value) => setState(() => _enabled = value),
                  ),
                  if (_enabled) ...[
                    const SizedBox(height: 14),
                    _Choices(
                      title: 'Quais serviços você oferece?',
                      options: serviceTags,
                      selected: _tags,
                      error: _showErrors && _tags.isEmpty
                          ? 'Escolha pelo menos um serviço.'
                          : null,
                      onChanged: (option, value) => setState(() {
                        if (value) {
                          _tags.add(option);
                        } else {
                          _tags.remove(option);
                        }
                      }),
                    ),
                    const SizedBox(height: 20),
                    _Choices(
                      title: 'Em quais bairros você atende?',
                      options: areas,
                      selected: _areas,
                      error: _showErrors && _areas.isEmpty
                          ? 'Escolha pelo menos um bairro.'
                          : null,
                      onChanged: (option, value) => setState(() {
                        if (value) {
                          _areas.add(option);
                        } else {
                          _areas.remove(option);
                        }
                      }),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                child: const Text('Salvar preferências'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({
    required this.title,
    required this.options,
    required this.selected,
    required this.error,
    required this.onChanged,
  });
  final String title;
  final List<String> options;
  final Set<String> selected;
  final String? error;
  final void Function(String, bool) onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            height: 1.3,
            color: InkColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      if (error != null)
        Semantics(
          liveRegion: true,
          child: Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      const SizedBox(height: 7),
      Wrap(
        spacing: 7,
        children: [
          for (final option in options)
            FilterChip(
              label: Text(option),
              selected: selected.contains(option),
              onSelected: (value) => onChanged(option, value),
            ),
        ],
      ),
    ],
  );
}
