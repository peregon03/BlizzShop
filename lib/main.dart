import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'providers/venta_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.projectUrl,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const ProviderScope(child: BlizzShopApp()));
}

class BlizzShopApp extends ConsumerStatefulWidget {
  const BlizzShopApp({super.key});

  @override
  ConsumerState<BlizzShopApp> createState() => _BlizzShopAppState();
}

class _BlizzShopAppState extends ConsumerState<BlizzShopApp>
    with WidgetsBindingObserver {
  String _lastDate = DateTime.now().toIso8601String().split('T')[0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Si la app vuelve al frente en un día distinto, invalida las ventas del día.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final today = DateTime.now().toIso8601String().split('T')[0];
      if (today != _lastDate) {
        _lastDate = today;
        ref.invalidate(ventasHoyProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BlizzShop',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'CO'), Locale('en')],
      locale: const Locale('es', 'CO'),
    );
  }
}
