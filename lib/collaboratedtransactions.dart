import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';

class CollaboratedTransactionsPage extends StatefulWidget {
  final String collaboratedUserEmail;

  const CollaboratedTransactionsPage(
      {required this.collaboratedUserEmail, Key? key})
      : super(key: key);

  @override
  State<CollaboratedTransactionsPage> createState() =>
      _CollaboratedTransactionsPageState();
}

class _CollaboratedTransactionsPageState
    extends State<CollaboratedTransactionsPage> {
  DateTimeRange? _selectedDateRange;
  DateTime? _selectedDate;
  double _totalDebited = 0.0;
  double _totalCredited = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  Map<String, double> _transactionData = {};
  String name = "";

  @override
  void initState() {
    super.initState();
    _fetchAllCollaboratedTransactions();
    _fetchUserName();
  }

  void _showDeleteConfirmationDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Remove Collaboration"),
          content: Text("Do you want to remove this user from collaboration?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _deleteCollaborations(email);
              },
              child: Text(
                "Remove",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCollaborations(String email) async {
    User? user = FirebaseAuth.instance.currentUser;
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('collaborations')
          .where('user2', isEqualTo: email)
          .where('user1', isEqualTo: user!.email)
          .get();

      for (var doc in querySnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('collaborations')
            .doc(doc.id)
            .delete();
      }

      print("Collaborations deleted successfully for user2: $email");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("User removed from collaboration"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pushReplacementNamed(context, '/collaborators');
    } catch (e) {
      print("Error deleting collaborations: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Collaborated Transactions'),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              Container(
                  padding: EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text("Transactions"),
                    trailing: IconButton(
                        onPressed: () {
                          _showDeleteConfirmationDialog(
                              context, widget.collaboratedUserEmail);
                        },
                        icon: Icon(Icons.delete)),
                  )),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.calendar_today,
                      size: 35,
                      color: Colors.blue,
                    ),
                    onPressed: () => _showDateSelectionDialog(context),
                  ),
                  Text(
                    'Select date or date range',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
              if (_selectedDateRange != null)
                Container(
                  padding: EdgeInsets.only(left: 20),
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Selected Range: ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              if (_selectedDate != null)
                Container(
                  padding: EdgeInsets.only(left: 20),
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Selected Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              if (_transactions.isNotEmpty)
                Container(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: PieChart(
                      dataMap: _transactionData,
                      chartType: ChartType.ring,
                      chartRadius: MediaQuery.of(context).size.width / 2,
                      ringStrokeWidth: 32,
                      animationDuration: Duration(milliseconds: 800),
                      chartValuesOptions: ChartValuesOptions(
                          showChartValuesInPercentage: false,
                          showChartValuesOutside: false,
                          decimalPlaces: 1,
                          showChartValues: true),
                      legendOptions: LegendOptions(
                        showLegendsInRow: false,
                        legendPosition: LegendPosition.right,
                        showLegends: true,
                        legendShape: BoxShape.circle,
                        legendTextStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_transactions.isNotEmpty)
                Container(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return Container(
                        padding: EdgeInsets.all(8),
                        child: ListTile(
                          trailing: Icon(
                            transaction['type'] == 'debited'
                                ? Icons.trending_down
                                : Icons.trending_up,
                            color: transaction['type'] == 'debited'
                                ? Colors.red
                                : Colors.green,
                          ),
                          title: Text(
                            '₹${transaction['amount']}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                              'Date: ${transaction['date']} at ${transaction['time']} \n ${transaction['category']}'),
                        ),
                      );
                    },
                  ),
                ),
              if (_transactions.isEmpty)
                Center(
                  child: Text(
                    'No transactions found',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDateSelectionDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Date Option'),
          content:
              Text('Would you like to select a single date or a date range?'),
          actions: <Widget>[
            TextButton(
              child: Text('Single Date'),
              onPressed: () {
                Navigator.of(context).pop();
                _pickDate(context, isRange: false);
              },
            ),
            TextButton(
              child: Text('Date Range'),
              onPressed: () {
                Navigator.of(context).pop();
                _pickDate(context, isRange: true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDate(BuildContext context, {required bool isRange}) async {
    if (isRange) {
      DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.5,
              child: child,
            ),
          );
        },
      );

      if (picked != null) {
        setState(() {
          if (picked.start == picked.end) {
            _selectedDate = picked.start;
            _selectedDateRange = null;
          } else {
            _selectedDateRange = picked;
            _selectedDate = null;
          }
        });
        _fetchCollaboratedTransactions();
      }
    } else {
      DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.5,
              child: child,
            ),
          );
        },
      );

      if (picked != null) {
        setState(() {
          _selectedDate = picked;
          _selectedDateRange = null;
        });
        _fetchCollaboratedTransactions();
      }
    }
  }

  Future<void> _fetchCollaboratedTransactions() async {
    if (_selectedDateRange == null && _selectedDate == null) return;

    try {
      QuerySnapshot querySnapshot;
      if (_selectedDateRange != null) {
        querySnapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where('email', isEqualTo: widget.collaboratedUserEmail)
            .where('date',
                isGreaterThanOrEqualTo:
                    DateFormat('dd-MM-yyyy').format(_selectedDateRange!.start))
            .where('date',
                isLessThanOrEqualTo:
                    DateFormat('dd-MM-yyyy').format(_selectedDateRange!.end))
            .get();
      } else {
        querySnapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where('email', isEqualTo: widget.collaboratedUserEmail)
            .where('date',
                isEqualTo: DateFormat('dd-MM-yyyy').format(_selectedDate!))
            .get();
      }

      double totalDebited = 0.0;
      double totalCredited = 0.0;
      List<Map<String, dynamic>> transactions = [];
      for (var doc in querySnapshot.docs) {
        double amount = double.parse(doc['amount']);
        transactions.add(doc.data() as Map<String, dynamic>);
        if (doc['type'] == 'debited') {
          totalDebited += amount;
        } else if (doc['type'] == 'credited') {
          totalCredited += amount;
        }
      }

      setState(() {
        _totalDebited = totalDebited;
        _totalCredited = totalCredited;
        _transactions = transactions;
        _transactionData = {
          'Debited': _totalDebited,
          'Credited': _totalCredited,
        };
      });

      // Debug prints to verify data
      print("Total Debited: $_totalDebited");
      print("Total Credited: $_totalCredited");
      print("Transactions: $_transactions");
      print("Transaction Data: $_transactionData");
    } catch (e) {
      print("Error fetching transactions: $e");
    }
  }

  Future<void> _fetchAllCollaboratedTransactions() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('email', isEqualTo: widget.collaboratedUserEmail)
          .get();

      double totalDebited = 0.0;
      double totalCredited = 0.0;
      List<Map<String, dynamic>> transactions = [];
      for (var doc in querySnapshot.docs) {
        double amount = double.parse(doc['amount']);
        transactions.add(doc.data() as Map<String, dynamic>);
        if (doc['type'] == 'debited') {
          totalDebited += amount;
        } else if (doc['type'] == 'credited') {
          totalCredited += amount;
        }
      }

      setState(() {
        _totalDebited = totalDebited;
        _totalCredited = totalCredited;
        _transactions = transactions;
        _transactionData = {
          'Debited': _totalDebited,
          'Credited': _totalCredited,
        };
      });

      // Debug prints to verify data
      print("Total Debited: $_totalDebited");
      print("Total Credited: $_totalCredited");
      print("Transactions: $_transactions");
      print("Transaction Data: $_transactionData");
    } catch (e) {
      print("Error fetching transactions: $e");
    }
  }

  Future<void> _fetchUserName() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.collaboratedUserEmail)
          .get();
      Map<String, dynamic> userData =
          querySnapshot.docs[0].data() as Map<String, dynamic>;

      // Extract the name field

      setState(() {
        name = userData["name"] ?? "";
      });
    } catch (e) {
      print("Error fetching user name: $e");
    }
  }
}
