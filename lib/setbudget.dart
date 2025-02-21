import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SetBudgetPage extends StatefulWidget {
  const SetBudgetPage({super.key});

  @override
  State<SetBudgetPage> createState() => _SetBudgetPageState();
}

class _SetBudgetPageState extends State<SetBudgetPage> {
  final TextEditingController _budgetController = TextEditingController();
  final CollectionReference _budgetCollection =
      FirebaseFirestore.instance.collection('budget');
  final _formKey = GlobalKey<FormState>();
  String? _currentBudget;
  User? _currentUser;
  double _averageSpent = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _fetchAverageSpendForLastTwoMonths();
  }

  Future<void> _fetchAverageSpendForLastTwoMonths() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DateTime now = DateTime.now();
        DateTime firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
        DateTime firstDayOfLastMonth = DateTime(now.year, now.month - 1, 1);
        DateTime lastDayOfLastMonth = DateTime(now.year, now.month, 0);

        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where('user', isEqualTo: user.uid)
            .where('date',
                isGreaterThanOrEqualTo:
                    DateFormat('dd-MM-yyyy').format(firstDayOfLastMonth))
            .where('date',
                isLessThanOrEqualTo:
                    DateFormat('dd-MM-yyyy').format(lastDayOfLastMonth))
            .where('type', isEqualTo: 'debited')
            .get();

        double totalAmount = 0.0;
        int transactionCount = querySnapshot.docs.length;

        for (var doc in querySnapshot.docs) {
          double amount = double.parse(doc['amount']);
          totalAmount += amount;
        }

        setState(() {
          _averageSpent =
              transactionCount > 0 ? totalAmount / transactionCount : 0.0;
        });

        // Debug prints to verify data
        print("Average Spent for Last Two Months: $_averageSpent");
      }
    } catch (e) {
      print("Error fetching average spend for last two months: $e");
    }
  }

  Future<void> _fetchCurrentUser() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _fetchCurrentBudget();
    }
  }

  Future<void> _fetchCurrentBudget() async {
    DocumentSnapshot snapshot =
        await _budgetCollection.doc(_currentUser!.uid).get();
    if (snapshot.exists) {
      setState(() {
        _currentBudget = snapshot['amount'].toString();
        _budgetController.text = _currentBudget!;
      });
    }
  }

  Future<void> _saveBudget() async {
    if (_formKey.currentState!.validate()) {
      await _budgetCollection.doc(_currentUser!.uid).set({
        'amount': double.parse(_budgetController.text),
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Budget saved successfully')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Set Budget"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter your budget',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a budget';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveBudget,
                child: Text('Save Budget'),
              ),
              if (_currentBudget != null) ...[
                SizedBox(height: 20),
                Container(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Current Budget:  ₹$_currentBudget',
                      style: TextStyle(fontSize: 20),
                    )),
              ],
              Container(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'AI Generated Budget: ₹${_averageSpent.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 20),
                  )),
              ElevatedButton(
                  onPressed: () {
                    _budgetController.text = _averageSpent.toStringAsFixed(2);
                  },
                  child: Text('Set AI Budget')),
            ],
          ),
        ),
      ),
    );
  }
}
