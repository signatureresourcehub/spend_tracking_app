import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_sms_receiver/easy_sms_receiver.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:myapp/login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

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
  String _userName = "Loading...";
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
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? name;
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          name = user.displayName; // Fetch name from Google account
        } else {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          name = userDoc['name'];
        }
        setState(() {
          _userName = name ?? 'User';
        });
      }
    } catch (e) {
      print("Error fetching user name: $e");
    }
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
      // appBar: AppBar(
      //   title: Text("Dashboard"),
      // ),
      body: Column(
        children: [
          SizedBox(height: 40),
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(
                    Icons.account_circle,
                    size: 40,
                    color: Colors.white,
                  ), // Display the first letter of the user's name
                ),
                SizedBox(width: 8),
                Text("Hi,",
                    style: TextStyle(
                      fontSize: 16,
                    )),
                Text(_userName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16)), // Display the user's name
              ],
            ),
          ),
          // SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            alignment: Alignment.topLeft,
            child: Text(
              "${DateFormat('MMMM dd').format(DateTime.now())}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.greenAccent, Colors.green],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
            child: Card(
              color: Colors.transparent, // Make the card background transparent
              elevation: 0, // Remove card shadow
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          "Spend",
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "\₹500",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          "Income",
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          "\₹1000",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
