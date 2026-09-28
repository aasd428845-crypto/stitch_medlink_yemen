import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:medlink_app/l10n/app_localizations.dart';
import 'package:medlink_app/models/order.dart';
import 'package:medlink_app/screens/branch_manager/branch_order_actions.dart';
import 'package:medlink_app/services/branch_controller.dart';
import 'package:medlink_app/services/branch_service.dart';
import 'package:medlink_app/services/catalog_service.dart';
import 'package:medlink_app/services/driver_service.dart';
import 'package:medlink_app/utils/theme.dart';

/// Offline fakes: override every network method. Records calls so tests
/// prove which path executed (RPC vs direct write).
class FakeBranchService extends BranchService {
  FakeBranchService._(super.client);

  factory FakeBranchService() => FakeBranchService._(
        SupabaseClient(
          'https://localhost:1',
          'anon',
          authOptions: const FlutterAuthClientOptions(
            autoRefreshToken: false,
          ),
        ),
      );

  final List<Map<String, Object?>> rpcCancels = [];
  final List<Map<String, String>> directUpdates = [];
  Object? nextError;
  Completer<String?>? gate;

  @override
  Future<String?> cancelOrderWithDiscount({
    required String orderId,
    required String reason,
    String? idempotencyKey,
  }) async {
    rpcCancels.add({
      'orderId': orderId,
      'reason': reason,
      'key': idempotencyKey,
    });
    if (gate != null) await gate!.future;
    final err = nextError;
    if (err != null) {
      nextError = null;
      throw err;
    }
    return 'reversal-9';
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    directUpdates.add({'orderId': orderId, 'status': status});
  }

}

class FakeCatalogService extends CatalogService {
  FakeCatalogService()
      : super(
          SupabaseClient(
            'https://localhost:1',
            'anon',
            authOptions: const FlutterAuthClientOptions(
              autoRefreshToken: false,
            ),
          ),
        );
}

class FakeDriverService extends DriverService {
  FakeDriverService()
      : super(
          SupabaseClient(
            'https://localhost:1',
            'anon',
            authOptions: const FlutterAuthClientOptions(
              autoRefreshToken: false,
            ),
          ),
        );
}

OrderModel testOrder() => OrderModel(
      id: 'order-1',
      clientId: 'client-1',
      status: 'pending',
      totalAmount: 1000,
    );

class TestBranchController extends BranchController {
  TestBranchController(super.a, super.b, super.c);

  int reloads = 0;

  @override
  Future<void> loadOrders() async {
    reloads++;
  }
}

TestBranchController testController(FakeBranchService service) =>
    TestBranchController(service, FakeCatalogService(), FakeDriverService());

void main() {
  group('BranchController.cancelOrderWithDiscount', () {
    test('uses the financial RPC, never a direct write', () async {
      final service = FakeBranchService();
      final controller = testController(service);
      final id = await controller.cancelOrderWithDiscount(
        orderId: 'order-1',
        reason: 'out of stock',
      );
      expect(id, 'reversal-9');
      expect(service.rpcCancels.length, 1);
      expect(service.rpcCancels.single['orderId'], 'order-1');
      expect(service.rpcCancels.single['reason'], 'out of stock');
      expect(service.rpcCancels.single['key'], isNotNull);
      expect(service.directUpdates, isEmpty);
      expect(controller.reloads, 1);
      expect(controller.cancelError, isNull);
    });

    test('retry reuses the idempotency key; new reason mints fresh', () async {
      final service = FakeBranchService();
      final controller = testController(service);
      service.nextError = Exception('timeout');
      await expectLater(
        controller.cancelOrderWithDiscount(
            orderId: 'order-1', reason: 'r1'),
        throwsException,
      );
      expect(controller.cancelError, isNotNull);
      await controller.cancelOrderWithDiscount(
          orderId: 'order-1', reason: 'r1');
      expect(service.rpcCancels[0]['key'], service.rpcCancels[1]['key']);
      await controller.cancelOrderWithDiscount(
          orderId: 'order-1', reason: 'r2');
      expect(service.rpcCancels[1]['key'] != service.rpcCancels[2]['key'],
          isTrue);
    });

    test('concurrent double submit issues one RPC', () async {
      final service = FakeBranchService();
      service.gate = Completer<String?>();
      final controller = testController(service);
      final first = controller.cancelOrderWithDiscount(
        orderId: 'order-1',
        reason: 'r',
      );
      final second = await controller.cancelOrderWithDiscount(
        orderId: 'order-1',
        reason: 'r',
      );
      expect(second, isNull);
      service.gate!.complete('reversal-9');
      expect(await first, 'reversal-9');
      expect(service.rpcCancels.length, 1);
    });
  });

  group('showRejectOrderConfirm dialog', () {
    Future<void> pumpDialog(
      WidgetTester tester,
      BranchController controller,
    ) async {
      // Provider wraps MaterialApp (mirrors main.dart) so dialog routes
      // pushed on the app Navigator can still read the controller.
      await tester.pumpWidget(
        ChangeNotifierProvider<BranchController>.value(
          value: controller,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const [AppLocalizations.delegate],
            theme: AppTheme.clientLight,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showRejectOrderConfirm(
                    context,
                    testOrder(),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('confirm with reason calls RPC once, never direct write',
        (tester) async {
      final service = FakeBranchService();
      await pumpDialog(tester, testController(service));
      await tester.enterText(find.byType(TextField), 'out of stock');
      await tester.tap(find.widgetWithText(FilledButton, 'Reject Order'));
      await tester.pumpAndSettle();
      expect(service.rpcCancels.length, 1);
      expect(service.rpcCancels.single['reason'], 'out of stock');
      expect(service.directUpdates, isEmpty);
    });

    testWidgets('empty reason blocks submit with validation', (tester) async {
      final service = FakeBranchService();
      await pumpDialog(tester, testController(service));
      await tester.tap(find.widgetWithText(FilledButton, 'Reject Order'));
      await tester.pumpAndSettle();
      expect(service.rpcCancels, isEmpty);
      expect(service.directUpdates, isEmpty);
      expect(find.text('Please enter a cancellation reason'), findsOneWidget);
    });

    testWidgets('double-tap confirm issues one RPC', (tester) async {
      final service = FakeBranchService();
      service.gate = Completer<String?>();
      await pumpDialog(tester, testController(service));
      await tester.enterText(find.byType(TextField), 'r');
      await tester.tap(find.widgetWithText(FilledButton, 'Reject Order'));
      await tester.tap(find.widgetWithText(FilledButton, 'Reject Order'));
      service.gate!.complete('reversal-9');
      await tester.pumpAndSettle();
      expect(service.rpcCancels.length, 1);
    });

    testWidgets('RPC failure shows error and keeps dialog open',
        (tester) async {
      final service = FakeBranchService();
      service.nextError = Exception('boom');
      await pumpDialog(tester, testController(service));
      await tester.enterText(find.byType(TextField), 'r');
      await tester.tap(find.widgetWithText(FilledButton, 'Reject Order'));
      await tester.pumpAndSettle();
      expect(service.rpcCancels.length, 1);
      expect(find.textContaining('boom'), findsOneWidget);
      // Dialog stays open (confirm button still present).
      expect(find.widgetWithText(FilledButton, 'Reject Order'), findsOneWidget);
    });
  });
}
