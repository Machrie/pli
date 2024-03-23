import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pli/providers/google_sign_in_provider.dart';
import 'package:googleapis/youtube/v3.dart' as youtube;
import 'package:http/http.dart' as http;

class PlaylistPage extends StatefulWidget {
  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  GoogleSignInAccount? _currentUser;
  List<youtube.Playlist> _playlists = [];
  String _newPlaylistTitle = '';

  @override
  void initState() {
    super.initState();
    _handleSignIn();
  }

  Future<void> _handleSignIn() async {
    _currentUser = Provider.of<GoogleSignInProvider>(context, listen: false).currentUser;

    if (_currentUser != null) {
      final GoogleSignInAuthentication googleAuth = await _currentUser!.authentication;

      final http.Client client = GoogleHttpClient(googleAuth.accessToken!);
      final youtube.YouTubeApi youtubeApi = youtube.YouTubeApi(client);

      final youtube.PlaylistListResponse response =
      await youtubeApi.playlists.list(['snippet'], mine: true);

      setState(() {
        _playlists = response.items!;
      });
    }
  }

  Future<void> _createNewPlaylist() async {
    try {
      final GoogleSignInAccount? googleUser = Provider.of<GoogleSignInProvider>(context, listen: false).currentUser;
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      final http.Client client = GoogleHttpClient(googleAuth.accessToken!);
      final youtube.YouTubeApi youtubeApi = youtube.YouTubeApi(client);

      final youtube.Playlist newPlaylist = youtube.Playlist()
        ..snippet = (youtube.PlaylistSnippet()
          ..title = _newPlaylistTitle
          ..description = 'A new playlist created from Flutter app');

      await youtubeApi.playlists.insert(newPlaylist, ['snippet']);

      _newPlaylistTitle = '';
      _handleSignIn(); // 재생목록 목록을 새로고침합니다.
    } catch (error) {
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Playlist Page'),
      ),
      body: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _newPlaylistTitle = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Enter playlist title',
            ),
          ),
          ElevatedButton(
            onPressed: _newPlaylistTitle.isNotEmpty ? _createNewPlaylist : null,
            child: Text('Create New Playlist'),
          ),
          Expanded(child: _buildPlaylistList()),
        ],
      ),
    );
  }


  Widget _buildPlaylistList() {
    if (_currentUser == null) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final youtube.Playlist playlist = _playlists[index];
        final String title = playlist.snippet?.title ?? '';

        return ListTile(
          title: Text(title),
        );
      },
    );
  }
}

class GoogleHttpClient extends http.BaseClient {
  final String _accessToken;

  GoogleHttpClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll({'Authorization': 'Bearer $_accessToken'});
    return request.send();
  }
}