import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/dashboard_controller.dart';
import 'home_dashboard_view.dart';
import 'patient_workspace_view.dart';
import 'profile_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DashboardController>();

    final List<Widget> pages = [
      const HomeDashboardView(),
      const PatientWorkspaceView(),
      const ProfileView(),
    ];

    return Obx(() {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: IndexedStack(
          index: ctrl.currentNavIndex.value,
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: ctrl.currentNavIndex.value,
          onDestinationSelected: (index) {
            ctrl.currentNavIndex.value = index;
          },
          backgroundColor: AppTheme.bgCard,
          indicatorColor: AppTheme.primary.withOpacity(0.12),
          elevation: 8,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.primary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_alt_rounded, color: AppTheme.primary),
              label: 'Pasien',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primary),
              label: 'Profil',
            ),
          ],
        ),
      );
    });
  }
}
