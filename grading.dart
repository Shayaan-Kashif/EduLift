import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'profile.dart';
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
  List<File> _selectedImages = [];
  List<String> _extractedText = [];
  List<Map<String, dynamic>> _gradedResults = [];

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
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
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
    if (_selectedImages.isEmpty) {
      print("No images selected for processing.");
      return;
    }

    _startLoading("Extracting texts from images");
    _extractedText.clear();

    for (File image in _selectedImages) {
      try {
        List<int> imageBytes = await image.readAsBytes();
        var response = await http.post(
          Uri.parse(azureEndpoint),
          headers: {
            "Ocp-Apim-Subscription-Key": azureApiKey,
            "Content-Type": "application/octet-stream",
          },
          body: imageBytes,
        );

        if (response.statusCode == 202) {
          String operationUrl = response.headers['operation-location'] ?? '';
          if (operationUrl.isNotEmpty) {
            await Future.delayed(Duration(seconds: 3));
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
                  extractedText += line['text'] + " ";
                }
              }

              extractedText = extractedText.trim();
              setState(() {
                _extractedText.add(extractedText);
              });

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

    if (_extractedText.isEmpty) {
      _stopLoading();
      print("No text extracted.");
      return;
    }

    await Future.delayed(Duration(milliseconds: 300));
    _startLoading("Grading...");

    String prompt = "You are a math teacher grading student answers.\n"
        "For each student's answers:\n"
        "- For mathematical equations (like 4+4=8), check if the calculation is correct\n"
        "- For statements (like 'Water is H2O'), check if they are correct\n"
        "- For statistical questions (like finding median), check if the answer matches the correct calculation\n"
        "- When the answer starts with 'A:', grade the number after it\n"
        "- Grade each answer independently\n"
        "- Use the same format for all students\n"
        "- Grade ALL students, even if their answers are incorrect\n\n"
        "Grade these answers:\n\n";

    for (int i = 0; i < _extractedText.length; i++) {
      prompt += "Student ${i + 1} Answers:\n${_extractedText[i]}\n\n";
    }

    prompt += "\nShow results in this format for ALL students:\n"
        "Student 1:\n"
        "4+4=8: Correct\n"
        "2+2=5: Incorrect (correct answer is 4)\n"
        "Water is H2O: Correct\n\n"
        "Student 2:\n"
        "(similar format)\n\n"
        "Student 3:\n"
        "Find the median 1,4,9,15,18: Correct\n\n"
        "Student 4:\n"
        "Find the median 1,4,9,15,18: Incorrect (correct answer is 9)\n\n"
        "Important:\n"
        "- Use exactly this format for all students\n"
        "- Mark answers simply as Correct or Incorrect\n"
        "- Show the correct answer only when the answer is wrong\n"
        "- Grade each answer independently\n"
        "- Grade ALL students' answers\n"
        "- Keep the same simple format for all types of questions\n"
        "- When an answer is 'A: 9.4', grade it as 'Incorrect (correct answer is 9)'\n"
        "- Make sure to show results for every student\n"
        "- YOU MUST SHOW RESULTS FOR ALL STUDENTS INCLUDING STUDENT 4";

    try {
      var response = await http.post(
        Uri.parse(azureGptEndpoint),
        headers: {
          "Content-Type": "application/json",
          "api-key": azureGptApiKey,
        },
        body: jsonEncode({
          "messages": [
            {
              "role": "system", 
              "content": "You are a math teacher. Grade each answer simply as Correct or Incorrect. Use the same format for all students. For wrong answers, show the correct answer in parentheses. You must grade ALL students' answers, even if incorrect. When grading answers that start with 'A:', focus on the number after it. YOU MUST GRADE ALL STUDENTS INCLUDING STUDENT 4."
            },
            {"role": "user", "content": prompt}
          ],
          "max_tokens": 200,
          "temperature": 0.3
        }),
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        String gptResponse = jsonResponse["choices"][0]["message"]["content"].trim();
        print("GPT Response: $gptResponse"); // For debugging
        
        _stopLoading();
        await Future.delayed(Duration(milliseconds: 200));
        _showPopup(context, gptResponse);
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
        _stopLoading();
        _showErrorPopup("Failed to process grading results");
      }
    } catch (e) {
      print("Error: $e");
      _stopLoading();
      _showErrorPopup("An error occurred while grading");
    }
  }

  void _showPopup(BuildContext context, String results) {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    
    // Split results by student and ensure all students are included
    List<String> studentResults = results.split('\n\n')
        .where((result) => result.trim().isNotEmpty && result.toLowerCase().contains('student'))
        .toList();

    print("Number of student results: ${studentResults.length}"); // Debug print
    print("Results content: $results"); // Debug print

    // Ensure we have results for all students
    while (studentResults.length < _selectedImages.length) {
      studentResults.add("Student ${studentResults.length + 1}:\nGrading results not available");
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        PageController _pageController = PageController();
        return WillPopScope(
          onWillPop: () async => true,
          child: AlertDialog(
            title: Text("Grading Results"),
            content: Container(
              width: double.maxFinite,
              height: 300,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Student ${index + 1} Results",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  "Image ${index + 1}",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15),
                            Text(
                              studentResults[index],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Navigation arrows
                  if (_selectedImages.length > 1) ...[
                    Positioned(
                      left: 0,
                      bottom: 20,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios),
                        onPressed: () {
                          _pageController.previousPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 20,
                      child: IconButton(
                        icon: Icon(Icons.arrow_forward_ios),
                        onPressed: () {
                          _pageController.nextPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Main app structure
      appBar: AppBar(
        centerTitle: true,  // Centers the title in the AppBar
        title: Padding(
          padding: EdgeInsets.only(right: 50, bottom: 20),  // Adjusts title position
          child: Transform.translate(
            offset: Offset(15, 18),  // Fine-tunes title position
            child: Text(
              "Grading",
              style: TextStyle(
                fontSize: 24,  // Sets title text size
                fontWeight: FontWeight.w500,  // Sets title text weight
              ),
            ),
          ),
        ),
        automaticallyImplyLeading: false,  // Removes default back button
        actions: [
          // Profile icon button
          Padding(
            padding: EdgeInsets.only(left: 30),  // Spaces profile icon
            child: IconButton(
              icon: Icon(Icons.account_circle),  // Profile icon
              onPressed: () {
                // Navigates to sign in page and clears navigation stack
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => SignInPage()),
                  (route) => false,
                );
              },
            ),
          ),
          SizedBox(width: 8),  // Spacing between icons
          // Forward arrow button
          IconButton(
            icon: Icon(Icons.arrow_forward),  // Forward arrow icon
            onPressed: () {
              Navigator.of(context).pop();  // Returns to previous screen
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: _selectedImages.isEmpty
                  ? Center(child: Text("No images selected"))  // Shows when no images
                  : GridView.builder(  // Creates grid of images
                      padding: EdgeInsets.all(10),  // Padding around grid
                      itemCount: _selectedImages.length,  // Number of images
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,  // Two images per row
                        crossAxisSpacing: 8,  // Horizontal spacing
                        mainAxisSpacing: 8,  // Vertical spacing
                      ),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onLongPress: () {
                            // Shows delete confirmation dialog
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text("Delete Image"),  // Dialog title
                                  content: Text("Do you want to delete this image?"),  // Dialog message
                                  actions: [
                                    // Cancel button
                                    TextButton(
                                      child: Text("Cancel"),
                                      onPressed: () {
                                        Navigator.of(context).pop();  // Closes dialog
                                      },
                                    ),
                                    // Delete button
                                    TextButton(
                                      child: Text(
                                        "Delete",
                                        style: TextStyle(color: Colors.red),  // Red color for delete
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _selectedImages.removeAt(index);  // Removes image
                                          _extractedText.removeAt(index);   // Removes associated text
                                        });
                                        Navigator.of(context).pop();  // Closes dialog
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Stack(  // Stacks image and delete instruction
                            children: [
                              Image.file(_selectedImages[index]),  // Displays image
                              Positioned(
                                top: 5,  // Positions text overlay
                                right: 5,
                                child: Container(
                                  padding: EdgeInsets.all(4),  // Padding around text
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),  // Semi-transparent background
                                    borderRadius: BorderRadius.circular(12),  // Rounded corners
                                  ),
                                  child: Text(
                                    "Long press to delete",  // Helper text
                                    style: TextStyle(
                                      color: Colors.white,  // White text
                                      fontSize: 12,  // Small text size
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 20, bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.grey; // disabled color
                    }
                    return Colors.green; // enabled color
                  },
                ),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
              ),
              onPressed: _selectedImages.isNotEmpty ? _extractTextFromImages : null,
              child: Text("Grade"),
            ),
            SizedBox(width: 10),
            FloatingActionButton(
              onPressed: _showUploadOptions,
              child: Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
