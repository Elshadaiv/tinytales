import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tinytales/pages/auth_page.dart';
import 'package:tinytales/services/notification_service.dart';
import 'services/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 await  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.init();
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin
      .resolvePlatformSpecificImplementation<//ios
      IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: false);

  final androidPlugin = plugin
      .resolvePlatformSpecificImplementation<//android
      AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.requestNotificationsPermission();

  runApp(const TinyTalesApp());
}

class TinyTalesApp extends StatelessWidget {
  const TinyTalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple
      ),
      home: const AuthPage(),//
    );
  }
}



