import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_state_provider.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
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
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text('Beranda MotoCare'),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/notifications'),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () {
                  ref.read(authStateProvider.notifier).setUnauthenticated();
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Selamat Datang di MotoCare!',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Aplikasi perawatan motor Kota Lhokseumawe & Kabupaten Aceh Utara.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.two_wheeler),
                title: const Text('Motor Saya'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/motors'),
              ),
              ListTile(
                leading: const Icon(Icons.build),
                title: const Text('Bengkel Terverifikasi'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/workshops'),
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('Tutorial Perawatan'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/tutorials'),
              ),
              ListTile(
                leading: const Icon(Icons.sos_rounded),
                title: const Text('Bantuan Mekanik'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/help'),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profil Pengguna'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/profile'),
              ),
            ],
          ),
        ),
      ),

      // Motor (M3)
      GoRoute(
        path: '/motors',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Motor Saya',
          milestone: 'M3',
        ),
        routes: <RouteBase>[
          GoRoute(
            path: 'new',
            builder: (context, state) => const PlaceholderScreen(
              title: 'Tambah Motor Baru',
              milestone: 'M3',
            ),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => PlaceholderScreen(
              title: 'Detail Motor #${state.pathParameters['id']}',
              milestone: 'M3',
            ),
            routes: <RouteBase>[
              GoRoute(
                path: 'edit',
                builder: (context, state) => PlaceholderScreen(
                  title: 'Ubah Motor #${state.pathParameters['id']}',
                  milestone: 'M3',
                ),
              ),
              GoRoute(
                path: 'mileage',
                builder: (context, state) => PlaceholderScreen(
                  title: 'Perbarui Kilometer Motor #${state.pathParameters['id']}',
                  milestone: 'M3',
                ),
              ),
              GoRoute(
                path: 'services',
                builder: (context, state) => PlaceholderScreen(
                  title: 'Riwayat Servis Motor #${state.pathParameters['id']}',
                  milestone: 'M4',
                ),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const PlaceholderScreen(
                      title: 'Tambah Catatan Servis',
                      milestone: 'M4',
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'reminders',
                builder: (context, state) => PlaceholderScreen(
                  title: 'Pengingat Motor #${state.pathParameters['id']}',
                  milestone: 'M5',
                ),
              ),
            ],
          ),
        ],
      ),

      // Servis Detail (M4)
      GoRoute(
        path: '/services/:id',
        builder: (context, state) => PlaceholderScreen(
          title: 'Detail Servis #${state.pathParameters['id']}',
          milestone: 'M4',
        ),
      ),

      // Pengingat (M5)
      GoRoute(
        path: '/reminders/new',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Buat Pengingat Baru',
          milestone: 'M5',
        ),
      ),
      GoRoute(
        path: '/reminders/:id',
        builder: (context, state) => PlaceholderScreen(
          title: 'Detail Pengingat #${state.pathParameters['id']}',
          milestone: 'M5',
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Pusat Notifikasi',
          milestone: 'M5',
        ),
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
