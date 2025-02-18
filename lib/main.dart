import 'package:flutter/material.dart';
import 'signIn.dart'; // Import SignIn Page

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Demo Fest',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SignInPage(), // Start at Sign-In Page
    );
  }
}
