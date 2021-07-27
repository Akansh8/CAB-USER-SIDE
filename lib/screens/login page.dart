import 'package:cabrider/brand_colors.dart';
import 'package:cabrider/screens/main%20page.dart';
import 'package:cabrider/screens/registration%20page.dart';
import 'package:cabrider/widgets/Progress%20Dialogue.dart';
import 'package:cabrider/widgets/TaxiButton.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  static const String id = "login";

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<ScaffoldState> scaffoldkey = new GlobalKey<ScaffoldState>();

  void showSnackBar(String title) {
    final snackbar = SnackBar(
      content: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15),
      ),
    );
    scaffoldkey.currentState.showSnackBar(snackbar);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  var emailController = new TextEditingController();

  var passwordController = new TextEditingController();

  void login() async {
    //show please wait dialog
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              status: 'Logging in',
            ));
    final user = (await _auth
            .signInWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
    )
            .catchError((ex) {
      Navigator.pop(context);
      PlatformException thisex = ex;
      showSnackBar(thisex.message);
    }))
        .user;

    if (user != null) {
      //verify login
      DatabaseReference userRef =
          FirebaseDatabase.instance.reference().child('users/${user.uid}');

      userRef.once().then((DataSnapshot snapshot) => {
            if (snapshot.value != null)
              {
                Navigator.pushNamedAndRemoveUntil(
                    context, MainPage.id, (route) => false)
              }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldkey,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SizedBox(
                  height: 70,
                ),
                Image(
                  alignment: Alignment.center,
                  height: 100.0,
                  width: 100.0,
                  image: AssetImage('images/logo.png'),
                ),
                SizedBox(
                  height: 40,
                ),
                Text(
                  'Sign In as a rider',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontFamily: 'Brand-Bold'),
                ),
                Padding(
                  padding: const EdgeInsets.all(23.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: TextStyle(
                            fontSize: 14,
                          ),
                          hintText: 'Enter email',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 10.0,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      TextField(
                        controller: passwordController,
                        obscureText: true, //hides the password
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            fontSize: 14,
                          ),
                          hintText: 'Enter your password!',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 10.0,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(
                        height: 40,
                      ),
                      TaxiButton(
                          title: 'LOGIN',
                          color: BrandColors.colorGreen,
                          onPressed: () async {
                            //check network availibility
                            var connectivityResult =
                                await Connectivity().checkConnectivity();
                            if (connectivityResult !=
                                    ConnectivityResult.mobile &&
                                connectivityResult != ConnectivityResult.wifi) {
                              showSnackBar("Couldn\'t Connect to internet");
                              return;
                            }
                            //email condition
                            if (!emailController.text.contains('@')) {
                              showSnackBar("enter a valid email");
                              return;
                            }
                            //password condition
                            if (passwordController.text.length < 5) {
                              showSnackBar(
                                  "Password too short..\n Enter at least 5 characters.");
                              return;
                            }
                            login();
                          }),
                    ],
                  ),
                ),
                FlatButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, RegistrationPage.id, (route) => false);
                    },
                    child: Text('Don\'t have an account,sign up here')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
