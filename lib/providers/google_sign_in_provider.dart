import 'package:flutter/foundation.dart';
import 'package:pli/services/google_sign_in_service.dart';


class GoogleSignInProvider with ChangeNotifier {
  final GoogleSignInService _googleSignInService = GoogleSignInService();

  bool get isSignedIn => _googleSignInService.isSignedIn;

  Future<void> initializeGoogleSignIn() async {
    await _googleSignInService.initializeGoogleSignIn();
    notifyListeners();
  }

  Future<void> handleSignIn() async {
    try {
      await _googleSignInService.signIn();
      notifyListeners();
    } catch (error) {
      print(error);
    }
  }

  Future<void> handleSignOut() async {
    await _googleSignInService.signOut();
    notifyListeners();
  }

  Future<String> getAccessToken() async {
    return await _googleSignInService.getAccessToken();
  }
}