import 'package:google_sign_in/google_sign_in.dart';
import 'package:pli/keys.dart';

class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: client_id,
    scopes: [
      'email',
      'https://www.googleapis.com/auth/youtube',
    ],
  );

  bool get isSignedIn => _googleSignIn.currentUser != null;

  Future<void> initializeGoogleSignIn() async {
    await _googleSignIn.signInSilently();
  }

  Future<void> signIn() async {
    await _googleSignIn.signIn();
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
  }

  Future<String> getAccessToken() async {
    final GoogleSignInAccount? googleUser = _googleSignIn.currentUser;
    final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
    return googleAuth.accessToken!;
  }
}