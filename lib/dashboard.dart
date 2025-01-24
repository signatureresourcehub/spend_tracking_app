import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_sms_receiver/easy_sms_receiver.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:myapp/login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:myapp/setbudget.dart';

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
  double _debitedAmount = 0.0;
  double? _budgetAmount;
  List<Map<String, dynamic>> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _refreshPage();
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

  Future<void> _fetchDebitAmount() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where('user', isEqualTo: user.uid)
            .where('date', isEqualTo: formattedDate)
            .where('type', isEqualTo: 'debited')
            .get();

        double totalAmount = 0.0;
        for (var doc in querySnapshot.docs) {
          totalAmount += double.parse(doc['amount']);
        }

        setState(() {
          _debitedAmount = totalAmount;
        });
      }
    } catch (e) {
      print("Error fetching debited amount: $e");
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

  Future<void> _fetchRecentTransactions() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where('user', isEqualTo: user.uid)
            .orderBy('date', descending: true)
            .limit(3)
            .get();

        List<Map<String, dynamic>> transactions = [];
        for (var doc in querySnapshot.docs) {
          transactions.add(doc.data() as Map<String, dynamic>);
        }

        setState(() {
          _recentTransactions = transactions;
        });
      }
    } catch (e) {
      print("Error fetching recent transactions: $e");
    }
  }

  Future<void> _fetchBudget() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('budget')
            .doc(user.uid)
            .get();

        if (snapshot.exists) {
          setState(() {
            _budgetAmount = snapshot['amount'];
          });
        }
      }
    } catch (e) {
      print("Error fetching budget: $e");
    }
  }

  Future<void> _refreshPage() async {
    print("Refreshing page...");
    await _fetchUserName();
    await _fetchCreditedAmount();
    await _fetchDebitAmount();
    await _fetchRecentTransactions();
    await _fetchBudget();
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
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: ListView(
          children: [
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
                    ),
                  ),
                  SizedBox(width: 8),
                  Text("Hi,",
                      style: TextStyle(
                        fontSize: 16,
                      )),
                  Text(_userName,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            if (_budgetAmount != null && _debitedAmount > _budgetAmount!)
              Container(
                padding: EdgeInsets.all(16),
                alignment: Alignment.topLeft,
                child: Text(
                  "Budget exceeded for ${DateFormat('MMMM dd').format(DateTime.now())}",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
              ),
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
                color: Colors.transparent,
                elevation: 0,
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
                            "\₹$_debitedAmount",
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
            Container(
              padding: EdgeInsets.all(16),
              alignment: Alignment.topLeft,
              child: Text(
                "Recent Transactions:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (_recentTransactions.isNotEmpty)
              ..._recentTransactions.map((transaction) {
                return ListTile(
                  title: Text('₹${transaction['amount']}'),
                  subtitle: Text('${transaction['date']}'),
                  trailing: Icon(
                    transaction['type'] == 'debited'
                        ? Icons.trending_down
                        : Icons.trending_up,
                    color: transaction['type'] == 'debited'
                        ? Colors.red
                        : Colors.green,
                  ),
                );
              }).toList(),
            Container(
              padding: EdgeInsets.all(16),
              child: ListTile(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SetBudgetPage()));
                },
                leading: Text(
                  "₹",
                  style: TextStyle(fontSize: 20),
                ),
                tileColor: Colors.grey[200],
                title: Text("Set Budget",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
