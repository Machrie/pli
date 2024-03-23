import 'package:flutter/material.dart';

class PlaylistPage extends StatefulWidget {
  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  List<String> playlists = []; // 사용자의 유튜브 재생목록 목록
  List<bool> selectedPlaylists = []; // 체크박스 상태 관리

  @override
  void initState() {
    super.initState();
    // 사용자의 유튜브 재생목록 가져오기
    playlists = ['Playlist 1', 'Playlist 2', 'Playlist 3'];
    selectedPlaylists = List.filled(playlists.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Playlist Page'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // 새로운 유튜브 재생목록 생성 로직 구현
            },
            child: Text('Create New Playlist'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                return CheckboxListTile(
                  title: Text(playlists[index]),
                  value: selectedPlaylists[index],
                  onChanged: (value) {
                    setState(() {
                      selectedPlaylists[index] = value!;
                    });
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // 선택된 재생목록 처리 로직 구현
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }
}