import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'routing/app_router.dart';
import 'services/auth_controller.dart';
import 'services/auth_service.dart';
import 'services/branch_controller.dart';
import 'services/branch_service.dart';
import 'services/cart_controller.dart';
import 'services/catalog_controller.dart';
import 'services/catalog_service.dart';
import 'services/driver_orders_controller.dart';
import 'services/driver_orders_service.dart';
import 'services/driver_service.dart';
import 'services/notification_controller.dart';
import 'services/notification_service.dart';
import 'services/order_controller.dart';
import 'services/order_service.dart';
import 'services/supabase_bootstrap.dart';
import 'utils/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const MedLinkApp());
}

class MedLinkApp extends StatefulWidget {
  const MedLinkApp({super.key});

  @override
  State<MedLinkApp> createState() => _MedLinkAppState();
}

class _MedLinkAppState extends State<MedLinkApp> {
  late final AuthService _authService;
  late final AuthController _authController;
  late final CatalogService _catalogService;
  late final CatalogController _catalogController;
  late final OrderService _orderService;
  late final CartController _cartController;
  late final OrderController _orderController;
  late final BranchService _branchService;
  late final DriverService _driverService;
  late final BranchController _branchController;
  late final DriverOrdersService _driverOrdersService;
  late final DriverOrdersController _driverOrdersController;
  late final NotificationService _notificationService;
  late final NotificationController _notificationController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(supabase);
    _authController = AuthController(_authService);
    _catalogService = CatalogService(supabase);
    _catalogController = CatalogController(_catalogService);
    _orderService = OrderService(supabase);
    _cartController = CartController();
    _orderController = OrderController(_orderService);
    _branchService = BranchService(supabase);
    _driverService = DriverService(supabase);
    _branchController = BranchController(_branchService, _catalogService, _driverService);
    _driverOrdersService = DriverOrdersService(supabase);
    _driverOrdersController = DriverOrdersController(_driverOrdersService);
    _notificationService = NotificationService(supabase);
    _notificationController =
        NotificationController(_notificationService, _authController);
    _router = buildRouter(_authController);

    // Load bonus rules into cart controller on start
    _orderService.fetchBonusRules().then((rules) {
      _cartController.updateBonusRules(rules);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _authController.dispose();
    _catalogController.dispose();
    _cartController.dispose();
    _orderController.dispose();
    _branchController.dispose();
    _driverOrdersController.dispose();
    _notificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: _authService),
        ChangeNotifierProvider<AuthController>.value(value: _authController),
        Provider<CatalogService>.value(value: _catalogService),
        ChangeNotifierProvider<CatalogController>.value(
          value: _catalogController,
        ),
        Provider<OrderService>.value(value: _orderService),
        ChangeNotifierProvider<CartController>.value(value: _cartController),
        ChangeNotifierProvider<OrderController>.value(value: _orderController),
        Provider<BranchService>.value(value: _branchService),
        Provider<DriverService>.value(value: _driverService),
        ChangeNotifierProvider<BranchController>.value(value: _branchController),
        Provider<DriverOrdersService>.value(value: _driverOrdersService),
        ChangeNotifierProvider<DriverOrdersController>.value(
          value: _driverOrdersController,
        ),
        Provider<NotificationService>.value(value: _notificationService),
        ChangeNotifierProvider<NotificationController>.value(
          value: _notificationController,
        ),
      ],
      child: MaterialApp.router(
        title: 'MedLink Yemen',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (locale, supported) => const Locale('ar'),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
