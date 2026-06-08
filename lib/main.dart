import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_router.dart';
import 'features/dashboard/presentation/pages/transaction_history_page.dart';
import 'core/services/notification_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/dashboard/presentation/providers/cart_provider.dart';
import 'features/dashboard/presentation/providers/product_provider.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FlutterLocalNotificationsPlugin()
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'ecommerceapp' && uri.host == 'success') {
        NotificationService.showNotification(
          title: 'Pembayaran Berhasil! 🎉',
          body: 'Tagihan Anda berhasil dibayar menggunakan E-Money Mamah Saya.',
        );
        // Force routing ke halaman history
        if (navigatorKey.currentState != null) {
          // Hapus semua tumpukan layar (termasuk splash screen) agar tidak bentrok
          navigatorKey.currentState!.pushNamedAndRemoveUntil('/dashboard', (route) => false);
          navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (context) => const TransactionHistoryPage()),
          );
        }
      }
    }, onError: (err) {
      debugPrint('Error deep link: $err');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initializeAuth(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider()..fetchProducts(),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider()..fetchCart(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'My App',
        initialRoute: AppRouter.splash,
        routes: AppRouter.routes,
      ),
    );
  }
}