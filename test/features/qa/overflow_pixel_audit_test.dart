import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:motocare/core/theme/app_theme.dart';
import 'package:motocare/features/auth/presentation/forgot_password_screen.dart';
import 'package:motocare/features/auth/presentation/login_screen.dart';
import 'package:motocare/features/auth/presentation/register_screen.dart';
import 'package:motocare/features/help_requests/domain/mechanic.dart';
import 'package:motocare/features/help_requests/domain/request_status.dart';
import 'package:motocare/features/help_requests/domain/service_request.dart';
import 'package:motocare/features/help_requests/presentation/create_help_request_screen.dart';
import 'package:motocare/features/help_requests/presentation/help_request_detail_screen.dart';
import 'package:motocare/features/help_requests/presentation/help_requests_providers.dart';
import 'package:motocare/features/help_requests/presentation/live_tracking_screen.dart';
import 'package:motocare/features/help_requests/presentation/location_picker_screen.dart';
import 'package:motocare/features/help_requests/presentation/my_help_requests_screen.dart';
import 'package:motocare/features/help_requests/presentation/widgets/simulated_mechanic_tracking_card.dart';
import 'package:motocare/features/home/presentation/admin_home_screen.dart';
import 'package:motocare/features/home/presentation/home_screen.dart';
import 'package:motocare/features/home/presentation/mechanic_home_screen.dart';
import 'package:motocare/features/motorcycles/data/mock_motorcycle_repository.dart';
import 'package:motocare/features/motorcycles/domain/motorcycle.dart';
import 'package:motocare/features/motorcycles/presentation/add_edit_motorcycle_screen.dart';
import 'package:motocare/features/motorcycles/presentation/motorcycle_detail_screen.dart';
import 'package:motocare/features/motorcycles/presentation/motorcycle_providers.dart';
import 'package:motocare/features/motorcycles/presentation/motorcycles_screen.dart';
import 'package:motocare/features/motorcycles/presentation/update_mileage_screen.dart';
import 'package:motocare/features/notifications/presentation/notification_settings_screen.dart';
import 'package:motocare/features/notifications/presentation/notifications_screen.dart';
import 'package:motocare/features/profile/presentation/edit_profile_screen.dart';
import 'package:motocare/features/profile/presentation/profile_screen.dart';
import 'package:motocare/features/reminders/data/mock_maintenance_reminder_repository.dart';
import 'package:motocare/features/reminders/presentation/add_edit_reminder_screen.dart';
import 'package:motocare/features/reminders/presentation/reminders_providers.dart';
import 'package:motocare/features/reminders/presentation/reminders_screen.dart';
import 'package:motocare/features/service_history/data/mock_service_history_repository.dart';
import 'package:motocare/features/service_history/presentation/add_edit_service_history_screen.dart';
import 'package:motocare/features/service_history/presentation/service_history_providers.dart';
import 'package:motocare/features/service_history/presentation/service_history_screen.dart';
import 'package:motocare/features/tutorials/data/mock_tutorial_repository.dart';
import 'package:motocare/features/tutorials/presentation/tutorial_detail_screen.dart';
import 'package:motocare/features/tutorials/presentation/tutorials_providers.dart';
import 'package:motocare/features/tutorials/presentation/tutorials_screen.dart';
import 'package:motocare/features/workshops/data/mock_workshop_repository.dart';
import 'package:motocare/features/workshops/presentation/workshop_detail_screen.dart';
import 'package:motocare/features/workshops/presentation/workshops_providers.dart';
import 'package:motocare/features/workshops/presentation/workshops_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  final testMechanic = Mechanic(
    id: 'mech-01',
    profileId: 'prof-mech-01',
    name: 'Bang Rudi Pratama',
    phone: '081269112201',
    workshopName: 'Bengkel Resmi Samudera Motor',
    createdAt: DateTime(2026, 10, 1),
  );

  final testRequestOtw = ServiceRequest(
    id: 'req-otw-01',
    userId: 'user-01',
    issueCategory: 'Mesin Mogok',
    issueDescription: 'Motor mati mendadak dekat Simpang Elak',
    addressText: 'Jl. Merdeka Barat No. 88, Banda Sakti, Kota Lhokseumawe',
    cityRegency: 'Kota Lhokseumawe',
    latitude: 5.1801,
    longitude: 97.1402,
    contactPhone: '081234567890',
    status: RequestStatus.onTheWay,
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    mechanicId: 'mech-01',
    mechanic: testMechanic,
    isDemo: false,
  );

  final testMotor = Motorcycle(
    id: 'motor-01',
    userId: 'user-01',
    brand: 'Honda',
    model: 'Vario 160 CBS',
    productionYear: 2023,
    licensePlate: 'BL 4821 KAA',
    currentMileage: 12500,
    mileageUpdatedAt: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  Future<void> testScreenOverflow(
    WidgetTester tester, {
    required Widget screen,
    required String screenName,
    double width = 360,
    double height = 800,
    double textScale = 1.3,
    List<Override> overrides = const <Override>[],
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          motorcycleRepositoryProvider.overrideWithValue(MockMotorcycleRepository(populateDemoData: true)),
          workshopRepositoryProvider.overrideWithValue(MockWorkshopRepository()),
          tutorialRepositoryProvider.overrideWithValue(MockTutorialRepository()),
          reminderRepositoryProvider.overrideWithValue(MockMaintenanceReminderRepository(populateDemoData: true)),
          serviceHistoryRepositoryProvider.overrideWithValue(MockServiceHistoryRepository(populateDemoData: true)),
          helpRequestDetailProvider('req-otw-01').overrideWith((ref) => Future.value(testRequestOtw)),
          motorcycleDetailProvider('motor-01').overrideWith((ref) => Future.value(testMotor)),
          ...overrides,
        ],
        child: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScale),
          ),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: screen,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    final exception = tester.takeException();
    expect(exception, isNull, reason: '$screenName mengalami exception/overflow: $exception');
  }

  group('Audit Pixel Overload / RenderFlex Overflow Seluruh Layar MotoCare', () {
    // 1. Auth & Onboarding
    testWidgets('LoginScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(tester, screen: const LoginScreen(), screenName: 'LoginScreen');
    });

    testWidgets('RegisterScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(tester, screen: const RegisterScreen(), screenName: 'RegisterScreen');
    });

    testWidgets('ForgotPasswordScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(tester, screen: const ForgotPasswordScreen(), screenName: 'ForgotPasswordScreen');
    });

    // 2. Beranda & Dashboard (Pelanggan, Mekanik, Admin)
    testWidgets('HomeScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(tester, screen: const HomeScreen(), screenName: 'HomeScreen');
    });

    testWidgets('MechanicHomeScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(tester, screen: const MechanicHomeScreen(), screenName: 'MechanicHomeScreen');
    });

    testWidgets('AdminHomeScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(tester, screen: const AdminHomeScreen(), screenName: 'AdminHomeScreen');
    });

    // 3. Panggil Montir & Pelacakan
    testWidgets('CreateHelpRequestScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(tester, screen: const CreateHelpRequestScreen(), screenName: 'CreateHelpRequestScreen');
    });

    testWidgets('HelpRequestDetailScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(
        tester,
        screen: const HelpRequestDetailScreen(requestId: 'req-otw-01'),
        screenName: 'HelpRequestDetailScreen',
      );
    });

    testWidgets('LiveTrackingScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(
        tester,
        screen: const LiveTrackingScreen(requestId: 'req-otw-01'),
        screenName: 'LiveTrackingScreen',
      );
    });

    testWidgets('MyHelpRequestsScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(tester, screen: const MyHelpRequestsScreen(), screenName: 'MyHelpRequestsScreen');
    });

    testWidgets('LocationPickerScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(tester, screen: const LocationPickerScreen(), screenName: 'LocationPickerScreen');
    });

    testWidgets('SimulatedMechanicTrackingCard tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(
        tester,
        screen: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: SimulatedMechanicTrackingCard(request: testRequestOtw),
          ),
        ),
        screenName: 'SimulatedMechanicTrackingCard',
      );
    });

    // 4. Sepeda Motor
    testWidgets('MotorcyclesScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(tester, screen: const MotorcyclesScreen(), screenName: 'MotorcyclesScreen');
    });

    testWidgets('MotorcycleDetailScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(
        tester,
        screen: const MotorcycleDetailScreen(motorcycleId: 'motor-01'),
        screenName: 'MotorcycleDetailScreen',
      );
    });

    testWidgets('AddEditMotorcycleScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(tester, screen: const AddEditMotorcycleScreen(), screenName: 'AddEditMotorcycleScreen');
    });

    testWidgets('UpdateMileageScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(
        tester,
        screen: const UpdateMileageScreen(motorcycleId: 'motor-01'),
        screenName: 'UpdateMileageScreen',
      );
    });

    // 5. Bengkel
    testWidgets('WorkshopsScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(tester, screen: const WorkshopsScreen(), screenName: 'WorkshopsScreen');
    });

    testWidgets('WorkshopDetailScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(
        tester,
        screen: const WorkshopDetailScreen(workshopId: 'ws-01'),
        screenName: 'WorkshopDetailScreen',
      );
    });

    // 6. Pengingat & Riwayat
    testWidgets('RemindersScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(
        tester,
        screen: const RemindersScreen(motorcycleId: 'motor-01'),
        screenName: 'RemindersScreen',
      );
    });

    testWidgets('AddEditReminderScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(
        tester,
        screen: const AddEditReminderScreen(motorcycleId: 'motor-01'),
        screenName: 'AddEditReminderScreen',
      );
    });

    testWidgets('ServiceHistoryScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(
        tester,
        screen: const ServiceHistoryScreen(motorcycleId: 'motor-01'),
        screenName: 'ServiceHistoryScreen',
      );
    });

    testWidgets('AddEditServiceHistoryScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(
        tester,
        screen: const AddEditServiceHistoryScreen(motorcycleId: 'motor-01'),
        screenName: 'AddEditServiceHistoryScreen',
      );
    });

    // 7. Tutorial & Profil
    testWidgets('TutorialsScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(tester, screen: const TutorialsScreen(), screenName: 'TutorialsScreen');
    });

    testWidgets('TutorialDetailScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(
        tester,
        screen: const TutorialDetailScreen(tutorialId: 'tut-01'),
        screenName: 'TutorialDetailScreen',
      );
    });

    testWidgets('ProfileScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(tester, screen: const ProfileScreen(), screenName: 'ProfileScreen');
    });

    testWidgets('EditProfileScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(tester, screen: const EditProfileScreen(), screenName: 'EditProfileScreen');
    });

    testWidgets('NotificationSettingsScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(tester, screen: const NotificationSettingsScreen(), screenName: 'NotificationSettingsScreen');
    });

    testWidgets('NotificationsScreen tidak overflow pada layar 360x800 skala 1.3x', (tester) async {
      await testScreenOverflow(tester, screen: const NotificationsScreen(), screenName: 'NotificationsScreen');
    });

    // 8. Pengujian Ekstrem Layar Sempit 320px (Compact Mobile)
    testWidgets('Layar Kritis tidak overflow pada layar sangat sempit 320x640', (tester) async {
      await testScreenOverflow(
        tester,
        screen: const HomeScreen(),
        screenName: 'HomeScreen (320px)',
        width: 320,
        height: 640,
        textScale: 1.0,
      );

      await testScreenOverflow(
        tester,
        screen: const WorkshopsScreen(),
        screenName: 'WorkshopsScreen (320px)',
        width: 320,
        height: 640,
        textScale: 1.0,
      );

      await testScreenOverflow(
        tester,
        screen: const LiveTrackingScreen(requestId: 'req-otw-01'),
        screenName: 'LiveTrackingScreen (320px)',
        width: 320,
        height: 640,
        textScale: 1.0,
      );

      await testScreenOverflow(
        tester,
        screen: const MechanicHomeScreen(),
        screenName: 'MechanicHomeScreen (320px)',
        width: 320,
        height: 640,
        textScale: 1.0,
      );
    });
  });
}
