import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pli/providers/google_sign_in_provider.dart';
import 'package:pli/view_models/text_to_playlist_view_model.dart';
import 'package:pli/widgets/playlist_dialog.dart';

class TextToPlaylistPage extends StatelessWidget {
  final String playlistId;

  TextToPlaylistPage({required this.playlistId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TextToPlaylistViewModel(
        Provider.of<GoogleSignInProvider>(context, listen: false),
      ),
      child: Consumer<TextToPlaylistViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Add Text to Playlist',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.black,
            ),
            body: Container(
              color: Colors.black,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        viewModel.inputText = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter text to search videos',
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
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: viewModel.inputText.isNotEmpty
                          ? () async {
                        final lines = viewModel.inputText.split('\n');
                        showPlaylistAddingDialog(
                          context,
                          lines.length,
                          0,
                              () {
                            Navigator.of(context).pop();
                            viewModel.openPlaylistUrl(playlistId);
                          },
                              () {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                        );

                        final addedVideoIds = await viewModel.searchAndAddVideosToPlaylist(
                          playlistId,
                              (addedVideos) {
                            Navigator.of(context).pop();
                            showPlaylistAddingDialog(
                              context,
                              lines.length,
                              addedVideos,
                                  () {
                                Navigator.of(context).pop();
                                viewModel.openPlaylistUrl(playlistId);
                              },
                                  () {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                            );
                          },
                        );

                        if (addedVideoIds.isEmpty) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('추가된 동영상이 없습니다.')),
                          );
                        }
                      }
                          : null,
                      child: Text('Search and Add Videos to Playlist'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}