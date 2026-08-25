import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/article_service.dart';
import 'services/auth_service.dart';
import 'services/booking_service.dart';
import 'services/event_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const _AppProviders());
}

/// Wires up app-wide services. AuthService is created first since
/// NotificationService depends on it to save the device's push token to
/// the signed-in parent's profile.
class _AppProviders extends StatelessWidget {
  const _AppProviders();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => EventService()),
        Provider(create: (_) => BookingService()),
        Provider(create: (_) => ArticleService()),
        ProxyProvider<AuthService, NotificationService>(
          update: (_, auth, previous) =>
              previous ?? NotificationService(auth),
        ),
      ],
      child: const TheLittleNurseryApp(),
    );
  }
}
