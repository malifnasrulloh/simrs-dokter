import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/dashboard_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import 'home_dashboard_view.dart';
import 'patient_workspace_view.dart';
import 'harian_dokter_view.dart';
import 'harian_dokter_config_view.dart';
import 'profile_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DashboardController>();
    final auth = Get.find<AuthController>();

    return Obx(() {
      final List<Widget> pages = [];
      final List<NavigationDestination> destinations = [];

      pages.add(const HomeDashboardView());
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.primary),
        label: 'Dashboard',
      ));

      pages.add(const PatientWorkspaceView());
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.people_outline_rounded),
        selectedIcon: Icon(Icons.people_alt_rounded, color: AppTheme.primary),
        label: 'Pasien',
      ));

      if (auth.isAdmin) {
        pages.add(const HarianDokterConfigView());
        destinations.add(const NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings, color: AppTheme.primary),
          label: 'Akses Harian',
        ));
      } else if (auth.hasAccess('harian_dokter')) {
        pages.add(const HarianDokterView());
        destinations.add(const NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics_rounded, color: AppTheme.primary),
          label: 'Jasa Medis',
        ));
      }

      pages.add(const ProfileView());
      destinations.add(const NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primary),
        label: 'Profil',
      ));

      int activeIndex = ctrl.currentNavIndex.value;
      if (activeIndex >= pages.length) {
        activeIndex = pages.length - 1;
      }
      if (activeIndex < 0) {
        activeIndex = 0;
      }

      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: IndexedStack(
          index: activeIndex,
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: activeIndex,
          onDestinationSelected: (index) {
            ctrl.currentNavIndex.value = index;
          },
          backgroundColor: AppTheme.bgCard,
          indicatorColor: AppTheme.primary.withValues(alpha: 0.12),
          elevation: 8,
          destinations: destinations,
        ),
      );
    });
  }
}
