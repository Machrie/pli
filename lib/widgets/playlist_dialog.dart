import 'package:flutter/material.dart';

class PlaylistDialog extends StatefulWidget {
  final int totalVideos;
  final int addedVideos;
  final VoidCallback onPlaylistTap;
  final VoidCallback onAdditionalWorkTap;

  PlaylistDialog({
    required this.totalVideos,
    required this.addedVideos,
    required this.onPlaylistTap,
    required this.onAdditionalWorkTap,
  });

  @override
  _PlaylistDialogState createState() => _PlaylistDialogState();
}

class _PlaylistDialogState extends State<PlaylistDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('동영상 추가 중...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('${widget.addedVideos}/${widget.totalVideos} 동영상 추가됨'),
        ],
      ),
      actions: [
        if (widget.addedVideos == widget.totalVideos)
          TextButton(
            child: Text('재생목록으로 이동'),
            onPressed: widget.onPlaylistTap,
          ),
        if (widget.addedVideos == widget.totalVideos)
          TextButton(
            child: Text('추가 작업하기'),
            onPressed: widget.onAdditionalWorkTap,
          ),
      ],
    );
  }
}

void showPlaylistAddingDialog(
    BuildContext context,
    int totalVideos,
    int addedVideos,
    VoidCallback onPlaylistTap,
    VoidCallback onAdditionalWorkTap,
    ) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return PlaylistDialog(
        totalVideos: totalVideos,
        addedVideos: addedVideos,
        onPlaylistTap: onPlaylistTap,
        onAdditionalWorkTap: onAdditionalWorkTap,
      );
    },
  );
}