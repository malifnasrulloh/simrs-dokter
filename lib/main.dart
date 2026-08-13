import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'core/network/api_client.dart';
import 'core/services/notification_polling_service.dart';
import 'core/utils/notification_action_controller.dart';
import 'core/utils/local_notification_service.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/views/login_view.dart';
import 'features/dashboard/controllers/dashboard_controller.dart';
import 'features/dashboard/views/dashboard_view.dart';
import 'features/dashboard/views/patient_list_view.dart';
import 'features/rekam_medis/views/rekam_medis_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await LocalNotificationService.initialize();
  await LocalNotificationService.requestPermissions();
  NotificationActionController.startListening();

  Get.put(NotificationPollingService());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'E-Dokter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Outfit',
      ),
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController(), permanent: true);
      }),
      initialRoute: '/login',
      getPages: [
        GetPage(
          name: '/login',
          page: () => const LoginView(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/home',
          page: () => const DashboardView(),
          transition: Transition.fadeIn,
          binding: BindingsBuilder(() {
            Get.put(DashboardController());
          }),
        ),
        GetPage(
          name: '/patient-list',
          page: () => const PatientListView(),
          transition: Transition.rightToLeft,
          transitionDuration: const Duration(milliseconds: 250),
        ),
        GetPage(
          name: '/rekam-medis',
          page: () => const RekamMedisView(),
          transition: Transition.rightToLeft,
          transitionDuration: const Duration(milliseconds: 250),
        ),
      ],
      builder: (context, child) {
        return _NotificationNavigationHandler(child: child!);
      },
    );
  }
}

/// Handles cold-start navigation from system notification tap.
/// Listens to [NotificationActionController.pendingNavigation] and
/// navigates to the appropriate route once the app is ready.
class _NotificationNavigationHandler extends StatefulWidget {
  final Widget child;
  const _NotificationNavigationHandler({required this.child});

  @override
  State<_NotificationNavigationHandler> createState() =>
      _NotificationNavigationHandlerState();
}

class _NotificationNavigationHandlerState
    extends State<_NotificationNavigationHandler> {
  final _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _listenForPendingNavigation();
  }

  void _listenForPendingNavigation() {
    ever(NotificationActionController.pendingNavigation, (nav) async {
      if (nav == null) return;

      final route = notificationRoutes[nav.eventType] ?? defaultNotifRoute;

      // Events without a patient context just land on the dashboard shell.
      if (route.route != '/rekam-medis' || nav.noRawat.isEmpty) {
        Get.offAllNamed(route.route);
        return;
      }

      // Fetch patient data from backend
      try {
        final res = await _api.dio.get(
          '/pasien/cari-by-rawat',
          queryParameters: {'no_rawat': nav.noRawat},
        );
        if (res.data?['success'] != true) return;
        final patient = res.data['data'] as Map<String, dynamic>?;
        if (patient == null) return;

        Get.toNamed(route.route, arguments: <String, dynamic>{
          ...patient,
          '_targetTab': route.tabIndex,
        });
      } catch (_) {
        // Silently fail — user can navigate manually
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
