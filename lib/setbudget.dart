import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
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
            ],
          ),
        ),
      ),
    );
  }
}
