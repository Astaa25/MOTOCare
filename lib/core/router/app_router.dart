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
import '../../features/notifications/presentation/notification_settings_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/reminders/presentation/add_edit_reminder_screen.dart';
import '../../features/reminders/presentation/reminder_detail_screen.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/service_history/presentation/add_edit_service_history_screen.dart';
import '../../features/service_history/presentation/service_history_detail_screen.dart';
import '../../features/service_history/presentation/service_history_screen.dart';
import '../../features/help_requests/presentation/create_help_request_screen.dart';
import '../../features/help_requests/presentation/help_request_detail_screen.dart';
import '../../features/help_requests/presentation/live_tracking_screen.dart';
import '../../features/help_requests/presentation/location_picker_screen.dart';
import '../../features/help_requests/presentation/my_help_requests_screen.dart';
import '../../features/home/presentation/admin_home_screen.dart';
import '../../features/motorcycles/presentation/motorcycle_providers.dart';
import '../../features/tutorials/presentation/tutorial_detail_screen.dart';
import '../widgets/animated_loading.dart';
import '../widgets/app_background.dart';
import '../widgets/empty_state.dart';
import '../../features/tutorials/presentation/tutorials_screen.dart';
import '../../features/workshops/presentation/workshop_detail_screen.dart';
import '../../features/workshops/presentation/workshops_screen.dart';
import '../widgets/component_catalog_screen.dart';
import '../widgets/main_navigation_shell.dart';
import '../theme/motion.dart';

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

      // Shell Navigasi Utama (N-02 & N-03: Floating Bottom Nav)
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationShell(
            currentLocation: state.matchedLocation,
            child: child,
          );
        },
        routes: <RouteBase>[
          // Beranda (M3, M5 - Tab 1 Pelanggan, Mekanik, Admin)
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => AppMotion.fadeThroughPage(
              key: state.pageKey,
              child: const HomeScreen(),
            ),
          ),

          // Aktivitas Servis & Bantuan (M7 - Tab 2 Pelanggan)
          GoRoute(
            path: '/help',
            pageBuilder: (context, state) => AppMotion.fadeThroughPage(
              key: state.pageKey,
              child: const MyHelpRequestsScreen(),
            ),
          ),

          // Motor Saya (M3 - Tab 3 Pelanggan)
          GoRoute(
            path: '/motors',
            pageBuilder: (context, state) => AppMotion.fadeThroughPage(
              key: state.pageKey,
              child: const MotorcyclesScreen(),
            ),
          ),

          // Bengkel (M6 - Tab 2 Mekanik & Admin / Rute Akses Cepat Pelanggan)
          GoRoute(
            path: '/workshops',
            pageBuilder: (context, state) => AppMotion.fadeThroughPage(
              key: state.pageKey,
              child: WorkshopsScreen(
                initialCity: state.uri.queryParameters['city'],
                initialQuery: state.uri.queryParameters['query'],
              ),
            ),
          ),

          // Tutorial (M6 - Tab 3 Mekanik & Admin / Rute Akses Cepat Pelanggan)
          GoRoute(
            path: '/tutorials',
            pageBuilder: (context, state) => AppMotion.fadeThroughPage(
              key: state.pageKey,
              child: const TutorialsScreen(),
            ),
          ),

          // Profil / Akun (M2 - Tab 4 Pelanggan, Mekanik, Admin)
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => AppMotion.fadeThroughPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),

      // =======================================================================
      // Layar Turunan (Form, Detail, Subfitur - Berada di Luar Shell Nav)
      // Menggunakan shared axis horizontal (T-03: geser 30px + fade, 300 ms)
      // =======================================================================

      // Form Motor Baru (M3)
      GoRoute(
        path: '/motors/new',
        pageBuilder: (context, state) => AppMotion.sharedAxisPage(
          key: state.pageKey,
          child: const AddEditMotorcycleScreen(),
        ),
      ),

      // Detail Motor & Subfitur (M3)
      GoRoute(
        path: '/motors/:id',
        pageBuilder: (context, state) => AppMotion.sharedAxisPage(
          key: state.pageKey,
          child: MotorcycleDetailScreen(
            motorcycleId: state.pathParameters['id']!,
          ),
        ),
        routes: <RouteBase>[
          GoRoute(
            path: 'edit',
            pageBuilder: (context, state) => AppMotion.sharedAxisPage(
              key: state.pageKey,
              child: AddEditMotorcycleScreen(
                motorcycleId: state.pathParameters['id'],
              ),
            ),
          ),
          GoRoute(
            path: 'mileage',
            pageBuilder: (context, state) => AppMotion.sharedAxisPage(
              key: state.pageKey,
              child: UpdateMileageScreen(
                motorcycleId: state.pathParameters['id']!,
              ),
            ),
          ),
          GoRoute(
            path: 'services',
            pageBuilder: (context, state) => AppMotion.sharedAxisPage(
              key: state.pageKey,
              child: ServiceHistoryScreen(
                motorcycleId: state.pathParameters['id']!,
              ),
            ),
            routes: <RouteBase>[
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) {
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

                  return AppMotion.sharedAxisPage(
                    key: state.pageKey,
                    child: AddEditServiceHistoryScreen(
                      motorcycleId: state.pathParameters['id']!,
                      initialServiceType: prefilledType,
                      initialMileage: prefilledMileage,
                      initialDescription: prefilledDescription,
                      reminderId: reminderId,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'reminders',
            pageBuilder: (context, state) => AppMotion.sharedAxisPage(
              key: state.pageKey,
              child: RemindersScreen(
                motorcycleId: state.pathParameters['id']!,
              ),
            ),
          ),
        ],
      ),

      // Servis Detail (M4)
      GoRoute(
        path: '/services/:id',
        pageBuilder: (context, state) => AppMotion.sharedAxisPage(
          key: state.pageKey,
          child: ServiceHistoryDetailScreen(
            serviceId: state.pathParameters['id']!,
          ),
        ),
      ),

      // Pengingat (M5)
      GoRoute(
        path: '/reminders/new',
        pageBuilder: (context, state) => AppMotion.sharedAxisPage(
          key: state.pageKey,
          child: AddEditReminderScreen(
            motorcycleId: state.uri.queryParameters['motorId'],
          ),
        ),
      ),
      GoRoute(
        path: '/reminders/:id',
        pageBuilder: (context, state) => AppMotion.sharedAxisPage(
          key: state.pageKey,
          child: ReminderDetailScreen(
            reminderId: state.pathParameters['id']!,
          ),
        ),
        routes: <RouteBase>[
          GoRoute(
            path: 'edit',
            pageBuilder: (context, state) => AppMotion.sharedAxisPage(
              key: state.pageKey,
              child: AddEditReminderScreen(
                reminderId: state.pathParameters['id']!,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => AppMotion.sharedAxisPage(
          key: state.pageKey,
          child: const NotificationsScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications/settings',
        pageBuilder: (context, state) => AppMotion.sharedAxisPage(
          key: state.pageKey,
          child: const NotificationSettingsScreen(),
        ),
      ),

      // Bengkel Detail (M6)
      GoRoute(
        path: '/workshops/:id',
        pageBuilder: (context, state) => AppMotion.sharedAxisPage(
          key: state.pageKey,
          child: WorkshopDetailScreen(
            workshopId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),

      // Tutorial Detail (M6)
      GoRoute(
        path: '/tutorials/:id',
        pageBuilder: (context, state) => AppMotion.sharedAxisPage(
          key: state.pageKey,
          child: TutorialDetailScreen(
            tutorialId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),

      // Panggil Montir Form, Picker, & Detail Tracking (M7)
      GoRoute(
        path: '/help/new',
        pageBuilder: (context, state) => AppMotion.sharedAxisPage(
          key: state.pageKey,
          child: CreateHelpRequestScreen(
            initialWorkshopId: state.uri.queryParameters['workshopId'],
          ),
        ),
      ),
      GoRoute(
        path: '/help/picker',
        pageBuilder: (context, state) => AppMotion.modalPage(
          key: state.pageKey,
          child: const LocationPickerScreen(),
        ),
      ),
      GoRoute(
        path: '/help/:id',
        pageBuilder: (context, state) => AppMotion.sharedAxisPage(
          key: state.pageKey,
          child: HelpRequestDetailScreen(
            requestId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/help/:id/live-tracking',
        pageBuilder: (context, state) => AppMotion.sharedAxisPage(
          key: state.pageKey,
          child: LiveTrackingScreen(
            requestId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),

      // Pintasan Global Riwayat Servis & Pengingat (dari Beranda agar tidak 404)
      GoRoute(
        path: '/service-history',
        pageBuilder: (context, state) => AppMotion.sharedAxisPage(
          key: state.pageKey,
          child: const _ActiveMotorcycleShortcutScreen(isReminders: false),
        ),
      ),
      GoRoute(
        path: '/reminders',
        pageBuilder: (context, state) => AppMotion.sharedAxisPage(
          key: state.pageKey,
          child: const _ActiveMotorcycleShortcutScreen(isReminders: true),
        ),
      ),

      // Area Admin (UC-07)
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => AppMotion.sharedAxisPage(
          key: state.pageKey,
          child: const AdminHomeScreen(),
        ),
      ),

      // Edit Profil (M2)
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (context, state) => AppMotion.sharedAxisPage(
          key: state.pageKey,
          child: const EditProfileScreen(),
        ),
      ),
    ],
  );
});

/// Wrapper pintasan `/service-history` & `/reminders` yang otomatis memilih motor aktif
/// atau menampilkan ajakan tambah motor bila garasi masih kosong.
class _ActiveMotorcycleShortcutScreen extends ConsumerWidget {
  final bool isReminders;

  const _ActiveMotorcycleShortcutScreen({required this.isReminders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeMotorcycleProvider);
    final active = activeAsync.valueOrNull;

    if (active != null) {
      return isReminders
          ? RemindersScreen(motorcycleId: active.id)
          : ServiceHistoryScreen(motorcycleId: active.id);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(isReminders ? 'Pengingat Servis' : 'Riwayat Servis'),
      ),
      body: AppBackground(
        child: SafeArea(
          child: activeAsync.when(
            loading: () => Center(
              child: MotoCareLoadingIndicator.medium(
                message: 'Memuat data kendaraan...',
              ),
            ),
            error: (err, _) => EmptyState(
              icon: Icons.two_wheeler_rounded,
              title: 'Belum Ada Sepeda Motor',
              message:
                  'Tambahkan sepeda motor terlebih dahulu untuk melihat ${isReminders ? 'pengingat servis' : 'riwayat servis'}.',
              actionLabel: 'Tambah Motor Sekarang',
              onAction: () => context.push('/motors/new'),
            ),
            data: (motor) {
              if (motor == null) {
                return EmptyState(
                  icon: Icons.two_wheeler_rounded,
                  title: 'Belum Ada Sepeda Motor',
                  message:
                      'Tambahkan sepeda motor terlebih dahulu untuk memantau ${isReminders ? 'jadwal pengingat servis' : 'riwayat dan biaya servis'}.',
                  actionLabel: 'Tambah Motor Sekarang',
                  onAction: () => context.push('/motors/new'),
                );
              }
              return isReminders
                  ? RemindersScreen(motorcycleId: motor.id)
                  : ServiceHistoryScreen(motorcycleId: motor.id);
            },
          ),
        ),
      ),
    );
  }
}
