import 'package:flutter/material.dart';
import 'package:pli/view_models/playlist_view_model.dart';
import 'package:pli/views/text_to_playlist.dart';
import 'package:provider/provider.dart';
import 'package:pli/providers/google_sign_in_provider.dart';
import 'package:pli/views/ocr_to_playlist.dart';
import 'package:googleapis/youtube/v3.dart' as youtube;

class PlaylistPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PlaylistViewModel(Provider.of<GoogleSignInProvider>(context, listen: false)),
      child: Consumer<PlaylistViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Playlist Page',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.black,
            ),
            body: Container(
              color: Colors.black,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: TextField(
                      onChanged: (value) {
                        viewModel.newPlaylistTitle = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter playlist title',
                        hintStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: viewModel.newPlaylistTitle.isNotEmpty ? viewModel.createNewPlaylist : null,
                    child: Text('Create New Playlist'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  Expanded(child: _buildPlaylistList(viewModel)),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: viewModel.selectedPlaylistIndex >= 0 ? () => _navigateToOCRToPlaylist(context, viewModel) : null,
                            child: Text('Add Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: viewModel.selectedPlaylistIndex >= 0 ? () => _navigateToText(context, viewModel) : null,
                            child: Text('Add Text'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaylistList(PlaylistViewModel viewModel) {
    if (viewModel.playlists.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
        ),
      );
    }

    return ListView.builder(
      itemCount: viewModel.playlists.length,
      itemBuilder: (context, index) {
        final youtube.Playlist playlist = viewModel.playlists[index];
        final String title = playlist.snippet?.title ?? '';

        return ListTile(
          title: Text(
            title,
            style: TextStyle(color: Colors.white),
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.white),
            onPressed: () => viewModel.deletePlaylist(playlist.id!),
          ),
          leading: Radio<int>(
            value: index,
            groupValue: viewModel.selectedPlaylistIndex,
            onChanged: (int? value) {
              viewModel.selectedPlaylistIndex = value!;
            },
            activeColor: Colors.red,
          ),
          tileColor: Colors.white12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        );
      },
    );
  }

  void _navigateToOCRToPlaylist(BuildContext context, PlaylistViewModel viewModel) {
    final youtube.Playlist selectedPlaylist = viewModel.playlists[viewModel.selectedPlaylistIndex];
    final String playlistId = selectedPlaylist.id!;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OCRToPlaylistPage(playlistId: playlistId),
      ),
    );
  }

  void _navigateToText(BuildContext context, PlaylistViewModel viewModel) {
    final youtube.Playlist selectedPlaylist = viewModel.playlists[viewModel.selectedPlaylistIndex];
    final String playlistId = selectedPlaylist.id!;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TextToPlaylistPage(playlistId: playlistId),
      ),
    );
  }
}