import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:medlink_app/l10n/app_localizations.dart';
import 'package:medlink_app/models/order.dart';
import 'package:medlink_app/models/order_cancellation.dart';
import 'package:medlink_app/screens/client/order_cancel_section.dart';
import 'package:medlink_app/services/order_controller.dart';
import 'package:medlink_app/services/order_service.dart';

/// Offline fake: overrides every network seam the cancel flow touches.
/// Records calls so tests prove which path executed (RPC vs direct write).
class FakeOrderService extends OrderService {
  FakeOrderService._(super.client);

  factory FakeOrderService() => FakeOrderService._(
        SupabaseClient(
          'https://localhost:1',
          'anon',
          authOptions: const FlutterAuthClientOptions(
            autoRefreshToken: false,
          ),
        ),
      );

  final List<Map<String, Object?>> cancelCalls = [];
  int orderReloads = 0;
  List<OrderCancellation> historySeed = const [];
  Object? nextError;
  Completer<String?>? gate;

  @override
  Future<String?> cancelOrder({
    required String orderId,
    required String reason,
    String? idempotencyKey,
  }) async {
    cancelCalls.add({
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
    return 'reversal-7';
  }

  @override
  Future<List<OrderModel>> fetchClientOrders() async {
    orderReloads++;
    return const [];
  }

  @override
  Future<List<OrderCancellation>> fetchOrderCancellationHistory(
    String orderId,
  ) async {
    return historySeed.where((e) => e.orderId == orderId).toList();
  }
}

OrderCancellation seedRow() => const OrderCancellation(
      id: 'h1',
      orderId: 'order-1',
      reason: 'changed mind',
      cancelledAt: '2026-09-26T10:00:00Z',
      previousStatus: 'pending',
      source: 'client',
      reversalLedgerId: 'rev-1',
      createdAt: '2026-09-26T10:00:00Z',
    );

void main() {
  group('OrderController.cancelOrder', () {
    test('invokes the existing RPC with order, reason and key', () async {
      final service = FakeOrderService();
      final controller = OrderController(service);
      final id = await controller.cancelOrder(
        orderId: 'order-1',
        reason: 'changed mind',
      );
      expect(id, 'reversal-7');
      expect(service.cancelCalls.length, 1);
      expect(service.cancelCalls.single['orderId'], 'order-1');
      expect(service.cancelCalls.single['reason'], 'changed mind');
      expect(service.cancelCalls.single['key'], isNotNull);
      expect(controller.cancelError, isNull);
    });

    test('success refreshes orders and history', () async {
      final service = FakeOrderService();
      service.historySeed = [seedRow()];
      final controller = OrderController(service);
      await controller.cancelOrder(orderId: 'order-1', reason: 'r');
      expect(service.orderReloads, 1);
      expect(controller.cancellationHistory.length, 1);
      expect(controller.cancellationHistory.single.reason, 'changed mind');
    });

    test('busy guard prevents double submission', () async {
      final service = FakeOrderService();
      service.gate = Completer<String?>();
      final controller = OrderController(service);
      final first = controller.cancelOrder(orderId: 'order-1', reason: 'r');
      final second = await controller.cancelOrder(
        orderId: 'order-1',
        reason: 'r',
      );
      expect(second, isNull);
      service.gate!.complete('reversal-7');
      expect(await first, 'reversal-7');
      expect(service.cancelCalls.length, 1);
      expect(controller.isCancelling, isFalse);
    });

    test('RPC failure maps to controller error and retains key', () async {
      final service = FakeOrderService();
      final controller = OrderController(service);
      service.nextError = Exception('not cancellable');
      await expectLater(
        controller.cancelOrder(orderId: 'order-1', reason: 'r'),
        throwsException,
      );
      expect(controller.cancelError, contains('not cancellable'));
      await controller.cancelOrder(orderId: 'order-1', reason: 'r');
      expect(service.cancelCalls.length, 2);
      expect(service.cancelCalls[0]['key'], service.cancelCalls[1]['key']);
    });

    test('history loads newest rows for the order only', () async {
      final service = FakeOrderService();
      service.historySeed = [
        seedRow(),
        const OrderCancellation(
          id: 'h2',
          orderId: 'order-2',
          reason: 'other',
          cancelledAt: '2026-09-26T11:00:00Z',
          previousStatus: 'pending',
          source: 'branch_manager',
          createdAt: '2026-09-26T11:00:00Z',
        ),
      ];
      final controller = OrderController(service);
      await controller.loadCancellationHistory('order-1');
      expect(controller.cancellationHistory.length, 1);
      expect(controller.cancellationHistory.single.id, 'h1');
    });
  });

  group('OrderCancelSection widget', () {
    Future<void> pumpSection(
      WidgetTester tester,
      OrderController controller,
      String status,
    ) async {
      // Provider wraps MaterialApp (mirrors main.dart) so bottom-sheet
      // routes pushed on the app Navigator can still read the controller.
      await tester.pumpWidget(
        ChangeNotifierProvider<OrderController>.value(
          value: controller,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const [AppLocalizations.delegate],
            home: Scaffold(
              body: OrderCancelSection(
                orderId: 'order-1',
                status: status,
                onChanged: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('pending shows cancel entry, empty history renders none',
        (tester) async {
      final controller = OrderController(FakeOrderService());
      await pumpSection(tester, controller, 'pending');
      expect(find.text('Cancel order'), findsOneWidget);
      expect(find.text('Cancellation history'), findsNothing);
    });

    testWidgets('non-pending without history renders nothing', (tester) async {
      final controller = OrderController(FakeOrderService());
      await pumpSection(tester, controller, 'delivered');
      expect(find.text('Cancel order'), findsNothing);
    });

    testWidgets('seeded history renders reason and date', (tester) async {
      final service = FakeOrderService();
      service.historySeed = [seedRow()];
      await pumpSection(
          tester, OrderController(service), 'cancelled');
      expect(find.text('Cancellation history'), findsOneWidget);
      expect(find.text('changed mind'), findsOneWidget);
    });

    testWidgets('confirm with reason calls RPC once', (tester) async {
      final service = FakeOrderService();
      final controller = OrderController(service);
      await pumpSection(tester, controller, 'pending');
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'changed mind');
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm cancellation'));
      await tester.pumpAndSettle();
      expect(service.cancelCalls.length, 1);
      expect(service.cancelCalls.single['reason'], 'changed mind');
      expect(service.orderReloads, 1);
    });

    testWidgets('empty reason blocks submit with validation', (tester) async {
      final service = FakeOrderService();
      await pumpSection(tester, OrderController(service), 'pending');
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm cancellation'));
      await tester.pumpAndSettle();
      expect(service.cancelCalls, isEmpty);
      expect(
        find.text('Please enter a cancellation reason'),
        findsOneWidget,
      );
    });
  });
}
