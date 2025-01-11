import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  DateTimeRange? _selectedDateRange;
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _transactions = [];
  double _totalSpent = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchAllTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.calendar_today,
                      size: 40,
                      color: Colors.blue,
                    ),
                    onPressed: () => _showDateSelectionDialog(context),
                  ),
                  Text(
                    'Select date or date range',
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
              if (_selectedDateRange != null)
                Container(
                  padding: EdgeInsets.only(left: 20),
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Selected Range: ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              if (_selectedDate != null)
                Text(
                  'Selected Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                ),
              if (_transactions.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No spend found',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              if (_transactions.isNotEmpty)
                Expanded(
                  child: ListView.builder(
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
                          tileColor: Colors.grey[300],
                          title: Text(
                            '₹${transaction['amount']}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Date: ${transaction['date']}'),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          // Align(
          //   alignment: Alignment.bottomCenter,
          //   child: Container(
          //     padding: EdgeInsets.all(16),
          //     color: Colors.white,
          //     child: Text(
          //       'Total Spent: $_totalSpent',
          //       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          //     ),
          //   ),
          // ),
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
        _fetchTransactions();
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
        _fetchTransactions();
      }
    }
  }

  Future<void> _fetchTransactions() async {
    if (_selectedDateRange == null && _selectedDate == null) return;

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot querySnapshot;
        if (_selectedDateRange != null) {
          querySnapshot = await FirebaseFirestore.instance
              .collection('transactions')
              .where('user', isEqualTo: user.uid)
              .where('date',
                  isGreaterThanOrEqualTo: DateFormat('dd-MM-yyyy')
                      .format(_selectedDateRange!.start))
              .where('date',
                  isLessThanOrEqualTo:
                      DateFormat('dd-MM-yyyy').format(_selectedDateRange!.end))
              .get();
        } else {
          querySnapshot = await FirebaseFirestore.instance
              .collection('transactions')
              .where('user', isEqualTo: user.uid)
              .where('date',
                  isEqualTo: DateFormat('dd-MM-yyyy').format(_selectedDate!))
              .get();
        }

        double totalAmount = 0.0;
        List<Map<String, dynamic>> transactions = [];
        for (var doc in querySnapshot.docs) {
          totalAmount += double.parse(doc['amount']);
          transactions.add(doc.data() as Map<String, dynamic>);
        }

        setState(() {
          _totalSpent = totalAmount;
          _transactions = transactions;
        });
      }
    } catch (e) {
      print("Error fetching transactions: $e");
    }
  }

  Future<void> _fetchAllTransactions() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where('user', isEqualTo: user.uid)
            .get();

        double totalAmount = 0.0;
        List<Map<String, dynamic>> transactions = [];
        for (var doc in querySnapshot.docs) {
          totalAmount += double.parse(doc['amount']);
          transactions.add(doc.data() as Map<String, dynamic>);
        }

        setState(() {
          _totalSpent = totalAmount;
          _transactions = transactions;
        });
      }
    } catch (e) {
      print("Error fetching transactions: $e");
    }
  }
}
