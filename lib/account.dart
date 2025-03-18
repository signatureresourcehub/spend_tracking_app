import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Collaborators'),
            onTap: () async {
              Navigator.of(context).pushNamed('/collaborators');
            },
          ),
          // ListTile(
          //   leading: Icon(Icons.delete),
          //   title: Text('Delete Account'),
          //   onTap: () async {},
          // ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help'),
            onTap: () async {
              Navigator.of(context).pushNamed('/help');
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              await _googleSignIn.signOut();

              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
    );
  }
}
