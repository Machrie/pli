import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/youtube/v3.dart' as youtube;
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:pli/providers/google_sign_in_provider.dart';

class OCRPage extends StatefulWidget {
  final String playlistId;

  const OCRPage({required this.playlistId});

  @override
  _OCRPageState createState() => _OCRPageState();
}

class _OCRPageState extends State<OCRPage> {
  List<Uint8List> _imageDataList = [];
  String _extractedText = '';
  List<String> _sentences = [];

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedImages = await picker.pickMultiImage();

    if (pickedImages != null) {
      List<Uint8List> imageDataList = [];
      for (var pickedImage in pickedImages) {
        final imageData = await pickedImage.readAsBytes();
        imageDataList.add(imageData);
      }
      setState(() {
        _imageDataList = imageDataList;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageDataList.removeAt(index);
    });
  }

  Future<void> _performOCR() async {
    if (_imageDataList.isNotEmpty) {
      String extractedText = '';
      for (var imageData in _imageDataList) {
        final response = await _callGoogleVisionApi(imageData);
        final parsedText = _parseResponse(response);
        extractedText += parsedText + '\n';
      }
      setState(() {
        _extractedText = extractedText.trim();
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

  void _openPlaylistUrl() async {
    final String playlistUrl = 'https://music.youtube.com/playlist?list=${widget.playlistId}';
    if (await canLaunch(playlistUrl)) {
      await launch(playlistUrl);
    } else {
      throw 'Could not launch $playlistUrl';
    }
  }
  Future<void> _addVideosToPlaylist() async {
    final googleSignInProvider = Provider.of<GoogleSignInProvider>(context, listen: false);
    final googleSignIn = googleSignInProvider.googleSignIn;

    if (googleSignIn == null) {
      await googleSignInProvider.initializeGoogleSignIn();
    }

    final googleSignInAccount = await googleSignIn!.signIn();
    final authHeaders = await googleSignInAccount!.authHeaders;
    final httpClient = GoogleHttpClient(authHeaders);
    final youtubeApi = youtube.YouTubeApi(httpClient);

    List<String> addedVideoIds = [];

    for (String sentence in _sentences) {
      final searchResponse = await youtubeApi.search.list(
        ['snippet'],
        q: sentence,
        type: ['video'],
        videoCategoryId: '10',
        maxResults: 1,
      );

      if (searchResponse.items != null && searchResponse.items!.isNotEmpty) {
        final videoId = searchResponse.items![0].id!.videoId!;
        await youtubeApi.playlistItems.insert(
          youtube.PlaylistItem(
            snippet: youtube.PlaylistItemSnippet(
              playlistId: widget.playlistId,
              resourceId: youtube.ResourceId(
                kind: 'youtube#video',
                videoId: videoId,
              ),
            ),
          ),
          ['snippet'],
        );
        addedVideoIds.add(videoId);
      }
    }

    if (addedVideoIds.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('성공'),
            content: Text('${addedVideoIds.length}개의 동영상이 재생목록에 추가되었습니다.'),
            actions: [
              TextButton(
                child: Text('재생목록으로 이동'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _openPlaylistUrl();
                },
              ),
              TextButton(
                child: Text('추가 작업하기'),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('추가된 동영상이 없습니다.')),
      );
    }
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

        // 문장 배열 출력
        print('Sentences:');
        print(sentences);

        setState(() {
          _sentences = sentences;
        });

        return sentences.join('\n');
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
          if (_imageDataList.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _imageDataList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Image.memory(
                        _imageDataList[index],
                        fit: BoxFit.contain,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(Icons.remove_circle),
                          onPressed: () => _removeImage(index),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ElevatedButton(
            onPressed: _performOCR,
            child: Text('Perform OCR'),
          ),
          Text('Extracted Text:'),
          Text(_extractedText),
          ElevatedButton(
            onPressed: _sentences.isNotEmpty ? _addVideosToPlaylist : null,
            child: Text('자동으로 재생목록에 추가하기'),
          ),
        ],
      ),
    );
  }
}

class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;

  GoogleHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return request.send();
  }
}