import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/auth_flow_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthFlowPage()),
  ],
);
