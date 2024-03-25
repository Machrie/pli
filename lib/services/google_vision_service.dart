import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pli/keys.dart';
class GoogleVisionService {
  Future<String> extractText(Uint8List imageData) async {
    const String apiKey = apikey;
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

    return _parseResponse(response.body);
  }

  String _parseResponse(String response) {
    final decodedResponse = json.decode(response);
    final List<dynamic>? responses = decodedResponse['responses'];

    if (responses != null && responses.isNotEmpty) {
      final dynamic firstResponseResult = responses[0]['fullTextAnnotation'];
      if (firstResponseResult != null && firstResponseResult['text'] != null) {
        final String extractedText = firstResponseResult['text'];

        // 추출된 텍스트를 줄 단위로 분할
        List<String> lines = extractedText.split('\n');

        // 2줄씩 묶어서 문장 만들기
        List<String> sentences = [];
        for (int i = 0; i < lines.length; i += 2) {
          if (i + 1 < lines.length) {
            String sentence = '${lines[i]} - ${lines[i + 1]}';
            sentences.add(sentence);
          } else {
            sentences.add(lines[i]);
          }
        }

        return sentences.join('\n');
      }
    }

    return '';
  }
}