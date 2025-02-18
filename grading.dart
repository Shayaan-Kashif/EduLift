import 'package:flutter/material.dart';
import 'profile.dart';
import 'package:image_picker/image_picker.dart';
import 'signin.dart'; // Ensure SignInPage is correctly imported

class GradingPage extends StatefulWidget {
  final String name;
  final String school;
  final String position;

  GradingPage({required this.name, required this.school, required this.position});

  @override
  _GradingPageState createState() => _GradingPageState();
}

class _GradingPageState extends State<GradingPage> {
  final ImagePicker _picker = ImagePicker();

  void _pickImage(ImageSource source) async {
    await _picker.pickImage(source: source);
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo),
              title: Text("Upload from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera),
              title: Text("Use Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SignInPage()),
          (route) => false, // Clears all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the back button
        title: Text("Grading"),
        actions: [
          Tooltip(
            message: "Profile",
            child: IconButton(
              icon: Icon(Icons.account_circle),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      name: widget.name,
                      school: widget.school,
                      position: widget.position,
                    ),
                  ),
                );
              },
            ),
          ),
          Tooltip(
            message: "Logout",
            child: IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome, ${widget.name}"),
            Text("Upload your answer key"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadOptions,
        child: Icon(Icons.add),
      ),
    );
  }
}
