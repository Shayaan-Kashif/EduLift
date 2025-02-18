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
  List<File> _selectedImages = []; // Store multiple images

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path)); // Add new image to list
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
          (route) => false, // Clears all previous routes
    );
  }

  void _gradeImages() {
    // Logic to grade the images
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Grading images...")),
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
      body: _selectedImages.isEmpty
          ? Center( // Center all text elements when no images are selected
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome, ${widget.name}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Upload your answer keys",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 20),
            Text(
              "No images selected",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      )
          : Column(
        children: [
          SizedBox(height: 20),
          Text(
            "Welcome, ${widget.name}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            "Upload your answer keys",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(10),
              itemCount: _selectedImages.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Display two images per row
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedImages[index],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: IconButton(
                        icon: Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedImages.removeAt(index); // Remove image
                          });
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: _selectedImages.length >= 2 ? _gradeImages : null, // Disable if less than 2 images
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Button size
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
            ),
            child: Text("Grade", style: TextStyle(fontWeight: FontWeight.bold),),
          ),
          SizedBox(width: 12), // Space between buttons
          FloatingActionButton(
            onPressed: _showUploadOptions,
            child: Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
