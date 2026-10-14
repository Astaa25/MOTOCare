import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_state_provider.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/motorcycles/presentation/add_edit_motorcycle_screen.dart';
import '../../features/motorcycles/presentation/motorcycle_detail_screen.dart';
import '../../features/motorcycles/presentation/motorcycles_screen.dart';
import '../../features/motorcycles/presentation/update_mileage_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/reminders/presentation/add_edit_reminder_screen.dart';
import '../../features/reminders/presentation/reminder_detail_screen.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/service_history/presentation/add_edit_service_history_screen.dart';
import '../../features/service_history/presentation/service_history_detail_screen.dart';
import '../../features/service_history/presentation/service_history_screen.dart';
import '../widgets/component_catalog_screen.dart';
import '../widgets/placeholder_screen.dart';

/// Notifier untuk refreshListenable GoRouter agar tidak re-instansiasi pada perubahan auth
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authStateProvider,
      (_, _) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final String location = state.uri.path;
    final bool isAuth = authState.isAuthenticated;
    final bool isLoggingIn = location == '/login' ||
        location == '/register' ||
        location == '/forgot-password';
    final bool isSplash = location == '/splash';
    final bool isCatalog = location == '/catalog';

    if (isSplash || isCatalog) return null;

    // Jika belum autentikasi dan mengakses rute terlindungi -> lempar ke login
    if (!isAuth && !isLoggingIn) {
      return '/login';
    }

    // Jika sudah login dan mencoba membuka halaman login/register -> lempar ke home
    if (isAuth && isLoggingIn) {
      return '/home';
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// Provider GoRouter aplikasi MotoCare sesuai PRD bagian 8
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: <RouteBase>[
      // Katalog Komponen Debug (M1)
      GoRoute(
        path: '/catalog',
        builder: (context, state) => const ComponentCatalogScreen(),
      ),

      // Splash Screen (M0)
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Autentikasi (M2)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Beranda (M3, M5)
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Motor (M3)
      GoRoute(
        path: '/motors',
        builder: (context, state) => const MotorcyclesScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'new',
            builder: (context, state) => const AddEditMotorcycleScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => MotorcycleDetailScreen(
              motorcycleId: state.pathParameters['id']!,
            ),
            routes: <RouteBase>[
              GoRoute(
                path: 'edit',
                builder: (context, state) => AddEditMotorcycleScreen(
                  motorcycleId: state.pathParameters['id'],
                ),
              ),
              GoRoute(
                path: 'mileage',
                builder: (context, state) => UpdateMileageScreen(
                  motorcycleId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'services',
                builder: (context, state) => ServiceHistoryScreen(
                  motorcycleId: state.pathParameters['id']!,
                ),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'new',
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      final query = state.uri.queryParameters;
                      final String? prefilledType =
                          extra?['serviceType'] as String? ?? query['prefilledType'];
                      final int? prefilledMileage = extra?['mileage'] as int? ??
                          (query['prefilledMileage'] != null
                              ? int.tryParse(query['prefilledMileage']!)
                              : null);
                      final String? prefilledDescription =
                          extra?['description'] as String? ?? query['prefilledDesc'];
                      final String? reminderId =
                          extra?['reminderId'] as String? ?? query['reminderId'];

                      return AddEditServiceHistoryScreen(
                        motorcycleId: state.pathParameters['id']!,
                        initialServiceType: prefilledType,
                        initialMileage: prefilledMileage,
                        initialDescription: prefilledDescription,
                        reminderId: reminderId,
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'reminders',
                builder: (context, state) => RemindersScreen(
                  motorcycleId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),

      // Servis Detail (M4)
      GoRoute(
        path: '/services/:id',
        builder: (context, state) => ServiceHistoryDetailScreen(
          serviceId: state.pathParameters['id']!,
        ),
      ),

      // Pengingat (M5)
      GoRoute(
        path: '/reminders/new',
        builder: (context, state) => AddEditReminderScreen(
          motorcycleId: state.uri.queryParameters['motorId'],
        ),
      ),
      GoRoute(
        path: '/reminders/:id',
        builder: (context, state) => ReminderDetailScreen(
          reminderId: state.pathParameters['id']!,
        ),
        routes: <RouteBase>[
          GoRoute(
            path: 'edit',
            builder: (context, state) => AddEditReminderScreen(
              reminderId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Bengkel (M6)
      GoRoute(
        path: '/workshops',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Bengkel Terverifikasi',
          milestone: 'M6',
        ),
        routes: <RouteBase>[
          GoRoute(
            path: ':id',
            builder: (context, state) => PlaceholderScreen(
              title: 'Detail Bengkel #${state.pathParameters['id']}',
              milestone: 'M6',
            ),
          ),
        ],
      ),

      // Tutorial (M6)
      GoRoute(
        path: '/tutorials',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Tutorial Perawatan Motor',
          milestone: 'M6',
        ),
        routes: <RouteBase>[
          GoRoute(
            path: ':id',
            builder: (context, state) => PlaceholderScreen(
              title: 'Detail Tutorial #${state.pathParameters['id']}',
              milestone: 'M6',
            ),
          ),
        ],
      ),

      // Bantuan Mekanik (M7)
      GoRoute(
        path: '/help',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Permintaan Bantuan Mekanik',
          milestone: 'M7',
        ),
        routes: <RouteBase>[
          GoRoute(
            path: 'new',
            builder: (context, state) => const PlaceholderScreen(
              title: 'Buat Permintaan Bantuan',
              milestone: 'M7',
            ),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => PlaceholderScreen(
              title: 'Detail Permintaan #${state.pathParameters['id']}',
              milestone: 'M7',
            ),
          ),
        ],
      ),

      // Profil (M2)
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
