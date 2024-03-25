import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pli/providers/google_sign_in_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pli/view_models/ocr_view_model.dart';
import 'package:pli/services/google_vision_service.dart';
import 'package:pli/widgets/playlist_dialog.dart';


class OCRToPlaylistPage extends StatelessWidget {
  final String playlistId;

  const OCRToPlaylistPage({required this.playlistId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => OCRViewModel(
        Provider.of<GoogleSignInProvider>(context, listen: false),
        GoogleVisionService(),
      ),
      child: Consumer<OCRViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'OCR Page',
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
                    child: ElevatedButton(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedImages = await picker.pickMultiImage();
                        if (pickedImages != null) {
                          List<Uint8List> imageDataList = [];
                          for (var pickedImage in pickedImages) {
                            final imageData = await pickedImage.readAsBytes();
                            imageDataList.add(imageData);
                          }
                          viewModel.addImages(imageDataList);
                        }
                      },
                      child: Text('Upload Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  if (viewModel.imageDataList.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: viewModel.imageDataList.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Image.memory(
                                viewModel.imageDataList[index],
                                fit: BoxFit.contain,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: Icon(Icons.remove_circle, color: Colors.white),
                                  onPressed: () => viewModel.removeImage(index),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: viewModel.performOCR,
                      child: Text('Perform OCR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.all(16.0),
                      children: [
                        Text(
                          'Extracted Text:',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          viewModel.extractedText,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: viewModel.sentences.isNotEmpty
                          ? () async {
                        showPlaylistAddingDialog(
                          context,
                          viewModel.sentences.length,
                          0,
                              () {
                            Navigator.of(context).pop();
                            _openPlaylistUrl(playlistId);
                          },
                              () {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                        );

                        final addedVideoIds = await viewModel.addVideosToPlaylist(
                          playlistId,
                              (addedVideos) {
                            Navigator.of(context).pop();
                            showPlaylistAddingDialog(
                              context,
                              viewModel.sentences.length,
                              addedVideos,
                                  () {
                                Navigator.of(context).pop();
                                _openPlaylistUrl(playlistId);
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
                      child: Text('자동으로 재생목록에 추가하기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
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

  void _openPlaylistUrl(String playlistId) async {
    final String playlistUrl = 'https://music.youtube.com/playlist?list=$playlistId';
    if (await canLaunch(playlistUrl)) {
      await launch(playlistUrl);
    } else {
      throw 'Could not launch $playlistUrl';
    }
  }
}