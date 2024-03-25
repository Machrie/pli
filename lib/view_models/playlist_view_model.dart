import 'package:flutter/material.dart';
import 'package:googleapis/youtube/v3.dart' as youtube;
import 'package:pli/providers/google_sign_in_provider.dart';
import 'package:pli/services/google_http_client.dart';

class PlaylistViewModel extends ChangeNotifier {
  final GoogleSignInProvider _googleSignInProvider;
  List<youtube.Playlist> _playlists = [];
  String _newPlaylistTitle = '';
  int _selectedPlaylistIndex = -1;

  PlaylistViewModel(this._googleSignInProvider) {
    _handleSignIn();
  }

  List<youtube.Playlist> get playlists => _playlists;
  String get newPlaylistTitle => _newPlaylistTitle;
  int get selectedPlaylistIndex => _selectedPlaylistIndex;

  set newPlaylistTitle(String value) {
    _newPlaylistTitle = value;
    notifyListeners();
  }

  set selectedPlaylistIndex(int value) {
    _selectedPlaylistIndex = value;
    notifyListeners();
  }

  Future<void> _handleSignIn() async {
    if (_googleSignInProvider.isSignedIn) {
      final accessToken = await _googleSignInProvider.getAccessToken();
      final GoogleHttpClient client = GoogleHttpClient(accessToken);
      final youtube.YouTubeApi youtubeApi = youtube.YouTubeApi(client);

      final youtube.PlaylistListResponse response =
      await youtubeApi.playlists.list(['snippet'], mine: true);

      _playlists = response.items!;
      notifyListeners();
    }
  }

  Future<void> createNewPlaylist() async {
    try {
      if (_googleSignInProvider.isSignedIn) {
        final accessToken = await _googleSignInProvider.getAccessToken();
        final GoogleHttpClient client = GoogleHttpClient(accessToken);
        final youtube.YouTubeApi youtubeApi = youtube.YouTubeApi(client);

        final youtube.Playlist newPlaylist = youtube.Playlist()
          ..snippet = (youtube.PlaylistSnippet()
            ..title = _newPlaylistTitle
            ..description = 'A new playlist created from Flutter app');

        final youtube.Playlist createdPlaylist = await youtubeApi.playlists.insert(newPlaylist, ['snippet']);

        _playlists.add(createdPlaylist);
        _newPlaylistTitle = '';
        notifyListeners();
      }
    } catch (error) {
      print(error);
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      if (_googleSignInProvider.isSignedIn) {
        final accessToken = await _googleSignInProvider.getAccessToken();
        final GoogleHttpClient client = GoogleHttpClient(accessToken);
        final youtube.YouTubeApi youtubeApi = youtube.YouTubeApi(client);

        await youtubeApi.playlists.delete(playlistId);

        _playlists.removeWhere((playlist) => playlist.id == playlistId);
        _selectedPlaylistIndex = -1;
        notifyListeners();
      }
    } catch (error) {
      print(error);
    }
  }
}