import 'package:easy_sms_receiver/easy_sms_receiver.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:myapp/login.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DashBoard extends StatefulWidget {
  const DashBoard({Key? key}) : super(key: key);

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  final storage = const FlutterSecureStorage();
  final plugin = EasySmsReceiver.instance;
  final EasySmsReceiver easySmsReceiver = EasySmsReceiver.instance;
  String _easySmsReceiverStatus = "Undefined";
  String _message = "";
  Future<void> startSmsReceiver() async {
    // Platform messages may fail, so we use a try/catch PlatformException.

    easySmsReceiver.listenIncomingSms(
      onNewMessage: (message) {
        print("You have new message:");
        print("::::::Message Address: ${message.address}");
        print("::::::Message body: ${message.body}");

        if (!mounted) return;

        setState(() {
          _message = message.body ?? "Error reading message body.";
        });
      },
    );

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _easySmsReceiverStatus = "Running";
    });
  }

  void initState() {
// TODO: implement initState
    super.initState();

    startSmsReceiver();
  }

  logout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    await storage.delete(key: "tokken");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false, // Removes all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
      ),
      body: Column(
        children: [
          Text("Latest Received SMS: $_message"),
          Text('EasySmsReceiver Status: $_easySmsReceiverStatus\n'),
          Container(
            child: ElevatedButton(
              child: Text("Logout"),
              onPressed: logout,
            ),
          ),
        ],
      ),
    );
  }
}
