import 'package:http/http.dart' as http;

class GoogleHttpClient extends http.BaseClient {
  final String _accessToken;

  GoogleHttpClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers.addAll({'Authorization': 'Bearer $_accessToken'});
    return request.send();
  }
}