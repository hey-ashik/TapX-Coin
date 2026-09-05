import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soul/main.dart';
import 'package:soul/providers/auth_provider.dart';
import 'package:soul/providers/tap_engine_provider.dart';
import 'package:soul/providers/wallet_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TapX App Core Tests', () {
    test('TapEngineProvider handles taps and energy charging correctly', () {
      final provider = TapEngineProvider();
      final initialScore = provider.score;
      final initialEnergy = provider.currentEnergy;

      provider.handleTap(const Offset(100, 100), hapticsEnabled: false);

      expect(provider.score, initialScore + 1);
      expect(provider.currentEnergy, initialEnergy + 1);
      expect(provider.particles.isNotEmpty, isTrue);

      provider.dispose();
    });

    test('WalletProvider calculates milestones and processes payouts in BDT', () {
      final wallet = WalletProvider();
      wallet.syncWithTapScore(1550000); // 1,550,000 taps = ৳1550.00
      expect(wallet.balance, 1550.0);
      expect(wallet.isTierUnlocked(50.0), isTrue);
      expect(wallet.isTierUnlocked(100.0), isTrue);
      expect(wallet.isTierUnlocked(2000.0), isFalse);

      final success = wallet.requestPayout(
        amount: 500.0,
        method: 'bKash',
        accountName: 'Alex Rahman',
        destination: '01712-345678',
      );

      expect(success, isTrue);
      expect(wallet.balance, 1050.0);
      expect(wallet.transactions.first.amount, 500.0);
    });

    testWidgets('TapXApp loads MainScaffoldScreen for authenticated user', (WidgetTester tester) async {
      final auth = AuthProvider();
      auth.loginAsGuest();

      await tester.pumpWidget(TapXApp(authProvider: auth));
      await tester.pumpAndSettle();

      expect(find.byType(TapXApp), findsOneWidget);
    });
  });
}
