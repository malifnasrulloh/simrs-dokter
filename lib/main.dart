import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/views/login_view.dart';
import 'features/dashboard/controllers/dashboard_controller.dart';
import 'features/dashboard/views/dashboard_view.dart';
import 'features/dashboard/views/patient_list_view.dart';
import 'features/rekam_medis/views/rekam_medis_view.dart';
import 'core/utils/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const SimrsDokterApp());
}

class SimrsDokterApp extends StatelessWidget {
  const SimrsDokterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'CareDoc EMR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
          binding: BindingsBuilder(() {
            Get.put(DashboardController());
          }),
          transition: Transition.fadeIn,
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
    );
  }
}
