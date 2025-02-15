import 'package:counter_flutter/signup.dart';
import 'package:flutter/material.dart';
import 'navbar.dart';
import 'profile.dart';
import 'signup.dart';
import 'markings.dart';

void main() {
  runApp(Counter_App());
}

class Counter_App extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        drawer: NavBar(),
        appBar: AppBar(
          backgroundColor: Colors.lightBlue,
          elevation: 10,
          shadowColor: Colors.black,
          title: Text(
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
              "Counter"
          ),
        ),
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Counter_Page(),
          ),
        ),
      ),

      routes: {
        '/profile': (context) => profile_page(),
        '/signUp': (context) => signUp(),
        '/markings': (context) => markings(),
      },

    );
  }
}


class Counter_Page extends StatefulWidget {

  @override
  State<Counter_Page> createState() => _Counter_PageState();
}

class _Counter_PageState extends State<Counter_Page> {

  int num_pressed = 0;

  increase_count() {
    setState(() {
      num_pressed += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: EdgeInsets.fromLTRB(10, 30, 10, 30),
          child: Text("You have clicked this button $num_pressed times"),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.lightBlue,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            shadowColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            )
          ),
        onPressed: () {
          increase_count();
    }, child: Text(
            "Click Me!",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        )
      ],
    );
  }
}


