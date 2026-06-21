import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../../features/auth/screen/login_screen.dart';
import '../../features/auth/screen/signup_screen.dart';
import '../../features/map/screen/map_list_screen.dart';
import '../../features/map/screen/map_create_screen.dart';
import '../../features/map/screen/map_detail_screen.dart';
import '../../features/pin/screen/pin_record_screen.dart';
import '../../features/user/screen/block_list_screen.dart';
import '../../features/user/screen/profile_screen.dart';
import '../../features/map/screen/map_member_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/login',
    redirect: (context, state) async {
      final isLoggedIn = await ref.read(isLoggedInProvider.future);
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/maps';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/maps', builder: (_, __) => const MapListScreen()),
      GoRoute(path: '/maps/create', builder: (_, __) => const MapCreateScreen()),
      GoRoute(
        path: '/maps/:mapId',
        builder: (_, state) => MapDetailScreen(
          mapId: int.parse(state.pathParameters['mapId']!),
        ),
      ),
      GoRoute(
        path: '/maps/:mapId/pins/:regionPinId',
        builder: (_, state) => PinRecordScreen(
          mapId: int.parse(state.pathParameters['mapId']!),
          regionPinId: int.parse(state.pathParameters['regionPinId']!),
          svgId: state.uri.queryParameters['svgId'] ?? '',  // 추가
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/maps/:mapId/members',
        builder: (_, state) => MapMemberScreen(
          mapId: int.parse(state.pathParameters['mapId']!),
        ),
      ),
      GoRoute(
        path: '/block-list',
        builder: (_, __) => const BlockListScreen(),
      ),
    ],
  );
});