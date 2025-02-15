import 'package:flutter/material.dart';

class Markings extends StatefulWidget {
  const Markings({super.key});

  @override
  _MarkingsState createState() => _MarkingsState();
}

class _MarkingsState extends State<Markings> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Markings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // First button (Option 1) with rounded corners and shadow
              InkWell(
                onTap: () {
                  print('MCQS button tapped!');
                },
                child: Container(
                  margin: EdgeInsets.only(top: 20.0, left: 20), // Margin at the top
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: Offset(4, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    "MCQS",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),


              // Second button (Option 2) with rounded corners and shadow
              InkWell(
                onTap: () {
                  print('Long Answers button tapped!');
                },
                child: Container(
                  margin: EdgeInsets.only(top: 20.0, left: 20), // Margin at the top
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: Offset(4, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    "Long Answers",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
