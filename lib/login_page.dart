import 'package:flutter/material.dart';
import 'package:pli/playlist_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. 로고 이미지
            Image.asset(
              'assets/images/logo.jpeg',
              width: 200,
              height: 200,
            ),
            SizedBox(height: 40),
            // 2. 구글 로그인 버튼
            ElevatedButton(
              onPressed: () async {
                GoogleSignIn _googleSignIn = GoogleSignIn();
                try {
                  await _googleSignIn.signIn();
                  // 로그인 성공 후 페이지 이동
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => PlaylistPage()),
                  );
                } catch (error) {
                  print(error);
                }
              },
              child: Text('Sign in with Google'),
            ),
          ],
        ),
      ),
    );
  }
}