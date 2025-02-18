import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'profile.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'signin.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  List<String> _extractedText = []; // Store extracted text from images

  final String azureEndpoint = dotenv.env['AZURE_OCR_ENDPOINT'] ?? "";
  final String azureApiKey = dotenv.env['AZURE_OCR_API_KEY'] ?? "";

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

  Future<void> _extractTextFromImages() async {
    _extractedText.clear(); // Clear previous results

    for (File image in _selectedImages) {
      try {
        // Convert image to binary (bytes)
        List<int> imageBytes = await image.readAsBytes();

        // Send request to Azure OCR API
        var response = await http.post(
          Uri.parse(azureEndpoint),
          headers: {
            "Ocp-Apim-Subscription-Key": azureApiKey,
            "Content-Type": "application/octet-stream",
          },
          body: imageBytes,
        );

        if (response.statusCode == 202) {
          // Extract Operation-Location for result retrieval
          String operationUrl = response.headers['operation-location'] ?? '';
          if (operationUrl.isNotEmpty) {
            await Future.delayed(Duration(seconds: 3)); // Wait for processing
            var resultResponse = await http.get(
              Uri.parse(operationUrl),
              headers: {
                "Ocp-Apim-Subscription-Key": azureApiKey,
              },
            );

            if (resultResponse.statusCode == 200) {
              var jsonResponse = json.decode(resultResponse.body);
              var readResults = jsonResponse['analyzeResult']['readResults'];

              String extractedText = "";
              for (var result in readResults) {
                for (var line in result['lines']) {
                  extractedText += line['text'] + " "; // Add space instead of newline
                }
              }

              extractedText = extractedText.trim(); // Remove extra spaces

              setState(() {
                _extractedText.add(extractedText); // Store extracted text
              });

              // Print extracted text to console
              print("Extracted Text from Image:\n$extractedText");
            }
          }
        } else {
          print("OCR API Error: ${response.statusCode} - ${response.body}");
        }
      } catch (e) {
        print("Error extracting text: $e");
      }
    }
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
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => SignInPage()),
                      (route) => false, // Clears all previous routes
                );
              },
            ),
          ),
        ],
      ),
      body: _selectedImages.isEmpty
          ? Center(
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
            onPressed: _selectedImages.length >= 2 ? _extractTextFromImages : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              minimumSize: Size(150, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Grade",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: _showUploadOptions,
            child: Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
