import 'package:cabrider/brand_colors.dart';
import 'package:cabrider/screens/main%20page.dart';
import 'package:cabrider/widgets/Progress%20Dialogue.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login page.dart';

class RegistrationPage extends StatefulWidget {
  static const String id = "register";

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
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

  var fullNameController = TextEditingController();

  var phoneController = TextEditingController();

  var emailController = TextEditingController();

  var passwordController = TextEditingController();

  void registerUser() async {
    //show please wait dialog
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              status: 'Registring...',
            ));
    //firebaseUser class is now User class
    final user = (await _auth
            .createUserWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
    )
            .catchError((ex) {
      Navigator.pop(context);
      PlatformException thisex = ex;
      showSnackBar(thisex.message);
    }))
        .user;
    Navigator.pop(context);
    if (user != null) {
      DatabaseReference newUserRef =
          FirebaseDatabase.instance.reference().child('users/${user.uid}');
      Map userMap = {
        'fullname': fullNameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
      };
      newUserRef.set(userMap);
      //Take user to main page
      Navigator.pushNamedAndRemoveUntil(context, MainPage.id, (route) => false);
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
                  'Create Rider\'s account',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontFamily: 'Brand-Bold'),
                ),
                Padding(
                  padding: const EdgeInsets.all(23.0),
                  child: Column(
                    children: [
                      //name
                      TextField(
                        controller: fullNameController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(
                            fontSize: 14,
                          ),
                          hintText: 'Enter your name',
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
                      //email
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
                      //password
                      TextField(
                        controller: passwordController,
                        obscureText: true,
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
                        height: 10,
                      ),
                      //phone
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: TextStyle(
                            fontSize: 14,
                          ),
                          hintText: 'Enter phone number',
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
                        height: 30,
                      ),
                      RaisedButton(
                        onPressed: () async {
                          //check network availibility
                          var connectivityResult =
                              await Connectivity().checkConnectivity();
                          if (connectivityResult != ConnectivityResult.mobile &&
                              connectivityResult != ConnectivityResult.wifi) {
                            showSnackBar("Couldn\'t Connect to internet");
                            return;
                          }
                          //full name condition
                          if (fullNameController.text.length < 3) {
                            showSnackBar("Enter valid full name");
                            return;
                          }
                          if (phoneController.text.length < 10) {
                            showSnackBar("Enter valid phone number");
                            return;
                          }
                          if (!emailController.text.contains('@')) {
                            showSnackBar("enter a valid email");
                            return;
                          }
                          if (passwordController.text.length < 5) {
                            showSnackBar(
                                "Password too short..\n Enter at least 5 characters.");
                            return;
                          }
                          registerUser();
                        },
                        shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(25),
                        ),
                        color: BrandColors.colorGreen,
                        textColor: Colors.white,
                        child: Container(
                          height: 50,
                          child: Center(
                            child: Text(
                              'REGISTER',
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Brand-Bold',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                FlatButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, LoginPage.id, (route) => false);
                    },
                    child: Text('Already have an account? Login')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
