import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/settings_provider.dart';
import 'router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);

    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'BookHub',
      routerConfig: router,
      theme: baseTheme,
      darkTheme: baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(brightness: Brightness.dark),
        brightness: Brightness.dark,
      ),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: const [
        Locale('ru'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
