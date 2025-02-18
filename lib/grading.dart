import 'package:flutter/material.dart';
import 'profile.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'signin.dart';

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
  File? _selectedImage; // Store the selected image

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path); // Store the image file
      });
    }
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
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
            SizedBox(height: 10),
            Text("Upload your answer key"),
            SizedBox(height: 20),
            _selectedImage != null
                ? Image.file(_selectedImage!, width: 200, height: 200, fit: BoxFit.cover)
                : Text("No image selected"),
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
