import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'profile.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'signin.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';



class GradingPage extends StatefulWidget {
  final String name;
  final String school;
  final String position;
  final String email;

  GradingPage({required this.name, required this.school, required this.position, required this.email});

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
            await Future.delayed(Duration(seconds: 3)); // Wait for processing
            var resultResponse = await http.get(
              Uri.parse(operationUrl),
              headers: {"Ocp-Apim-Subscription-Key": azureApiKey},
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
        "- A name will be provided after Name: {student name} if no name is provided then write Student 1 Student 2... for those studnets\n"
        "- Reference Text for answers: ${_extractedText[0]}. Mark All the students against this answer sheet\n"
        "- Grade ALL students, even if their answers are incorrect\n\n"
        "Grade these answers:\n\n";

    for (int i = 1; i < _extractedText.length; i++) {
      prompt += "Student ${i}: ${_extractedText[i]}\n";
    }

    prompt += "\nShow results in this format for ALL students:\n"
        "{Student name}:\n"
        "4+4=8: True\nStudent Answer: {student answer} \nResult: Correct\n"
        "2+2=5: False \nStudent Answer: {student answer} \nResult: Incorrect\n"
        "Water is H2O: True\nStudent Answer: {student answer} \nResult: Correct\n\n"
        "{Student name}:\n"
        "(similar format)\n\n"
        "{Student name}:\n"
        "Find the median 1,4,9,15,18: 9\nStudent Answer: {student answer} \nResult: Correct\n\n"
        "{Student name}:\n"
        "Find the median 1,4,9,15,18: 9\nStudent Answer: {student answer} \nResult: Incorrect\n\n"
        "Important:\n"
        "- Use exactly this format for all students\n"
        "- Mark answers simply as Correct or Incorrect\n"
        "- Show the correct answer according to the solution sheet ${_extractedText[0]} only when the answer is wrong\n"
        "- Grade each answer independently\n"
        "- Grade ALL students' answers\n"
        "- Keep the same simple format for all types of questions\n"
        "- When an answer is 'A: 9.4', grade it as 'Incorrect (correct answer is 9)'\n"
        "- Make sure to show results for every student\n"
        "- YOU MUST USE THE ANSWER SHEET PROVIDED ${_extractedText[0]} WHEN MARKING STUDENTS. THE ANSWERS WITHIN IT ARE CONSIDERED CORRECT FOR MARKING PURPOSES.\n"
        "- YOU MUST SHOW RESULTS FOR ALL STUDENTS INCLUDING STUDENT 4";

    try {
      var response = await http
          .post(
        Uri.parse(azureGptEndpoint),
        headers: {
          "Content-Type": "application/json",
          "api-key": azureGptApiKey,
        },
        body: jsonEncode({
          "messages": [
            {
              "role": "system",
              "content": "You are a math teacher. Grade each answer simply as Correct or Incorrect according to the answer sheet ${_extractedText[0]}. Use the same format for all students. For wrong answers, show the correct answer in parentheses according to the answer sheet ${_extractedText[0]}. You must grade ALL students' answers, even if incorrect. When grading answers that start with 'A:', focus on the number after it. YOU MUST GRADE ALL STUDENTS INCLUDING STUDENT 4."
            },
            {"role": "user", "content": prompt}
          ],
          "max_tokens": 200,
          "temperature": 0.3
        }),
      )
          .timeout(Duration(seconds: 35));

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        String gptResponse = jsonResponse["choices"][0]["message"]["content"].trim();
        print(gptResponse);

        _stopLoading();
        await Future.delayed(Duration(milliseconds: 200));

        if (Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        List<String> studentResults = gptResponse.split('\n\n')
            .where((result) => result.trim().isNotEmpty && result.toLowerCase().contains('student'))
            .toList();

        print("Number of student results: ${studentResults.length}");
        print("Results content: $gptResponse");

        while (studentResults.length < _selectedImages.length - 1) {
          studentResults.add("Student ${studentResults.length + 1}:\nGrading results not available");
        }

        showDialog(
          context: context,
          barrierDismissible: false,
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
                        itemCount: studentResults.length,
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
                                Text(studentResults[index]),
                              ],
                            ),
                          );
                        },
                      ),
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
                    onPressed: () async {
                      await sendEmail(widget.email, "Results", gptResponse);
                      Navigator.of(context).pop();
                    },
                    child: Text("Send Email"),
                  ),

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
      } else {
        _stopLoading();
        _stopLoading();
        print("Error: ${response.statusCode} - ${response.body}");
        _showErrorPopup("Failed to process grading results. Please try again in a few minutes.");
      }
    } on TimeoutException catch (_) {
      _stopLoading();
      print("Timeout Error: API took too long to respond.");
      _showErrorPopup("Grading took too long. Please try again later.");
    } on Exception catch (e) {
      _stopLoading();
      print("Error: $e");
      _showErrorPopup("An unexpected error occurred. Please try again.");
    }



  }

  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text(message, style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: Text("OK", style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }



  Future<void> sendEmail(String recipient, String subject, String messageText) async {
    const String apiUrl = "https://edulift-email-api-hbhrhfgvffcfauer.canadacentral-01.azurewebsites.net/send-email";

    String formattedMessageText = messageText
        .split("\n")
        .map((line) {
      List<String> parts = line.split(":");
      if (parts.length < 2) {
        return "<p><strong>${parts[0]}</strong></p>"; // Handle lines without `:`
      }
      return "<p><strong>${parts[0]}</strong>: ${parts[1]}</p>";
    })
        .join("");

    Map<String, dynamic> emailData = {
      "recipient": recipient,
      "subject": subject,
      "plain_text": messageText,
      "html_content": """
  <p>Hi ${widget.name},</p>
  <p>We have completed marking your students! You can find the results of each student below:</p>

  ${formattedMessageText}
  
  <p>We thank you for using EduLift! We appreciate your dedication to education and your efforts in marking student work. 
  If you have any feedback or need any assistance, feel free to reach out to us. We’re always here to help!</p>
  
  <p>Sincerely,</p>
  <p><strong>The EduLift Team</strong></p>
  """
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(emailData),
      );

      if (response.statusCode == 200) {
        print("✅ Email sent successfully: ${response.body}");
      } else {
        print("Error sending email: ${response.body}");
      }
    } catch (error) {
      print("❌ HTTP Error: $error");
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
            onPressed: _selectedImages.length < 6 ? _showUploadOptions : null,
            backgroundColor: _selectedImages.length < 6 ? Colors.purple[100] : Colors.grey.shade400,
            child: Icon(Icons.add),
          ),

        ],

      ),

    );
  }
}
