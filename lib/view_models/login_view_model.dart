import 'package:flutter/material.dart';
import 'package:pli/providers/google_sign_in_provider.dart';
import 'package:pli/views/select_playlist.dart';

class LoginViewModel extends ChangeNotifier {
  final GoogleSignInProvider _googleSignInProvider;

  LoginViewModel(this._googleSignInProvider);

  Future<void> handleSignIn(BuildContext context) async {
    await _googleSignInProvider.handleSignIn();
    // 로그인 성공 후 페이지 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => PlaylistPage()),
    );
  }
} 