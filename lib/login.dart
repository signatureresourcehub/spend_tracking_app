import 'package:easy_sms_receiver/easy_sms_receiver.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/dashboard.dart';
import 'package:myapp/mainpage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _message = "";
  final storage = const FlutterSecureStorage();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool issigned = false;

  getUser() async {
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    await firebaseUser?.reload();
    if (firebaseUser != null) {
      print(firebaseUser.uid);
      await storage.write(key: "tokken", value: firebaseUser.uid);
      await storage.write(key: "email", value: firebaseUser.email);
      setState(() {
        issigned = true;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
          (Route<dynamic> route) => false, // Removes all previous routes
        );
      });
    }
  }

  void initState() {
    super.initState();
    getUser();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  showError(String errorMsg) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(errorMsg),
            actions: [
              TextButton(
                child: Text("Ok"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final User? user = userCredential.user;

    if (user != null) {
      // Check if the user is already in the users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        // User already exists, proceed to the main page
        getUser();
      } else {
        // Show the dialog to enter user details
        await _showUserInfoDialog(user);
      }
    }
  }

  Future<void> _showUserInfoDialog(User user) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController =
        TextEditingController(text: user.email);
    final TextEditingController phoneController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter your details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  readOnly: true,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                final String name = nameController.text.trim();
                final String email = emailController.text.trim();
                final String phone = phoneController.text.trim();

                if (name.isNotEmpty && email.isNotEmpty && phone.isNotEmpty) {
                  // Save the user information
                  await _saveUserInfo(user.uid, name, email, phone);
                  Navigator.of(context).pop();
                  getUser();
                } else {
                  // Show an error message if any field is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill in all fields')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveUserInfo(
      String uid, String name, String email, String phone) async {
    // Save the user information to Firestore or any other storage
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'phone': phone,
    });
  }

  logIn() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential user = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
                email: _emailController.text,
                password: _passwordController.text);
        getUser();
      } on FirebaseAuthException catch (e) {
        showError(e.message.toString());
        print(e.code);
        if (e.code == 'user-not-found') {
          print('No user found for that email.');
        } else if (e.code == 'wrong-password') {
          print('Wrong password provided for that user.');
        }
      }
    }
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      logIn();
    }
  }

  void _loginWithGoogle() {
    signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: 40),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: Container(
                    width: 100.0, // Set the width of the circle
                    height: 100.0, // Set the height of the circle
                    child: Image.asset('assets/Logo.jpg', fit: BoxFit.cover),
                  ),
                ),
                Text(
                  'Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    } else if (!RegExp(
                            r"^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$")
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    } else if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      shape: LinearBorder(),
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                ),
                // Login Button

                SizedBox(height: 16),
                // Login with Google Button
                OutlinedButton.icon(
                  onPressed: _loginWithGoogle,
                  icon: Image.asset('assets/google.png',
                      height: 20), // Add Google logo to your assets folder
                  label:
                      Text('Login with Google', style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    shape:
                        RoundedRectangleBorder(), // Use RoundedRectangleBorder
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    side: BorderSide(
                        color: Colors.black), // Set border color to black
                    minimumSize: Size(double.infinity, 0),
                  ),
                ),
                TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/registration');
                    },
                    child: Text("Create Account"))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
