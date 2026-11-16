import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/database/pack_manager.dart';
import 'l10n/app_localizations.dart';
import 'services/settings_controller.dart';
import 'ui/screens/about/about_screen.dart';
import 'ui/screens/cung_tu/cung_tu_screen.dart';
import 'ui/screens/packs/packs_screen.dart';
import 'ui/screens/search/search_screen.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsController.instance.loadSettings();
  final initialTab = (args.contains('packs') || args.contains('--tab=packs')) ? 1 : 0;
  String? initialQuery;
  for (final arg in args) {
    if (arg.startsWith('--word=')) {
      initialQuery = arg.substring('--word='.length);
    } else if (arg.startsWith('--query=')) {
      initialQuery = arg.substring('--query='.length);
    }
  }
  runApp(PaliDictApp(
    settingsController: SettingsController.instance,
    initialTab: initialTab,
    initialQuery: initialQuery,
  ));
}

class PaliDictApp extends StatefulWidget {
  final String? overrideDbPath;
  final int initialTab;
  final String? initialQuery;
  final SettingsController? settingsController;

  const PaliDictApp({
    super.key,
    this.overrideDbPath,
    this.initialTab = 0,
    this.initialQuery,
    this.settingsController,
  });

  @override
  State<PaliDictApp> createState() => _PaliDictAppState();
}

class _PaliDictAppState extends State<PaliDictApp> {
  bool _isInitialized = false;
  String? _initError;

  SettingsController get _settingsController =>
      widget.settingsController ?? SettingsController.instance;

  @override
  void initState() {
    super.initState();
    if (!_settingsController.isLoaded) {
      _settingsController.loadSettings();
    }
    if (PackManager.instance.isInitialized) {
      _isInitialized = true;
    } else {
      _initApp();
    }
  }

  Future<void> _initApp() async {
    try {
      await PackManager.instance.initialize(directDbPath: widget.overrideDbPath);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settingsController,
      builder: (context, _) {
        return MaterialApp(
          title: 'PaliDict',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: _settingsController.themeMode,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: mediaQuery.textScaler.clamp(
                  maxScaleFactor: 1.3,
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: _settingsController.locale,
          home: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    if (_initError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Initialization error: $_initError',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _initError = null;
                    });
                    _initApp();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return MainNavigationScaffold(
      initialIndex: widget.initialTab,
      initialQuery: widget.initialQuery,
    );
  }
}

class MainNavigationScaffold extends StatefulWidget {
  final int initialIndex;
  final String? initialQuery;

  const MainNavigationScaffold({
    super.key,
    this.initialIndex = 0,
    this.initialQuery,
  });

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  late int _currentIndex;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _navigateToPacks() {
    setState(() {
      _currentIndex = 1;
    });
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 0) {
      _searchFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = MediaQuery.sizeOf(context).width >= AppConstants.desktopBreakpoint;

    final screens = [
      SearchScreen(
        focusNode: _searchFocusNode,
        onNavigateToPacks: _navigateToPacks,
        initialQuery: widget.initialQuery,
      ),
      const PacksScreen(),
      const AboutScreen(),
      const CungTuScreen(),
    ];

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.search_outlined),
                  selectedIcon: const Icon(Icons.search),
                  label: Text(l10n.navLookup),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.inventory_2_outlined),
                  selectedIcon: const Icon(Icons.inventory_2),
                  label: Text(l10n.navPacks),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.info_outline),
                  selectedIcon: const Icon(Icons.info),
                  label: Text(l10n.navAbout),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.spa_outlined),
                  selectedIcon: const Icon(Icons.spa),
                  label: Text(l10n.navCungTu),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search),
            label: l10n.navLookup,
          ),
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2),
            label: l10n.navPacks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.info_outline),
            selectedIcon: const Icon(Icons.info),
            label: l10n.navAbout,
          ),
          NavigationDestination(
            icon: const Icon(Icons.spa_outlined),
            selectedIcon: const Icon(Icons.spa),
            label: l10n.navCungTu,
          ),
        ],
      ),
    );
  }
}
