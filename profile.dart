import 'package:flutter/material.dart';
import 'grading.dart';

class ProfilePage extends StatelessWidget {
  final String name;
  final String school;
  final String position;

  ProfilePage({required this.name, required this.school, required this.position});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.yellow,
              child: Icon(Icons.school, size: 50, color: Colors.black),
            ),
            SizedBox(height: 20),
            Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(school, style: TextStyle(fontSize: 16)),
            Text(position, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
