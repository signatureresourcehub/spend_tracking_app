import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/collaboratedtransactions.dart';
import 'dart:math';
import 'package:share_plus/share_plus.dart';

class CollaboratorsPage extends StatefulWidget {
  const CollaboratorsPage({super.key});

  @override
  State<CollaboratorsPage> createState() => _CollaboratorsPageState();
}

class _CollaboratorsPageState extends State<CollaboratorsPage> {
  String? _collaborationCode;
  final TextEditingController _codeController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _collaboratedUserNames = [];
  Map<String, String> _userNameToEmailMap = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkAndGenerateCollaborationCode());
    _fetchCollaboratedUsers();
  }

  Future<void> _checkAndGenerateCollaborationCode() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You need to be logged in to proceed')),
      );
      Navigator.of(context).pop();
      return;
    }

    final userEmail = currentUser.email;

    // Check if the collaboration code already exists for the user
    final querySnapshot = await _firestore
        .collection('collaborationcode')
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        _collaborationCode = querySnapshot.docs.first['code'];
      });
    } else {
      // Show the collaboration agreement dialog
      bool agreed = await _showCollaborationAgreement();
      if (agreed) {
        // Generate and save a new collaboration code
        await _generateAndSaveCollaborationCode(userEmail);
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _fetchCollaboratedUsers() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }

    final userEmail = currentUser.email;

    // Fetch collaborations where the current user is involved
    final querySnapshot = await _firestore
        .collection('collaborations')
        .where('user1', isEqualTo: userEmail)
        .get();

    final List<String> collaboratedUserEmails =
        querySnapshot.docs.map((doc) => doc['user2'] as String).toList();

    // Fetch names from users collection
    final List<String> collaboratedUserNames = [];
    final Map<String, String> userNameToEmailMap = {};
    for (String email in collaboratedUserEmails) {
      final userDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get()
          .then((value) => value.docs.first);
      if (userDoc.exists) {
        final userName = userDoc['name'] as String;
        collaboratedUserNames.add(userName);
        userNameToEmailMap[userName] = email;
      }
    }

    setState(() {
      _collaboratedUserNames = collaboratedUserNames;
      _userNameToEmailMap = userNameToEmailMap;
    });
  }

  Future<bool> _showCollaborationAgreement() async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Collaboration Agreement'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Please read and agree to the collaboration agreement to proceed.'),
                SizedBox(height: 10),
                Text('Collaboration Agreement Content...'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Disagree'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Agree'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateAndSaveCollaborationCode(String? email) async {
    final code = _generateRandomCode(5);

    // Save the code in the 'collaborationcode' collection
    await _firestore.collection('collaborationcode').add({
      'email': email,
      'code': code,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      _collaborationCode = code;
    });
  }

  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }

  void _shareCollaborationCode() {
    if (_collaborationCode != null) {
      Share.share('Here is my collaboration code: $_collaborationCode');
    }
  }

  Future<void> _submitCollaborationCode() async {
    final enteredCode = _codeController.text.trim();

    if (enteredCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a collaboration code')),
      );
      return;
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You need to be logged in to proceed')),
      );
      return;
    }

    // Check if the entered collaboration code exists in the collection
    final querySnapshot = await _firestore
        .collection('collaborationcode')
        .where('code', isEqualTo: enteredCode)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid collaboration code')),
      );
      return;
    }

    final collaboratedUserEmail = querySnapshot.docs.first['email'];

    // Prevent users from entering their own collaboration code
    if (collaboratedUserEmail == currentUser.email) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You cannot enter your own collaboration code')),
      );
      return;
    }

    // Check if the collaboration already exists
    final collaborationQuery = await _firestore
        .collection('collaborations')
        .where('user1', isEqualTo: currentUser.email)
        .where('user2', isEqualTo: collaboratedUserEmail)
        .limit(1)
        .get();

    if (collaborationQuery.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are already collaborated with this user')),
      );
      return;
    }

    // Save the collaboration in the 'collaborations' collection
    await _firestore.collection('collaborations').add({
      'user1': currentUser.email,
      'user2': collaboratedUserEmail,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Collaboration created successfully')),
    );

    // Clear the text field
    _codeController.clear();

    // Refresh the collaborated users list
    _fetchCollaboratedUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Collaborators'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: _collaborationCode == null
            ? Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Collaboration Code: ',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        _collaborationCode!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                          onPressed: _shareCollaborationCode,
                          icon: Icon(
                            Icons.share_rounded,
                            color: Colors.blue,
                          )),
                    ],
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Enter collaboration code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(
                    width: 20,
                    child: ElevatedButton(
                      onPressed: _submitCollaborationCode,
                      child: Text('Submit'),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Collaborated Users:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _collaboratedUserNames.length,
                    itemBuilder: (context, index) {
                      final userName = _collaboratedUserNames[index];
                      final userEmail = _userNameToEmailMap[userName];
                      return Container(
                        padding: EdgeInsets.only(top: 10, bottom: 10),
                        child: ListTile(
                          tileColor: Colors.grey[200],
                          title: Text(userName),
                          leading: Icon(
                            Icons.person,
                            color: Colors.blue,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    CollaboratedTransactionsPage(
                                  collaboratedUserEmail: userEmail!,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
