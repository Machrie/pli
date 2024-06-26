import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:googleapis/youtube/v3.dart' as youtube;
import 'package:pli/providers/google_sign_in_provider.dart';
import 'package:pli/services/google_http_client.dart';
import 'package:pli/services/google_vision_service.dart';

class OCRViewModel extends ChangeNotifier {
  final GoogleSignInProvider _googleSignInProvider;
  final GoogleVisionService _googleVisionService;
  List<Uint8List> _imageDataList = [];
  String _extractedText = '';
  List<String> _sentences = [];

  OCRViewModel(this._googleSignInProvider, this._googleVisionService);

  List<Uint8List> get imageDataList => _imageDataList;

  String get extractedText => _extractedText;

  List<String> get sentences => _sentences;

  Future<void> addImages(List<Uint8List> images) async {
    _imageDataList.addAll(images);
    notifyListeners();
  }

  void removeImage(int index) {
    _imageDataList.removeAt(index);
    notifyListeners();
  }

  Future<void> performOCR() async {
    if (_imageDataList.isNotEmpty) {
      List<String> allSentences = [];
      for (var imageData in _imageDataList) {
        final extractedText = await _googleVisionService.extractText(imageData);
        final sentences = extractedText.split('\n');
        allSentences.addAll(sentences);
      }
      _sentences = allSentences;
      _extractedText = allSentences.join('\n');
      notifyListeners();
    }
  }

  Future<List<String>> addVideosToPlaylist(
      String playlistId, Function(int) onProgress) async {
    if (!_googleSignInProvider.isSignedIn) {
      await _googleSignInProvider.handleSignIn();
    }

    final accessToken = await _googleSignInProvider.getAccessToken();
    final GoogleHttpClient httpClient = GoogleHttpClient(accessToken);
    final youtube.YouTubeApi youtubeApi = youtube.YouTubeApi(httpClient);

    List<String> addedVideoIds = [];

    for (int i = 0; i < _sentences.length; i++) {
      String sentence = _sentences[i];
      final searchResponse = await youtubeApi.search.list(
        ['snippet'],
        q: sentence,
        type: ['video'],
        videoCategoryId: '10',
        maxResults: 1,
      );

      try {
        if (searchResponse.items != null && searchResponse.items!.isNotEmpty) {
          final videoId = searchResponse.items![0].id!.videoId!;

          await youtubeApi.playlistItems.insert(
            youtube.PlaylistItem(
              snippet: youtube.PlaylistItemSnippet(
                playlistId: playlistId,
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
      } catch (e) {
        print('Error adding video: $e');
      }

      onProgress(i + 1);
    }

    return addedVideoIds;
  }
}