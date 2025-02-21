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

  final String azureGptEndpoint = dotenv.env['AZURE_GPT_ENDPOINT'] ?? "";
  final String azureGptApiKey = dotenv.env['AZURE_GPT_API_KEY'] ?? "";


  void _startLoading(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 15),
              Text(message, style: TextStyle(fontSize: 16)),
            ],
          ),
        );
      },
    );
  }

  void _stopLoading() {
    Navigator.of(context, rootNavigator: true).pop();
  }




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
    _startLoading("Extracting texts from images");

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

    //_stopLoading();
    await Future.delayed(Duration(milliseconds: 300));
    _startLoading("Grading...");

    String prompt = "Compare each text in the following list to the first text. If the first text has a explicit question which is mathematical then check for if the student got it correct or incorrect otherwise return a similarity percentage (0% - 100%) for each and if the student name is present please put that in the response:\n\n"
        "Reference Text: ${_extractedText[0]}\n\n";

    for (int i = 1; i < _extractedText.length; i++) {
      prompt += "Student ${i}: ${_extractedText[i]}\n";
    }
    prompt += "\nReturn the results in this format: 'Student 1: 85% or Student 1: Correct or {Student name}: 85% or {Student name}: Correct\n Student 2: 72% or Student 2: Incorrect or Student name}: 72% or {Student name}: Incorrect\n ...' with no additional explanation.";


    try {
      var response = await http.post(
        Uri.parse(azureGptEndpoint),
        headers: {
          "Content-Type": "application/json",
          "api-key": azureGptApiKey,
        },
        body: jsonEncode({
          "messages": [
            {"role": "system", "content": "You are an AI that analyzes text similarity and returns a similarity percentages."},
            {"role": "user", "content": prompt}
          ],
          "max_tokens": 100
        }),
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        String gptResponse = jsonResponse["choices"][0]["message"]["content"].trim();
        print(gptResponse);

        _stopLoading();
        _stopLoading();
        await Future.delayed(Duration(milliseconds: 200));
        _showPopup(context, gptResponse);

      } else {
        print("Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print( "Error: $e");
    }


  }


  void _showPopup(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Results"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Closing the popup
              },
              child: Text("Ok"),
            ),
          ],
        );
      },
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
            onPressed: _selectedImages.length < 6 ? _showUploadOptions : null,
            backgroundColor: _selectedImages.length < 6 ? Colors.purple[100] : Colors.grey.shade400,
            child: Icon(Icons.add),
          ),

        ],

      ),

    );
  }
}
