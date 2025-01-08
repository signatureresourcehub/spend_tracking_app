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
  String _message = "";
  String _userName = "Loading...";
  double _creditedAmount = 0.0;
  void initState() {
// TODO: implement initState
    super.initState();

    // startSmsReceiver();
    _fetchUserName();
    _fetchCreditedAmount();
  }

  Future<void> _fetchCreditedAmount() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where('user', isEqualTo: user.uid)
            .where('date', isEqualTo: formattedDate)
            .where('type', isEqualTo: 'credited')
            .get();

        double totalAmount = 0.0;
        for (var doc in querySnapshot.docs) {
          totalAmount += double.parse(doc['amount']);
        }

        setState(() {
          _creditedAmount = totalAmount;
        });
      }
    } catch (e) {
      print("Error fetching credited amount: $e");
    }
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

  Future<void> _refreshPage() async {
    print("Refreshing page...");
    await _fetchUserName();
    await _fetchCreditedAmount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text("Dashboard"),
      // ),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: ListView(
          children: [
            // SizedBox(height: 50),
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
                color:
                    Colors.transparent, // Make the card background transparent
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
                            "\₹$_creditedAmount",
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
            // Text("Latest Received SMS: $_message"),
            // Text('EasySmsReceiver Status: $_easySmsReceiverStatus\n'),
            Container(
              child: ElevatedButton(
                child: Text("Logout"),
                onPressed: logout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
