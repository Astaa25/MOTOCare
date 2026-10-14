import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget aplikasi MotoCare
class MotoCareApp extends ConsumerWidget {
  const MotoCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'MotoCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      locale: const Locale('id', 'ID'),
      supportedLocales: const <Locale>[
        Locale('id', 'ID'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (BuildContext context, Widget? child) {
        // Menghormati textScaler sistem hingga 130% tanpa terpotong (PRD 4.2 & TC-24)
        final mediaQuery = MediaQuery.of(context);
        final double clampedScale = mediaQuery.textScaler.scale(1.0).clamp(0.8, 1.3);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(clampedScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
