import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:simrs_dokter/features/auth/controllers/auth_controller.dart';
import 'package:simrs_dokter/features/auth/views/login_view.dart';
import 'test_helper.dart';

void main() {
  setUpAll(() {
    TestHelper.setupTestMockChannels();
    TestHelper.setupMockApi();
  });

  setUp(() {
    TestHelper.mockSecureStorage.clear();
    Get.reset();
    Get.testMode = true;
  });

  group('AuthController Unit Tests', () {
    test('initial state is correct', () {
      final controller = AuthController();
      expect(controller.isLoading.value, isFalse);
      expect(controller.errorMsg.value, isEmpty);
      expect(controller.user.value, isNull);
    });

    test('login with correct credentials sets session and writes to storage', () async {
      final controller = Get.put(AuthController());
      
      await controller.login('D0001', 'password123');

      expect(controller.isLoading.value, isFalse);
      expect(controller.errorMsg.value, isEmpty);
      expect(controller.user.value, isNotNull);
      expect(controller.user.value?['kd_dokter'], 'D0001');

      // Verify data is persisted in secure storage
      expect(TestHelper.mockSecureStorage['auth_token'], 'mock_jwt_token');
      expect(TestHelper.mockSecureStorage['username'], 'D0001');
      expect(TestHelper.mockSecureStorage['password'], 'password123');
    });

    test('login with incorrect credentials sets error message', () async {
      final controller = Get.put(AuthController());

      await controller.login('wrong_user', 'wrong_pass');

      expect(controller.isLoading.value, isFalse);
      expect(controller.errorMsg.value, 'Username atau password salah');
      expect(controller.user.value, isNull);
      expect(TestHelper.mockSecureStorage['auth_token'], isNull);
    });

    test('logout clears secure storage and resets user data', () async {
      final controller = Get.put(AuthController());

      // Set mock session details
      TestHelper.mockSecureStorage['auth_token'] = 'old_token';
      controller.user.value = {'kd_dokter': 'D0001'};

      await controller.logout();

      expect(controller.user.value, isNull);
      expect(controller.setting.value, isNull);
      expect(controller.profileData.value, isNull);
      expect(TestHelper.mockSecureStorage, isEmpty);
    });
  });

  group('LoginView Widget Integration Tests', () {
    testWidgets('renders login form properly and handles submit', (WidgetTester tester) async {
      Get.put(AuthController());

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/login',
          getPages: [
            GetPage(name: '/login', page: () => const LoginView()),
            GetPage(name: '/home', page: () => const Scaffold(body: Text('Home Page'))),
          ],
        ),
      );

      // Verify that logo header, input fields and buttons are present
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Masuk Ke Dashboard'), findsOneWidget);

      // Fill in form with correct credentials
      await tester.enterText(find.byType(TextField).at(0), 'D0001');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.pumpAndSettle();

      // Click the login button
      await tester.tap(find.text('Masuk Ke Dashboard'));
      await tester.pump(); // Start loading
      
      // Let the mock future resolve
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Verify user successfully routed to '/home'
      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('shows validation/error message on login failure', (WidgetTester tester) async {
      Get.put(AuthController());

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/login',
          getPages: [
            GetPage(name: '/login', page: () => const LoginView()),
          ],
        ),
      );

      // Fill in incorrect credentials
      await tester.enterText(find.byType(TextField).at(0), 'invalid_doc');
      await tester.enterText(find.byType(TextField).at(1), 'wrongpass');
      await tester.pumpAndSettle();

      // Click submit
      await tester.tap(find.text('Masuk Ke Dashboard'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Verify the controller error message is displayed on screen
      expect(find.text('Username atau password salah'), findsOneWidget);
    });
  });
}
