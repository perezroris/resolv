import 'package:flutter/material.dart';

import 'data.dart';
import 'conversations.dart';
import 'directory.dart';
import 'ui.dart';

const _shortcuts = [
  ('Pequenos reparos', 'Reparos', 'assets/reparos.jpg'),
  ('Costura', 'Costura', 'assets/costura.jpg'),
  ('Aulas particulares', 'Aulas', 'assets/aulas.jpg'),
];

const _extraCategories = [
  ('Fretes e mudanças', 'Fretes', Icons.local_shipping_outlined),
  ('Beleza', 'Beleza', Icons.content_cut_outlined),
  ('Fotografia', 'Fotografia', Icons.photo_camera_outlined),
  ('Culinária', 'Culinária', Icons.restaurant_outlined),
];

class VitrinePage extends StatefulWidget {
  const VitrinePage({super.key, required this.data, required this.onRequest});
  final AppData data;
  final ValueChanged<String?> onRequest;

  @override
  State<VitrinePage> createState() => _VitrinePageState();
}

class _VitrinePageState extends State<VitrinePage> {
  final _search = TextEditingController();
  String? _tag, _openId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _changeTag(String? tag) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _tag = tag;
      _openId = null;
    });
  }

  Future<void> _categories() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
              child: Text(
                'Categorias',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: InkColors.ink,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final tag in ['', ...serviceTags])
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      title: Text(tag.isEmpty ? 'Todas as categorias' : tag),
                      selected: (_tag ?? '') == tag,
                      trailing: (_tag ?? '') == tag
                          ? const Icon(Icons.check_rounded)
                          : null,
                      onTap: () => Navigator.pop(context, tag),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (mounted && choice != null) _changeTag(choice.isEmpty ? null : choice);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: widget.data, builder: _buildDirectory);
  }

  Widget _buildDirectory(BuildContext context, Widget? _) {
    final area = widget.data.me.area;
    final results = findProviders(
      serviceDirectory(widget.data),
      area: area,
      tag: _tag,
      query: _search.text,
    );
    final filtered = _tag != null || _search.text.trim().isNotEmpty;
    final expandedSearch =
        filtered && results.isNotEmpty && results.first.person.area != area;
    return CustomScrollView(
      key: const PageStorageKey('vitrine'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                        'Vitrine',
                        style: TextStyle(
                          fontSize: 34,
                          letterSpacing: -1.5,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: InkColors.ink,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _categories,
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Categorias'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() => _openId = null),
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: InputDecoration(
                    hintText: 'Buscar serviço ou profissional',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpar busca',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              setState(() => _openId = null);
                            },
                          ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: InkColors.line),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 14,
                    ),
                  ),
                ),
                if (!filtered) ...[
                  const SizedBox(height: 13),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = (constraints.maxWidth - 16) / 3;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (tag, label, asset) in _shortcuts)
                            SizedBox(
                              width: width,
                              child: _ServiceTile(
                                label: label,
                                asset: asset,
                                onTap: () => _changeTag(tag),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final (tag, label, icon) in _extraCategories)
                          Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: ActionChip(
                              avatar: Icon(
                                icon,
                                size: 17,
                                color: InkColors.blue,
                              ),
                              label: Text(label),
                              tooltip: 'Filtrar por $tag',
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: InkColors.line),
                              shape: const StadiumBorder(),
                              onPressed: () => _changeTag(tag),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (_tag != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: InputChip(
                        label: Text(_tag!),
                        onDeleted: () => _changeTag(null),
                        deleteButtonTooltipMessage: 'Remover categoria',
                      ),
                    ),
                  ),
                const SizedBox(height: 21),
                Semantics(
                  header: true,
                  child: Text(
                    expandedSearch
                        ? 'Nos bairros próximos'
                        : area == 'Centro'
                        ? 'Atendem no Centro'
                        : 'Atendem no seu bairro',
                    style: const TextStyle(
                      color: InkColors.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      letterSpacing: -.65,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    expandedSearch
                        ? 'Estes profissionais também atendem no seu bairro.'
                        : '${results.length} ${results.length == 1 ? 'profissional' : 'profissionais'}',
                    style: const TextStyle(
                      color: InkColors.muted,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (results.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.travel_explore_rounded,
                      color: InkColors.blue,
                      size: 30,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nenhum profissional encontrado',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: InkColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Já buscamos nos bairros da região. Você também pode pedir uma indicação aos vizinhos.',
                      style: TextStyle(color: InkColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () => widget.onRequest(_tag),
                      child: const Text('Publicar pedido no Mural'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          sliver: SliverList.builder(
            itemCount: results.length,
            itemBuilder: (_, index) {
              final profile = results[index];
              final id = profile.person.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ProviderCard(
                  key: ValueKey(id),
                  profile: profile,
                  open: _openId == id,
                  onChat: id == widget.data.currentId
                      ? null
                      : () => openConversation(context, widget.data, id),
                  onTap: () =>
                      setState(() => _openId = _openId == id ? null : id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  border: Border.all(color: InkColors.line),
  borderRadius: BorderRadius.circular(20),
);

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.label,
    required this.asset,
    required this.onTap,
  });
  final String label, asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Filtrar por $label',
    onTap: onTap,
    excludeSemantics: true,
    child: Material(
      color: InkColors.navy,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(asset, fit: BoxFit.cover, cacheWidth: 480),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x080A1420), Color(0xDD071525)],
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 91),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 45, 8, 9),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    super.key,
    required this.profile,
    required this.open,
    required this.onChat,
    required this.onTap,
  });
  final ServiceProfile profile;
  final VoidCallback? onChat;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final person = profile.person;
    final rating = profile.rating?.toStringAsFixed(1).replaceAll('.', ',');
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: InkColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Semantics(
        button: true,
        expanded: open,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PersonAvatar(person, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person.name,
                            style: const TextStyle(
                              color: InkColors.ink,
                              fontSize: 18,
                              letterSpacing: -.35,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            person.area,
                            style: const TextStyle(
                              color: InkColors.muted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      open
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: InkColors.muted,
                    ),
                  ],
                ),
                if (profile.bio.isNotEmpty) ...[
                  const SizedBox(height: 11),
                  Text(
                    profile.bio,
                    style: const TextStyle(
                      color: InkColors.ink,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final tag in profile.tags) BrandTag(tag),
                    if (rating != null)
                      Semantics(
                        label:
                            'Nota $rating de 5 em ${profile.reviewCount} avaliações',
                        excludeSemantics: true,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: InkColors.blue,
                              size: 17,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '$rating (${profile.reviewCount})',
                              style: const TextStyle(
                                color: InkColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Text(
                        'Ainda sem avaliações',
                        style: TextStyle(color: InkColors.muted, fontSize: 13),
                      ),
                  ],
                ),
                if (open) ...[
                  const Divider(height: 25),
                  const Text(
                    'Bairros onde atende',
                    style: TextStyle(
                      color: InkColors.navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.serviceAreas.join(' · '),
                    style: const TextStyle(
                      color: InkColors.muted,
                      fontSize: 14,
                    ),
                  ),
                  if (onChat != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: FilledButton.icon(
                        onPressed: onChat,
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                        ),
                        label: const Text('Conversar'),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
