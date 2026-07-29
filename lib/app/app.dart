import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'app_router.dart';

class SaudeFinanceiraApp extends StatelessWidget {
  const SaudeFinanceiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Saúde Financeira Familiar',

      debugShowCheckedModeBanner: false,

      theme: AppTheme.light,

      routerConfig: appRouter,

      locale: const Locale('pt', 'BR'),
    );
  }
}
