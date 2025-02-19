import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'signIn.dart'; // Import SignIn Page

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: "assets/.env");
    print("✅ .env file loaded successfully!");
  } catch (e) {
    print("❌ Error loading .env file: $e");
  }

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
