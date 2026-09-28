import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:medlink_app/l10n/app_localizations.dart';
import 'package:medlink_app/screens/client/order_discount_section.dart';
import 'package:medlink_app/services/bonus_wallet_controller.dart';
import 'package:medlink_app/services/bonus_wallet_service.dart';

/// Offline fake: overrides every network method, so no test touches
/// Supabase. Records calls for idempotency assertions.
class FakeWalletService extends BonusWalletService {
  FakeWalletService._(super.client) : raw = client;

  factory FakeWalletService() => FakeWalletService._(
        SupabaseClient(
          'https://localhost:1',
          'anon',
          authOptions: const FlutterAuthClientOptions(
            autoRefreshToken: false,
          ),
        ),
      );

  final SupabaseClient raw;

  final List<Map<String, Object?>> discountCalls = [];
  final List<Map<String, Object?>> removalCalls = [];
  int fundsCalls = 0;
  int ledgerCalls = 0;
  Object? nextDiscountError;
  Object? nextRemovalError;
  Completer<String>? gate;

  @override
  Future<BonusFunds> fetchMyFunds() async {
    fundsCalls++;
    return const BonusFunds(available: 500, reserved: 0);
  }

  @override
  Future<List<BonusLedgerEntry>> fetchMyLedger({int limit = 100}) async {
    ledgerCalls++;
    return const [];
  }

  @override
  Future<List<BonusRedemption>> fetchMyRedemptions({int limit = 50}) async =>
      const [];

  @override
  Future<List<BonusWithdrawal>> fetchMyWithdrawals({int limit = 50}) async =>
      const [];

  @override
  Future<String> requestOrderDiscount({
    required String orderId,
    required double amount,
    String? idempotencyKey,
  }) async {
    discountCalls.add({
      'orderId': orderId,
      'amount': amount,
      'key': idempotencyKey,
    });
    if (gate != null) await gate!.future;
    final err = nextDiscountError;
    if (err != null) {
      nextDiscountError = null;
      throw err;
    }
    return 'ledger-1';
  }

  @override
  Future<String> cancelOrderDiscount({
    required String orderId,
    String? reason,
    String? idempotencyKey,
  }) async {
    removalCalls.add({'orderId': orderId, 'key': idempotencyKey});
    final err = nextRemovalError;
    if (err != null) {
      nextRemovalError = null;
      throw err;
    }
    return 'reversal-1';
  }
}

void main() {
  group('discountOperationSig', () {
    test('same inputs share one signature', () {
      expect(
        discountOperationSig('o1', 100),
        discountOperationSig('o1', 100),
      );
    });

    test('amount change starts a new logical operation', () {
      expect(
        discountOperationSig('o1', 100) == discountOperationSig('o1', 200),
        isFalse,
      );
    });

    test('order change starts a new logical operation', () {
      expect(
        discountOperationSig('o1', 100) == discountOperationSig('o2', 100),
        isFalse,
      );
    });
  });

  group('submitOrderDiscount', () {
    test('success returns ledger id and clears error', () async {
      final service = FakeWalletService();
      final controller = BonusWalletController(service);
      final id = await controller.submitOrderDiscount(
        orderId: 'order-1',
        amount: 100,
      );
      expect(id, 'ledger-1');
      expect(controller.error, isNull);
      expect(service.discountCalls.length, 1);
      expect(service.discountCalls.single['orderId'], 'order-1');
      expect(service.discountCalls.single['amount'], 100);
      expect(service.discountCalls.single['key'], isNotNull);
    });

    test('retry after failure reuses the same idempotency key', () async {
      final service = FakeWalletService();
      final controller = BonusWalletController(service);
      service.nextDiscountError = Exception('timeout');
      await expectLater(
        controller.submitOrderDiscount(orderId: 'order-1', amount: 100),
        throwsException,
      );
      final id = await controller.submitOrderDiscount(
        orderId: 'order-1',
        amount: 100,
      );
      expect(id, 'ledger-1');
      expect(service.discountCalls.length, 2);
      expect(
        service.discountCalls[0]['key'],
        service.discountCalls[1]['key'],
      );
    });

    test('amount change mints a fresh key', () async {
      final service = FakeWalletService();
      final controller = BonusWalletController(service);
      service.nextDiscountError = Exception('timeout');
      await expectLater(
        controller.submitOrderDiscount(orderId: 'order-1', amount: 100),
        throwsException,
      );
      await controller.submitOrderDiscount(orderId: 'order-1', amount: 200);
      expect(
        service.discountCalls[0]['key'] != service.discountCalls[1]['key'],
        isTrue,
      );
    });

    test('concurrent double submit issues one RPC', () async {
      final service = FakeWalletService();
      service.gate = Completer<String>();
      final controller = BonusWalletController(service);
      final first = controller.submitOrderDiscount(
        orderId: 'order-1',
        amount: 100,
      );
      final second = await controller.submitOrderDiscount(
        orderId: 'order-1',
        amount: 100,
      );
      expect(second, isNull);
      service.gate!.complete('ledger-1');
      expect(await first, 'ledger-1');
      expect(service.discountCalls.length, 1);
    });

    test('remove discount returns reversal id', () async {
      final service = FakeWalletService();
      final controller = BonusWalletController(service);
      final id = await controller.removeOrderDiscount(orderId: 'order-1');
      expect(id, 'reversal-1');
      expect(service.removalCalls.length, 1);
      expect(service.removalCalls.single['orderId'], 'order-1');
    });
  });

  group('OrderDiscountSection widget', () {
    Future<void> pumpSection(
      WidgetTester tester,
      BonusWalletController controller,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [AppLocalizations.delegate],
          home: Scaffold(
            body: ChangeNotifierProvider<BonusWalletController>.value(
              value: controller,
              child: OrderDiscountSection(
                orderId: 'order-1',
                status: 'pending',
                totalAmount: 1000,
                onChanged: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders funds and applies once per tap', (tester) async {
      final service = FakeWalletService();

      final controller = BonusWalletController(service);
      await pumpSection(tester, controller);
      expect(find.text('Available bonus'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '100');
      await tester.tap(find.text('Apply discount'));
      await tester.pumpAndSettle();
      expect(service.discountCalls.length, 1);
    });

    testWidgets('invalid amount submits nothing', (tester) async {
      final service = FakeWalletService();

      final controller = BonusWalletController(service);
      await pumpSection(tester, controller);
      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.text('Apply discount'));
      await tester.pumpAndSettle();
      expect(service.discountCalls, isEmpty);
    });

    testWidgets('non-pending order renders nothing', (tester) async {
      final service = FakeWalletService();

      final controller = BonusWalletController(service);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [AppLocalizations.delegate],
          home: Scaffold(
            body: ChangeNotifierProvider<BonusWalletController>.value(
              value: controller,
              child: OrderDiscountSection(
                orderId: 'order-1',
                status: 'assigned',
                totalAmount: 1000,
                onChanged: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Apply discount'), findsNothing);
    });
  });
}
