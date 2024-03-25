import 'package:flutter/material.dart';
import 'package:googleapis/youtube/v3.dart' as youtube;
import 'package:googleapis_auth/auth_io.dart' as auth;
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
    final List<String> queries = _inputText.split('\n');
    final List<String> addedVideoIds = [];

    if (!_googleSignInProvider.isSignedIn) {
      await _googleSignInProvider.handleSignIn();
    }

    final accessToken = await _googleSignInProvider.getAccessToken();
    final GoogleHttpClient httpClient = GoogleHttpClient(accessToken);
    final youtube.YouTubeApi youtubeApi = youtube.YouTubeApi(httpClient);

    final List<Map<String, dynamic>> searchParameters = queries.map((query) {
      return {
        'part': const ['snippet'],
        'q': query,
        'type': const ['video'],
        'videoCategoryId': '10',
        'maxResults': 1,
      };
    }).toList();

    final List<youtube.SearchResult> searchResults = [];

    for (final searchParameter in searchParameters) {
      final youtube.SearchListResponse searchResponse = await youtubeApi.search.list(
        searchParameter['part'],
        q: searchParameter['q'],
        type: searchParameter['type'],
        videoCategoryId: searchParameter['videoCategoryId'],
        maxResults: searchParameter['maxResults'],
      );
      if (searchResponse.items != null && searchResponse.items!.isNotEmpty) {
        searchResults.add(searchResponse.items![0]);
      }
    }

    final List<youtube.PlaylistItem> playlistItems = searchResults.map((searchResult) {
      final String videoId = searchResult.id!.videoId!;
      return youtube.PlaylistItem(
        snippet: youtube.PlaylistItemSnippet(
          playlistId: playlistId,
          resourceId: youtube.ResourceId(
            kind: 'youtube#video',
            videoId: videoId,
          ),
        ),
      );
    }).toList();

    try {
      final auth.AutoRefreshingAuthClient authClient = await _googleSignInProvider.getAuthClient();
      final BatchRequest batch = BatchRequest(authClient, rootUrl: 'https://www.googleapis.com/');

      playlistItems.forEach((playlistItem) {
        batch.add(youtubeApi.playlistItems.insert(
          playlistItem,
          ['snippet'],
        ));
      });

      final List<youtube.PlaylistItem> addedPlaylistItems = await batch.execute().then((responses) {
        return responses.map((response) => youtube.PlaylistItem.fromJson(response.body)).toList();
      });
      addedVideoIds.addAll(addedPlaylistItems.map((item) => item.snippet!.resourceId!.videoId!));
    } catch (e) {
      print('Error adding videos to playlist: $e');
    }

    onProgress(searchResults.length);

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