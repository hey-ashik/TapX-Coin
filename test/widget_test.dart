import 'package:flutter_test/flutter_test.dart';
import 'package:soul/main.dart';
import 'package:soul/providers/tap_engine_provider.dart';
import 'package:soul/providers/wallet_provider.dart';

void main() {
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

    testWidgets('TapXApp loads MainScaffoldScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const TapXApp());
      await tester.pumpAndSettle();

      expect(find.text('TAPX'), findsOneWidget);
      expect(find.text('TOTAL SCORE'), findsOneWidget);
    });
  });
}
