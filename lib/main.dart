import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:myapp/mainpage.dart';
import 'package:myapp/onboarding_screen.dart';
import 'package:myapp/welcome.dart';

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
  //DartPluginRegistrant.ensureInitialized();
  //await Firebase.initializeApp(); // Ensure Firebase is initialized here as well
  final storage = const FlutterSecureStorage();
  final plugin = EasySmsReceiver.instance;
  print("Service started");
  plugin.listenIncomingSms(
    onNewMessage: (message) async {
      DartPluginRegistrant.ensureInitialized();
      await Firebase.initializeApp();
      Map<String, String> allValues = await storage.readAll();
      print("tokken");
      print(allValues["tokken"]);
      if (allValues["tokken"] != null) {
        print("tokken true");
        if (message.body!.contains("credited")) {
          String formattedDate =
              DateFormat('dd-MM-yyyy').format(DateTime.now());
          RegExp regExp = RegExp(r'Rs\.(\d+)');
          Match? match = regExp.firstMatch(message.body!);
          if (match != null) {
            // Extract the matched string
            String amount = match.group(1)!;
            var transaction = {
              "amount": amount,
              "date": formattedDate,
              "type": "credited",
              "user": allValues["tokken"]
            };
            print(transaction);
            try {
              await FirebaseFirestore.instance
                  .collection('transactions')
                  .add(transaction);
              print('Transaction added successfully');
            } catch (e) {
              print('Failed to add transaction: $e');
            }
          } else {
            print("No match found in the message body.");
          }
        } else if (message.body!.contains("debited")) {
          String formattedDate =
              DateFormat('dd-MM-yyyy').format(DateTime.now());
          RegExp regExp = RegExp(r"debited by (\d+\.\d+)");
          Match? match = regExp.firstMatch(message.body!);

          if (match != null) {
            String amount = match.group(1)!;
            var transaction = {
              "amount": amount,
              "date": formattedDate,
              "type": "debited",
              "user": allValues["tokken"]
            };
            print(transaction);
            try {
              await FirebaseFirestore.instance
                  .collection('transactions')
                  .add(transaction);
              print('Transaction added successfully');
            } catch (e) {
              print('Failed to add transaction: $e');
            }
          } else {
            print("No amount found");
          }
        }
      } else {
        print("Token is null.");
      }
    },
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
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
          //filled: true,
          //fillColor: Colors.grey[200],
          //hintStyle: TextStyle(color: Colors.grey[100]),
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
        '/login': (context) => LoginPage(),
        '/welcome': (context) => MainPage(),
      },
      themeMode:
          ThemeMode.light, // Automatically switches based on system settings
      home: OnboardingScreen(),
    );
  }
}
