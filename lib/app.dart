import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/auth/login_screen.dart';
import 'screens/root_shell.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

class TheLittleNurseryApp extends StatefulWidget {
  const TheLittleNurseryApp({super.key});

  @override
  State<TheLittleNurseryApp> createState() => _TheLittleNurseryAppState();
}

class _TheLittleNurseryAppState extends State<TheLittleNurseryApp> {
  bool _notificationsRequested = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Little Nursery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (auth.isSignedIn) {
            if (!_notificationsRequested) {
              _notificationsRequested = true;
              // Registers this device for push notifications once, the
              // first time a parent is signed in.
              context.read<NotificationService>().initialize();
            }
            return const RootShell();
          }
          _notificationsRequested = false;
          return const LoginScreen();
        },
      ),
    );
  }
}
