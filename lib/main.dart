import 'dart:ui';
import 'package:myapp/onboarding_screen.dart';

import 'registration_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:myapp/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_options.dart';

import 'package:easy_sms_receiver/easy_sms_receiver.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

// function to initialize the background service
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    iosConfiguration: IosConfiguration(),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  final storage = const FlutterSecureStorage();
  final plugin = EasySmsReceiver.instance;

  plugin.listenIncomingSms(
    onNewMessage: (message) async {
      Map<String, String> allValues = await storage.readAll();

      print(allValues["tokken"]);
      if (allValues["tokken"] != null) {
        print("jishnu true");
        print("You have new message:");
        print("::::::Message Address: ${message.address}");
        print("::::::Message body: ${message.body}");
      }

      // do something

      // for example: show notification
      // if (service is AndroidServiceInstance) {
      //   service.setForegroundNotificationInfo(
      //     title: message.address ?? "address",
      //     content: message.body ?? "body",
      //   );
      // }
    },
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
// request the SMS permission, then initialize the background service
  Permission.sms.request().then((status) {
    if (status.isGranted) initializeService();
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Theme Demo',
      theme: ThemeData(
        useMaterial3: true, // Enables Material 3 styling
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal, // Automatically generates a color scheme
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[200],
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.red,
          foregroundColor: Colors.black,
          elevation: 2,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      routes: {
        '/registration': (context) => RegistrationPage(),
      },
      themeMode:
          ThemeMode.light, // Automatically switches based on system settings
      home: const OnboardingScreen(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to the custom-themed app!',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: Text('Click Me'),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Enter something',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
