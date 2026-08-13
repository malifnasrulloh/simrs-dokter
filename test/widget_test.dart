import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:simrs_dokter/main.dart';
import 'package:simrs_dokter/features/auth/views/login_view.dart';

void main() {
  testWidgets('app boots to the login screen with all core routes wired', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginView), findsOneWidget);
    expect(find.byType(GetMaterialApp), findsOneWidget);
    expect(find.text('E-Dokter'), findsOneWidget);
  });
}
