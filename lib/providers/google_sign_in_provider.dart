import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInProvider with ChangeNotifier {
  GoogleSignIn? _googleSignIn;

  GoogleSignIn? get googleSignIn => _googleSignIn;

  GoogleSignInAccount? _currentUser;

  GoogleSignInAccount? get currentUser => _currentUser;

  Future<void> initializeGoogleSignIn() async {
    _googleSignIn = GoogleSignIn(
      clientId: '265826158341-ub9on6lru39fa0vakrf69ekg83j42jbc.apps.googleusercontent.com',
      scopes: [
        'email',
        'https://www.googleapis.com/auth/youtube',
      ],
    );

    await _googleSignIn!.signInSilently();
    _currentUser = _googleSignIn!.currentUser;
    notifyListeners();
  }

  Future<void> handleSignIn() async {
    try {
      await _googleSignIn!.signIn();
      _currentUser = _googleSignIn!.currentUser;
      notifyListeners();
    } catch (error) {
      print(error);
    }
  }

  Future<void> handleSignOut() async {
    await _googleSignIn!.disconnect();
    _currentUser = null;
    notifyListeners();
  }
}