import 'package:cabrider/dataprovider/appdata.dart';
import 'package:cabrider/screens/login%20page.dart';
import 'package:cabrider/screens/main%20page.dart';
import 'package:cabrider/screens/registration%20page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp app = await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppData(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Brand-Regular',
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        //home: RegistrationPage(),
        initialRoute: LoginPage.id, //initialRoute: RegistrationPage.id,
        routes: {
          RegistrationPage.id: (context) => RegistrationPage(),
          MainPage.id: (context) => MainPage(),
          LoginPage.id: (context) => LoginPage(),
        },
      ),
    );
  }
}
