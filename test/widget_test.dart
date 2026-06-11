import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kucits/main.dart';
import 'package:kucits/app/router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();

    final mockUser = MockUser(
      isAnonymous: false,
      uid: 'test-uid-123',
      email: 'test@example.com',
      displayName: 'Test User',
    );
    AppRouter.authStateStream = Stream.value(mockUser);
    AppRouter.getCurrentUser = () => mockUser;
  });

  testWidgets('KucITS timeline smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KucITSApp());
    await tester.pump();
    expect(find.text('KucITS 🐱'), findsOneWidget);
  });
}
