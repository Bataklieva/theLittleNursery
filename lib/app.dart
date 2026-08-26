import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'screens/auth/login_screen.dart';
import 'screens/root_shell.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

class TheLittleNurseryApp extends StatefulWidget {
  const TheLittleNurseryApp({super.key});

  @override
  State<TheLittleNurseryApp> createState() => _TheLittleNurseryAppState();
}

class _TheLittleNurseryAppState extends State<TheLittleNurseryApp> {
  bool _notificationsRequested = false;
  bool _cartClearedForSignedOut = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Little Nursery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (auth.isSignedIn) {
            _cartClearedForSignedOut = false;
            if (!_notificationsRequested) {
              _notificationsRequested = true;
              // Registers this device for push notifications once, the
              // first time a parent is signed in.
              context.read<NotificationService>().initialize();
            }
            return const RootShell();
          }
          _notificationsRequested = false;
          if (!_cartClearedForSignedOut) {
            _cartClearedForSignedOut = true;
            // A shared device shouldn't carry one parent's cart into the
            // next parent's session. Deferred a frame since notifying
            // CartService listeners mid-build here would be unsafe.
            SchedulerBinding.instance.addPostFrameCallback((_) {
              context.read<CartService>().clear();
            });
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
