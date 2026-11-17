import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data.dart';
import 'conversations.dart';
import 'mural.dart';
import 'profile.dart';
import 'services.dart';
import 'ui.dart';
import 'vitrine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final data = AppData();
  await data.load();
  runApp(ResolvApp(data: data));
}

class ResolvApp extends StatelessWidget {
  const ResolvApp({super.key, required this.data});
  final AppData data;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: InkColors.blue).copyWith(
      primary: InkColors.navy,
      onPrimary: Colors.white,
      secondary: InkColors.blue,
      secondaryContainer: InkColors.pale,
      onSecondaryContainer: InkColors.navy,
      surface: Colors.white,
      onSurface: InkColors.ink,
      outline: InkColors.muted,
      outlineVariant: InkColors.line,
    );
    return MaterialApp(
      title: 'resolv!',
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: InkColors.canvas,
        dividerTheme: const DividerThemeData(
          color: InkColors.line,
          thickness: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: _NeighborhoodHome(data: data),
    );
  }
}

class _NeighborhoodHome extends StatefulWidget {
  const _NeighborhoodHome({required this.data});
  final AppData data;

  @override
  State<_NeighborhoodHome> createState() => _NeighborhoodHomeState();
}

class _NeighborhoodHomeState extends State<_NeighborhoodHome> {
  final _mural = GlobalKey<MuralPageState>();
  int _tab = 0;
  int _returnTab = 2;
  String? _postId;

  void _select(int next) {
    if (next == _tab && _postId == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _postId = null;
      _tab = next;
    });
  }

  void _openPost(String id) {
    if (widget.data.post(id) == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _returnTab = _tab;
      _tab = 0;
      _postId = id;
    });
  }

  void _request(String? tag) {
    _select(0);
    _mural.currentState?.showComposer(tag);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: InkColors.canvas,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: InkColors.line)),
          ),
          child: NavigationBar(
            height: 66,
            elevation: 0,
            backgroundColor: Colors.transparent,
            indicatorColor: InkColors.pale,
            selectedIndex: _tab,
            onDestinationSelected: _select,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.view_agenda_outlined),
                selectedIcon: Icon(
                  Icons.view_agenda_rounded,
                  color: InkColors.navy,
                ),
                label: 'Mural',
              ),
              NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(
                  Icons.storefront_rounded,
                  color: InkColors.navy,
                ),
                label: 'Vitrine',
              ),
              NavigationDestination(
                icon: Icon(Icons.work_outline_rounded),
                selectedIcon: Icon(Icons.work_rounded, color: InkColors.navy),
                label: 'Serviços',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: InkColors.navy),
                label: 'Perfil',
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 7, 22, 5),
                    child: Row(
                      children: [
                        const Text.rich(
                          TextSpan(
                            text: 'resolv',
                            children: [
                              TextSpan(
                                text: '!',
                                style: TextStyle(color: InkColors.blue),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 30,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.9,
                            color: InkColors.navy,
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(
                                Icons.place_outlined,
                                size: 17,
                                color: InkColors.muted,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: ListenableBuilder(
                                  listenable: data,
                                  builder: (context, _) => Text(
                                    data.me.area,
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      color: InkColors.muted,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ListenableBuilder(
                          listenable: data,
                          builder: (context, _) => IconButton(
                            tooltip: 'Conversas',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => ConversationsPage(data: data),
                              ),
                            ),
                            icon: Badge(
                              isLabelVisible: data.unreadChats > 0,
                              backgroundColor: InkColors.blue,
                              label: Text('${data.unreadChats}'),
                              child: const Icon(
                                Icons.forum_outlined,
                                color: InkColors.navy,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _postId == null ? _tab : 4,
                      children: [
                        MuralPage(key: _mural, data: data),
                        VitrinePage(data: data, onRequest: _request),
                        ServicesPage(
                          data: data,
                          onOpenPost: _openPost,
                          onEditProfile: () {
                            _select(3);
                            showServiceSettings(context, data);
                          },
                        ),
                        ProfilePage(data: data, onOpenPost: _openPost),
                        if (_postId != null)
                          MuralPostPanel(
                            key: ValueKey(_postId),
                            data: data,
                            postId: _postId!,
                            backLabel: _returnTab == 3
                                ? 'Voltar ao Perfil'
                                : 'Voltar para Serviços',
                            onBack: () => _select(_returnTab),
                          ),
                      ],
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
