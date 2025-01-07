import 'package:easy_sms_receiver/easy_sms_receiver.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/dashboard.dart';
import 'package:permission_handler/permission_handler.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final plugin = EasySmsReceiver.instance;
  final EasySmsReceiver easySmsReceiver = EasySmsReceiver.instance;
  String _easySmsReceiverStatus = "Undefined";
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
      setState(() {
        issigned = true;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DashBoard()),
          (Route<dynamic> route) => false, // Removes all previous routes
        );
      });
    }
  }

  // Future<bool> requestSmsPermission() async {
  //   return await Permission.sms.request().then(
  //     (PermissionStatus pStatus) {
  //       if (pStatus.isPermanentlyDenied) {
  //         // "You must allow sms permission"
  //         openAppSettings();
  //       }
  //       return pStatus.isGranted;
  //     },
  //   );
  // }

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
    getUser();
    startSmsReceiver();
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
    await FirebaseAuth.instance.signInWithCredential(credential);
    getUser();
  }

  logIn() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential user = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
                email: _emailController.text,
                password: _passwordController.text);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DashBoard()),
          (Route<dynamic> route) => false, // Removes all previous routes
        );
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
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Logging in...')),
      // );
      logIn();
    }
  }

  void _loginWithGoogle() {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Google login clicked!')),
    // );
    signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Login'),
      // ),
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
