import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class OCRPage extends StatefulWidget {
  final String playlistId;

  const OCRPage({required this.playlistId});

  @override
  _OCRPageState createState() => _OCRPageState();
}

class _OCRPageState extends State<OCRPage> {
  Uint8List? _imageData;
  String _extractedText = '';

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      final imageData = await pickedImage.readAsBytes();
      setState(() {
        _imageData = imageData;
      });
    }
  }

  Future<void> _performOCR() async {
    if (_imageData != null) {
      final response = await _callGoogleVisionApi(_imageData!);
      final extractedText = _parseResponse(response);

      setState(() {
        _extractedText = extractedText;
      });
    }
  }

  Future<String> _callGoogleVisionApi(Uint8List imageData) async {
    const String apiKey = 'AIzaSyB_8pedMX-0xzK16SWXkCH0EiVLQrRV2fs';
    const String apiUrl = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';

    final List<int> bytes = imageData.cast<int>();
    final String base64Image = base64Encode(bytes);

    final Map<String, dynamic> requestBody = {
      "requests": [
        {
          "image": {"content": base64Image},
          "features": [
            {"type": "TEXT_DETECTION"}
          ]
        }
      ]
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      body: json.encode(requestBody),
    );

    return response.body;
  }

  String _parseResponse(String response) {
    // 1. 콘솔에서 API 응답 출력
    print('API Response:');
    print(response);

    final decodedResponse = json.decode(response);
    final List<dynamic>? responses = decodedResponse['responses'];

    if (responses != null && responses.isNotEmpty) {
      final dynamic firstResponseResult = responses[0]['fullTextAnnotation'];
      if (firstResponseResult != null && firstResponseResult['text'] != null) {
        final String extractedText = firstResponseResult['text'];

        // 2. 추출된 텍스트 길이 확인
        print('Extracted Text Length: ${extractedText.length}');

        return extractedText;
      }
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OCR Page'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _getImage,
            child: Text('Upload Image'),
          ),
          if (_imageData != null)
            Expanded(
              child: Image.memory(
                _imageData!,
                fit: BoxFit.contain,
              ),
            ),
          ElevatedButton(
            onPressed: _performOCR,
            child: Text('Perform OCR'),
          ),
          Text('Extracted Text:'),
          Text(_extractedText),
        ],
      ),
    );
  }
}