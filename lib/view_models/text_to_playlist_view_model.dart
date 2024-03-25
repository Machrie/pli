import 'package:flutter/material.dart';
import 'package:googleapis/youtube/v3.dart' as youtube;
import 'package:pli/providers/google_sign_in_provider.dart';
import 'package:pli/services/google_http_client.dart';
import 'package:url_launcher/url_launcher.dart';

class TextToPlaylistViewModel extends ChangeNotifier {
  final GoogleSignInProvider _googleSignInProvider;
  String _inputText = '';

  TextToPlaylistViewModel(this._googleSignInProvider);

  String get inputText => _inputText;

  set inputText(String value) {
    _inputText = value;
    notifyListeners();
  }

  Future<List<String>> searchAndAddVideosToPlaylist(String playlistId, Function(int) onProgress) async {
    final List<String> lines = _inputText.split('\n');
    final List<String> addedVideoIds = [];

    if (!_googleSignInProvider.isSignedIn) {
      await _googleSignInProvider.handleSignIn();
    }

    final accessToken = await _googleSignInProvider.getAccessToken();
    final GoogleHttpClient client = GoogleHttpClient(accessToken);
    final youtube.YouTubeApi youtubeApi = youtube.YouTubeApi(client);

    for (int i = 0; i < lines.length; i++) {
      final String query = lines[i];
      final youtube.SearchListResponse searchResponse = await youtubeApi.search.list(
        ['snippet'],
        type: ['video'],
        q: query,
        videoCategoryId: '10',
        maxResults: 1,
      );

      try {
        if (searchResponse.items != null && searchResponse.items!.isNotEmpty) {
          final String videoId = searchResponse.items![0].id!.videoId!;

          await youtubeApi.playlistItems.insert(
            youtube.PlaylistItem()
              ..snippet = (youtube.PlaylistItemSnippet()
                ..playlistId = playlistId
                ..resourceId = (youtube.ResourceId()..kind = 'youtube#video'..videoId = videoId)),
            ['snippet'],
          );
          addedVideoIds.add(videoId);
        }
      } catch (e) {
        print('Error adding video: $e');
      }

      onProgress(i + 1);
    }

    _inputText = '';
    notifyListeners();

    return addedVideoIds;
  }

  void openPlaylistUrl(String playlistId) async {
    final String playlistUrl = 'https://music.youtube.com/playlist?list=$playlistId';
    if (await canLaunch(playlistUrl)) {
      await launch(playlistUrl);
    } else {
      throw 'Could not launch $playlistUrl';
    }
  }
}