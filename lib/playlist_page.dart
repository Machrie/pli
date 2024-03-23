import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pli/providers/google_sign_in_provider.dart';
import 'package:googleapis/youtube/v3.dart' as youtube;
import 'package:http/http.dart' as http;
import 'package:pli/ocr_page.dart';

class PlaylistPage extends StatefulWidget {
  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  GoogleSignInAccount? _currentUser;
  List<youtube.Playlist> _playlists = [];
  String _newPlaylistTitle = '';
  int _selectedPlaylistIndex = -1;

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
      final GoogleSignInAccount? googleUser =
          Provider.of<GoogleSignInProvider>(context, listen: false).currentUser;
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      final http.Client client = GoogleHttpClient(googleAuth.accessToken!);
      final youtube.YouTubeApi youtubeApi = youtube.YouTubeApi(client);

      final youtube.Playlist newPlaylist = youtube.Playlist()
        ..snippet = (youtube.PlaylistSnippet()
          ..title = _newPlaylistTitle
          ..description = 'A new playlist created from Flutter app');

      final youtube.Playlist createdPlaylist = await youtubeApi.playlists.insert(newPlaylist, ['snippet']);

      setState(() {
        _playlists.add(createdPlaylist);
        _newPlaylistTitle = '';
      });
    } catch (error) {
      print(error);
    }
  }

  Future<void> _deletePlaylist(String playlistId) async {
    try {
      final GoogleSignInAccount? googleUser =
          Provider.of<GoogleSignInProvider>(context, listen: false).currentUser;
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      final http.Client client = GoogleHttpClient(googleAuth.accessToken!);
      final youtube.YouTubeApi youtubeApi = youtube.YouTubeApi(client);

      await youtubeApi.playlists.delete(playlistId);

      setState(() {
        _playlists.removeWhere((playlist) => playlist.id == playlistId);
        _selectedPlaylistIndex = -1;
      });
    } catch (error) {
      print(error);
    }
  }

  void _confirmSelection() {
    if (_selectedPlaylistIndex >= 0) {
      final youtube.Playlist selectedPlaylist = _playlists[_selectedPlaylistIndex];
      final String playlistId = selectedPlaylist.id!;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OCRPage(playlistId: playlistId),
        ),
      );
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
          ElevatedButton(
            onPressed: _selectedPlaylistIndex >= 0 ? _confirmSelection : null,
            child: Text('Confirm Selection'),
          ),
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
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deletePlaylist(playlist.id!),
          ),
          leading: Radio<int>(
            value: index,
            groupValue: _selectedPlaylistIndex,
            onChanged: (int? value) {
              setState(() {
                _selectedPlaylistIndex = value!;
              });
            },
          ),
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
