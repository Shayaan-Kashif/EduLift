import 'package:flutter/material.dart';

class markings extends StatelessWidget {
  const markings({super.key});

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
              Container(
                margin: EdgeInsets.only(top: 20.0,left: 20), // Margin at the top
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
              SizedBox(width: 10), // Space between buttons

              // Second button (Option 2) with rounded corners and shadow
              Container(
                margin: EdgeInsets.only(top: 20.0), // Margin at the top
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
            ],
          ),


        ],
      ),
    );
  }
}
